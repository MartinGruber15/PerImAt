#!/usr/bin/env python3
"""
PerImAt (offline, QUEST+ version) - behavioural analysis per subject and pooled.

Folder layout (BIDS-like):
    <root>/rawdata/sub-XX/...      raw files written by the experiment
    <root>/analysis/               this script
    <root>/derivatives/            results (created by this script)
        sub-XX/tables/*.csv, sub-XX/figures/*.png
        pooled/tables/*.csv,  pooled/figures/*.png
        group_tables/*.csv     (all subjects + 'pooled' in one file)
        summary.md             (the key numbers in readable form)

Usage:
    python analysis/perimat_analysis.py                      # all sub-* in rawdata
    python analysis/perimat_analysis.py --subjects 01 03
    python analysis/perimat_analysis.py --include-dual-catch  # dual catch trials (2 dots) count as normal BR trials

What is analysed (practice trials are skipped: sub-XX_practice_du_*.csv / sub-XX_train_du_*.csv):
  1. Sustained BR (sub-XX_BRtraining_run-1/2.csv; 60 s each, run 1 = face left / house right,
     run 2 = house left / face right, at default contrasts) -> eye & stimulus dominance by time.
  2. QUEST+ tests (sub-XX_questplus-test*.csv), e.g. the one right before the calibration.
  3. QUEST+ calibration(s): trials and time needed, final contrasts (XX_training_n.mat),
     and the validation trials.
  4. Main experiment, Report (r) and Dual (du) runs: HouseL / FaceL / HouseR / FaceR / mixed / no response
     per condition (baseline, perception, attention, imagery) and cue (house, face),
     eye dominance P(left eye | house or face) and stimulus dominance P(house | house or face),
     reaction times, ratings, catch trials, run time course, sequential effects.
     No-report (nr) runs have no percept report; they only enter the rating table.

Percept labels: HouseL = the house was seen and it was in the left eye, FaceR = face seen, in the right eye, etc.
'mixed' = mixed key; 'noResp' = no key press (the main experiment logs these as perceived = 'mixed', response 0);
'invalid' = a key that is not a percept key.

Requires: numpy, pandas, scipy, matplotlib.
"""
from __future__ import annotations

import argparse
import re
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd
import scipy.io as sio
from scipy import stats

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402
from matplotlib.lines import Line2D  # noqa: E402

# --------------------------------------------------------------------------------------------
# constants
# --------------------------------------------------------------------------------------------
PERCEPTS = ["HouseL", "FaceL", "HouseR", "FaceR", "mixed", "noResp", "invalid"]
HF = ["HouseL", "FaceL", "HouseR", "FaceR"]
CONDITIONS = ["baseline", "perception", "attention", "imagery"]
CUES = ["house", "face"]
TASKS = {"r": "report", "du": "dual", "nr": "noReport"}
TASK_ORDER = ["report", "dual", "noReport"]

# colours: hue = stimulus (house blue, face orange), lightness = eye (left dark, right light)
COL = {
    "HouseL": "#1c5cab", "HouseR": "#6da7ec",
    "FaceL": "#c4461a", "FaceR": "#f08a5c",
    "mixed": "#898781", "noResp": "#d6d4cc", "none": "#d6d4cc", "invalid": "#2c2c2a",
    "house": "#2a78d6", "face": "#eb6834", "-": "#52514e", "left": "#52514e",
}
SURFACE, INK, INK2, MUTED, GRID, AXIS = "#fcfcfb", "#0b0b0b", "#52514e", "#898781", "#e1e0d9", "#c3c2b7"

plt.rcParams.update({
    "figure.facecolor": SURFACE, "axes.facecolor": SURFACE, "savefig.facecolor": SURFACE,
    "axes.edgecolor": AXIS, "axes.labelcolor": INK2, "xtick.color": INK2, "ytick.color": INK2,
    "text.color": INK, "axes.titlecolor": INK, "axes.grid": True, "grid.color": GRID, "grid.linewidth": 0.6,
    "axes.axisbelow": True, "axes.spines.top": False, "axes.spines.right": False,
    "font.family": "sans-serif", "font.size": 9, "axes.titlesize": 10, "axes.titleweight": "bold",
    "legend.frameon": False, "legend.fontsize": 8, "figure.dpi": 100,
})


# --------------------------------------------------------------------------------------------
# small helpers
# --------------------------------------------------------------------------------------------
def wilson(k, n, z=1.959964):
    """Wilson 95 % CI for a proportion."""
    if n == 0:
        return np.nan, np.nan
    p = k / n
    den = 1 + z ** 2 / n
    c = (p + z ** 2 / (2 * n)) / den
    h = z * np.sqrt(p * (1 - p) / n + z ** 2 / (4 * n ** 2)) / den
    return max(0.0, c - h), min(1.0, c + h)


def binom_p(k, n, p=0.5):
    return stats.binomtest(int(k), int(n), p).pvalue if n > 0 else np.nan


def fisher_p(k1, n1, k2, n2):
    if n1 == 0 or n2 == 0:
        return np.nan
    return stats.fisher_exact([[k1, n1 - k1], [k2, n2 - k2]])[1]


def ts_from_name(name):
    m = re.search(r"(\d{4}-\d{2}-\d{2})_(\d{6})", name)
    return datetime.strptime(m.group(1) + m.group(2), "%Y-%m-%d%H%M%S") if m else None


def read_csv(path):
    with open(path) as fh:
        head = fh.readline()
    return pd.read_csv(path, sep=";" if head.count(";") > head.count(",") else ",")


def mat_struct_to_dict(o):
    if isinstance(o, sio.matlab.mat_struct):
        return {k: mat_struct_to_dict(getattr(o, k)) for k in o._fieldnames}
    return o


def loadmat(path):
    m = sio.loadmat(path, squeeze_me=True, struct_as_record=False)
    return {k: mat_struct_to_dict(v) for k, v in m.items() if not k.startswith("__")}


def counts_of(labels):
    vc = pd.Series(labels).value_counts()
    return {p: int(vc.get(p, 0)) for p in PERCEPTS}


def percept_summary(labels, rt=None, extra=None):
    """Counts, percentages, stimulus and eye dominance for a list of percept labels."""
    c = counts_of(labels)
    n = int(len(labels))
    h = c["HouseL"] + c["HouseR"]
    f = c["FaceL"] + c["FaceR"]
    left = c["HouseL"] + c["FaceL"]
    nhf = h + f
    out = {"n": n, **c}
    for p in PERCEPTS:
        out[f"pct_{p}"] = 100 * c[p] / n if n else np.nan
    out["nHouseFace"] = nhf
    out["pHouse"] = h / nhf if nhf else np.nan
    out["pHouse_ci_lo"], out["pHouse_ci_hi"] = wilson(h, nhf)
    out["pHouse_binom_p"] = binom_p(h, nhf)
    out["pLeftEye"] = left / nhf if nhf else np.nan
    out["pLeftEye_ci_lo"], out["pLeftEye_ci_hi"] = wilson(left, nhf)
    out["pLeftEye_binom_p"] = binom_p(left, nhf)
    out["pMixedOrNoResp"] = (c["mixed"] + c["noResp"]) / n if n else np.nan
    if rt is not None:
        rt = pd.Series(rt, dtype=float)
        lab = pd.Series(list(labels), index=rt.index)
        out["rt_n"] = int(rt.notna().sum())
        out["rt_median"] = rt.median()
        out["rt_mean"] = rt.mean()
        out["rt_sd"] = rt.std()
        for grp, members in [("house", ["HouseL", "HouseR"]), ("face", ["FaceL", "FaceR"]), ("mixed", ["mixed"]),
                             ("left", ["HouseL", "FaceL"]), ("right", ["HouseR", "FaceR"])]:
            out[f"rt_median_{grp}"] = rt[lab.isin(members)].median()
    if extra:
        out.update(extra)
    return out


def save_table(df, folder, name):
    folder.mkdir(parents=True, exist_ok=True)
    df.to_csv(folder / f"{name}.csv", index=False, float_format="%.4f")


def savefig(fig, folder, name):
    folder.mkdir(parents=True, exist_ok=True)
    fig.savefig(folder / f"{name}.png", dpi=150, bbox_inches="tight")
    plt.close(fig)


def percept_legend(ax, cats=("HouseL", "FaceL", "HouseR", "FaceR", "mixed", "noResp", "invalid"), **kw):
    handles = [Patch(facecolor=COL[c], edgecolor="none", label=c) for c in cats]
    ax.legend(handles=handles, **({"loc": "upper left", "bbox_to_anchor": (1.0, 1.0)} | kw))


# --------------------------------------------------------------------------------------------
# 1. sustained binocular rivalry (BR training)
# --------------------------------------------------------------------------------------------
BR_RUN_EYES = {1: {"face": "L", "house": "R"}, 2: {"house": "L", "face": "R"}}  # see binocularRivalryTraining.m


def load_sustained_br(sub, subdir):
    rows = []
    for f in sorted(subdir.glob(f"sub-{sub}_BRtraining_run-*.csv")):
        run = int(re.search(r"run-(\d+)", f.name).group(1))
        d = read_csv(f).sort_values("onsets").reset_index(drop=True)
        eyes = BR_RUN_EYES.get(run, {})
        for i, r in d.iterrows():
            p = r.percepts
            # [2026-11-12] newer BR training logs 'none' (no key held) separately from 'mixed' (two keys)
            lab = p.capitalize() + eyes[p] if p in eyes else ("none" if p == "none" else "mixed")
            rows.append(dict(subject=f"sub-{sub}", run=run,
                             eyeConfig="FaceL_HouseR" if run == 1 else "HouseL_FaceR",
                             period=i + 1, percept=p, label=lab, onset=r.onsets, duration=r.durations,
                             keyAdded=int(r.get("keyAdded", 0)),
                             first=(i == 0), last=(i == len(d) - 1)))
    return pd.DataFrame(rows)


def summarise_sustained_br(br, group_name):
    """Dominance by time; mean durations exclude the first period (before the first key) and the
    last one (cut by the end of the run)."""
    out = []
    for key, d in list(br.groupby("run")) + [("all", br)]:
        tot = {c: d.loc[d.label == c, "duration"].sum() for c in HF + ["mixed", "none"]}
        h = tot["HouseL"] + tot["HouseR"]
        f = tot["FaceL"] + tot["FaceR"]
        left = tot["HouseL"] + tot["FaceL"]
        inner = d[~d["first"] & ~d["last"]]
        excl = d[d.label.isin(HF)]
        # alternations between exclusive percepts (ignoring mixed periods in between)
        n_alt = 0
        for _, dr in d.groupby(["subject", "run"]):
            seq = dr.loc[dr.label.isin(HF), "percept"].tolist()
            n_alt += sum(a != b for a, b in zip(seq[:-1], seq[1:]))
        run_time = (d.onset + d.duration).groupby([d.subject, d.run]).max().sum()
        row = dict(subject=group_name, run=key, total_s=run_time)
        for c in HF + ["mixed", "none"]:
            row[f"time_{c}_s"] = tot[c]
            row[f"pctTime_{c}"] = 100 * tot[c] / run_time if run_time else np.nan
            row[f"nPeriods_{c}"] = int((d.label == c).sum())
            row[f"meanDur_{c}_s"] = inner.loc[inner.label == c, "duration"].mean()
        row["pHouse_time"] = h / (h + f) if h + f else np.nan          # stimulus dominance
        row["pLeftEye_time"] = left / (h + f) if h + f else np.nan     # eye dominance
        row["nHouse_periods"] = int(excl.percept.eq("house").sum())
        row["nFace_periods"] = int(excl.percept.eq("face").sum())
        row["nLeft_periods"] = int(excl.label.isin(["HouseL", "FaceL"]).sum())
        row["nRight_periods"] = int(excl.label.isin(["HouseR", "FaceR"]).sum())
        row["meanDur_house_s"] = inner.loc[inner.percept == "house", "duration"].mean()
        row["meanDur_face_s"] = inner.loc[inner.percept == "face", "duration"].mean()
        row["medianDur_exclusive_s"] = inner.loc[inner.label.isin(HF), "duration"].median()
        row["alternations"] = n_alt
        row["alternations_per_min"] = 60 * n_alt / run_time if run_time else np.nan
        row["firstExclusivePercept"] = ";".join(
            dr.loc[dr.label.isin(HF), "label"].iloc[0] if dr.label.isin(HF).any() else "-"
            for _, dr in d.groupby(["subject", "run"]))
        out.append(row)
    return pd.DataFrame(out)


def plot_sustained_br(br, summ, title):
    groups = list(br.groupby(["subject", "run"]))
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(9, 1.2 + 0.45 * len(groups) + 2.2),
                                   gridspec_kw={"height_ratios": [max(1, len(groups)), 2.2]})
    ylabels = []
    for i, ((s, run), d) in enumerate(groups):
        for _, r in d.iterrows():
            ax1.barh(i, r.duration, left=r.onset, color=COL[r.label], edgecolor=SURFACE, linewidth=0.8, height=0.7)
        ylabels.append(f"{s} run {run}\n({'FaceL/HouseR' if run == 1 else 'HouseL/FaceR'})")
    ax1.set_yticks(range(len(groups)), ylabels)
    ax1.invert_yaxis()
    ax1.set_xlabel("time in run (s)")
    ax1.set_xlim(0, 60)
    ax1.grid(axis="y", visible=False)
    ax1.set_title(f"{title} - sustained BR (default contrasts): percept over time")
    percept_legend(ax1, cats=HF + ["mixed"] + (["none"] if (br.label == "none").any() else []))
    # proportion of time
    rows = summ.copy()
    labels = [f"{r.subject} run {r.run}" for r in rows.itertuples()]
    left = np.zeros(len(rows))
    for c in HF + ["mixed", "none"]:
        v = rows[f"pctTime_{c}"].values
        ax2.barh(range(len(rows)), v, left=left, color=COL[c], edgecolor=SURFACE, linewidth=1, height=0.65)
        for j, (vv, ll) in enumerate(zip(v, left)):
            if vv >= 7:
                ax2.text(ll + vv / 2, j, f"{vv:.0f}", ha="center", va="center", fontsize=7,
                         color="white" if c in ("HouseL", "FaceL", "mixed") else INK)
        left += v
    for j, r in enumerate(rows.itertuples()):
        ax2.text(101, j, f"house {r.pHouse_time:.2f} | left eye {r.pLeftEye_time:.2f}", va="center", fontsize=7.5,
                 color=INK2)
    ax2.set_yticks(range(len(rows)), labels)
    ax2.invert_yaxis()
    ax2.set_xlim(0, 100)
    ax2.set_xlabel("% of run time   (right: stimulus & eye dominance = share of exclusive time)")
    ax2.grid(axis="y", visible=False)
    fig.tight_layout()
    return fig


# --------------------------------------------------------------------------------------------
# 2./3. QUEST+ tests, calibrations, validations
# --------------------------------------------------------------------------------------------
def label_qp(row):
    """Percept label for QUEST+ calibration/test trials (houseEye 1 = house in the left eye)."""
    r = row.response
    if r == "house":
        return "HouseL" if row.houseEye == 1 else "HouseR"
    if r == "face":
        return "FaceR" if row.houseEye == 1 else "FaceL"
    if r == "mixed":
        return "mixed"
    return "noResp" if pd.isna(r) or r in ("", "none", 0) else "invalid"


def trial_end(d):
    return d[["rivalryOffset", "responseTime"]].max(axis=1)


def load_training_files(subdir, sub):
    out = []
    for f in sorted(subdir.glob(f"{sub}_training_*.mat")):
        sp = loadmat(f)["stimuliParameters"]
        qp = sp.get("questPlus", {}) if isinstance(sp.get("questPlus"), dict) else {}
        tex = qp.get("suggested", {}).get("textures", {}) if qp else {}
        out.append(dict(file=f.name, number=int(re.search(r"_training_(\d+)", f.name).group(1)),
                        questPlusFile=Path(str(qp.get("file", ""))).name, stopReason=qp.get("stopReason", ""),
                        predictedPHouse=np.atleast_1d(qp.get("predictedPHouse", [np.nan, np.nan])).tolist(),
                        houseContrast=sp.get("houseContrast"), faceContrast=sp.get("faceContrast"),
                        leftEyeContrast=sp.get("leftEyeContrast"), rightEyeContrast=sp.get("rightEyeContrast"),
                        **{f"tex_{k}": tex.get(k, np.nan) for k in HF}))
    return out


def training_used_for_main(subdir, trainings):
    """design.mat records trainingFile since 2026-11; otherwise the latest training file was loaded."""
    dm = subdir / "design.mat"
    if dm.exists():
        try:
            design = loadmat(dm).get("design", {})
            tf = design.get("trainingFile")
            if isinstance(tf, str) and tf:
                return Path(tf).name, "design.mat trainingFile"
        except Exception:  # noqa: BLE001
            pass
    if trainings:
        return max(trainings, key=lambda t: t["number"])["file"], "latest training file (assumed)"
    return None, "none"


def design_info(subdir):
    """Rivalry duration of the main runs (design.mat holds the last main run's design)."""
    dm = subdir / "design.mat"
    try:
        design = loadmat(dm).get("design", {}) if dm.exists() else {}
        t = design.get("stimulusPresentationTime")
        return {"rivalry_s_main": round(float(t), 2) if t is not None else np.nan}
    except Exception:  # noqa: BLE001
        return {"rivalry_s_main": np.nan}


def load_calibrations(sub, subdir):
    trainings = load_training_files(subdir, sub)
    used, used_src = training_used_for_main(subdir, trainings)
    cals, trials = [], []
    files = sorted([f for f in subdir.glob(f"sub-{sub}_questplus_*.csv")], key=lambda f: ts_from_name(f.name))
    for k, f in enumerate(files, start=1):
        d = read_csv(f)
        d["label"] = d.apply(label_qp, axis=1)
        d["stage"] = np.where(d.phase.eq("verify"), "validation", "calibration")
        d["calibration"] = k
        d["subject"] = f"sub-{sub}"
        d["file"] = f.name
        cal = d[d.stage == "calibration"]
        val = d[d.stage == "validation"]
        tr = next((t for t in trainings if t["questPlusFile"] == f.with_suffix(".mat").name), None)
        t0 = d.maskOnset.iloc[0]
        row = dict(subject=f"sub-{sub}", calibration=k, file=f.name, start=ts_from_name(f.name).strftime("%H:%M:%S"),
                   nTrials_total=len(d),
                   nTrials_calibration=len(cal),
                   nWarmup=int(d.phase.eq("warmup").sum()) if "phase" in d else 0,
                   nCalibration_houseFace=int(cal.response.isin(["house", "face"]).sum()),
                   nCalibration_mixed=int(cal.response.eq("mixed").sum()),
                   nUsedByQuest=int(d.usedByQuest.sum()) if "usedByQuest" in d else np.nan,
                   nValidations=int(val.validation.nunique()) if len(val) else 0,
                   nTrials_validation=len(val),
                   nValidation_houseFace=int(val.response.isin(["house", "face"]).sum()),
                   time_calibration_min=(trial_end(cal).iloc[-1] - t0) / 60 if len(cal) else np.nan,
                   time_break_min=(val.maskOnset.iloc[0] - trial_end(cal).iloc[-1]) / 60 if len(val) and len(cal) else np.nan,
                   time_validation_min=(trial_end(val).iloc[-1] - val.maskOnset.iloc[0]) / 60 if len(val) else np.nan,
                   time_total_min=(trial_end(d).iloc[-1] - t0) / 60,
                   final_thetaS_log2=cal.thetaS_mean.iloc[-1] if len(cal) else np.nan,
                   final_thetaS_sd=cal.thetaS_sd.iloc[-1] if len(cal) else np.nan,
                   final_thetaE_log2=cal.thetaE_mean.iloc[-1] if len(cal) else np.nan,
                   final_thetaE_sd=cal.thetaE_sd.iloc[-1] if len(cal) else np.nan)
        for cfg, g in val.groupby("eyeConfig"):
            row[f"validation_x_{cfg}"] = g.x.iloc[-1]
            row[f"validation_houseContrast_{cfg}"] = g.houseTextureContrast.iloc[-1]
            row[f"validation_faceContrast_{cfg}"] = g.faceTextureContrast.iloc[-1]
        if tr:
            row.update(trainingFile=tr["file"], stopReason=tr["stopReason"],
                       predictedPHouse_HouseL=tr["predictedPHouse"][0], predictedPHouse_HouseR=tr["predictedPHouse"][-1],
                       houseContrast=tr["houseContrast"], faceContrast=tr["faceContrast"],
                       leftEyeContrast=tr["leftEyeContrast"], rightEyeContrast=tr["rightEyeContrast"],
                       **{f"final_texture_{c}": tr[f"tex_{c}"] for c in HF})
            row["usedForMain"] = tr["file"] == used
            row["usedForMain_source"] = used_src
        cals.append(row)
        trials.append(d)
    cal_df = pd.DataFrame(cals)
    trials = pd.concat(trials, ignore_index=True) if trials else pd.DataFrame()
    return cal_df, trials


def load_tests(sub, subdir, cal_df):
    out, trials = [], []
    cal_starts = [(r.calibration, datetime.strptime(r.file.split("_questplus_")[1][:17], "%Y-%m-%d_%H%M%S"))
                  for r in cal_df.itertuples()] if len(cal_df) else []
    for f in sorted(subdir.glob(f"sub-{sub}_questplus-test*.csv"), key=lambda f: ts_from_name(f.name)):
        d = read_csv(f)
        d["label"] = d.apply(label_qp, axis=1)
        t = ts_from_name(f.name)
        nxt = [k for k, s in cal_starts if s > t]
        prv = [k for k, s in cal_starts if s < t]
        position = (f"before calibration {nxt[0]}" if nxt else "after the last calibration")
        contrasts = "default (all 1)"
        mf = f.with_suffix(".mat")
        if mf.exists():
            try:
                sp = loadmat(mf)["results"]["stimuliParameters"]
                qf = sp.get("questPlus", {})
                if isinstance(qf, dict) and qf.get("file"):
                    k = [r.calibration for r in cal_df.itertuples() if r.file == Path(str(qf["file"])).with_suffix(".csv").name]
                    contrasts = f"calibration {k[0]}" if k else Path(str(qf["file"])).name
            except Exception:  # noqa: BLE001
                pass
        elif prv:
            contrasts = f"calibration {prv[-1]} (assumed)"
        mode = d.taskMode.iloc[0] if "taskMode" in d else ""
        name = f"test {t:%H:%M} ({mode})"
        d["subject"], d["stage"], d["file"] = f"sub-{sub}", name, f.name
        trials.append(d)
        out.append(dict(subject=f"sub-{sub}", stage=name, file=f.name, start=t.strftime("%H:%M:%S"),
                        taskMode=mode, position=position, contrasts=contrasts,
                        rightBeforeCalibration=bool(nxt),
                        time_min=(trial_end(d).iloc[-1] - d.maskOnset.iloc[0]) / 60,
                        **percept_summary(d.label.tolist(), d.rt)))
    return pd.DataFrame(out), (pd.concat(trials, ignore_index=True) if trials else pd.DataFrame())


def plot_calibration(trials, cal_df, title):
    cals = sorted(trials.calibration.unique())
    fig, axes = plt.subplots(2, len(cals), figsize=(6.2 * len(cals), 6.4), squeeze=False, sharex="col")
    for j, k in enumerate(cals):
        d = trials[trials.calibration == k].reset_index(drop=True)
        x = np.arange(1, len(d) + 1)
        a = axes[0, j]
        for col, lab, c in [("thetaS", "θS stimulus balance", COL["house"]), ("thetaE", "θE eye balance", INK2)]:
            m, s = d[f"{col}_mean"].values, d[f"{col}_sd"].values
            a.plot(x, m, color=c, lw=2, label=lab)
            a.fill_between(x, m - s, m + s, color=c, alpha=0.15, lw=0)
        nv = d.index[d.stage == "validation"]
        for aa in axes[:, j]:
            if len(nv):
                aa.axvline(nv[0] + 0.5, color=MUTED, ls="--", lw=1)
        if len(nv):
            a.text(nv[0] + 1.5, a.get_ylim()[1], "validation", va="top", fontsize=8, color=INK2)
        a.set_ylabel("posterior mean ± SD (log2)")
        r = cal_df[cal_df.calibration == k].iloc[0]
        used = " - used for main" if r.get("usedForMain", False) else ""
        a.set_title(f"{title} calibration {k} ({r.start}){used}")
        a.legend(loc="lower right")
        b = axes[1, j]
        for resp, mk in [("house", "o"), ("face", "o"), ("mixed", "x")]:
            for cfg, fill in [("HouseL_FaceR", True), ("FaceL_HouseR", False)]:
                s = d[(d.response == resp) & (d.eyeConfig == cfg)]
                if not len(s):
                    continue
                cc = COL.get(resp, MUTED) if resp != "mixed" else MUTED
                if mk == "x":
                    b.scatter(s.index + 1, s.x, s=26, marker=mk, color=cc, linewidths=1.2)
                else:
                    b.scatter(s.index + 1, s.x, s=26, marker=mk,
                              facecolors=cc if fill else "none", edgecolors=cc, linewidths=1.2)
        b.set_xlabel("trial")
        b.set_ylabel("x = log2 house/face contrast ratio")
        b.set_title(f"stimulus level per trial: n = {r.nTrials_calibration} calibration "
                    f"({r.time_calibration_min:.1f} min) + {r.nTrials_validation} validation "
                    f"({r.time_validation_min:.1f} min)", fontsize=9, fontweight="normal")
    handles = [Line2D([], [], marker="o", ls="", color=COL["house"], label="house (house in left eye)"),
               Line2D([], [], marker="o", ls="", mfc="none", color=COL["house"], label="house (house in right eye)"),
               Line2D([], [], marker="o", ls="", color=COL["face"], label="face (house left / face right)"),
               Line2D([], [], marker="o", ls="", mfc="none", color=COL["face"], label="face (face left / house right)"),
               Line2D([], [], marker="x", ls="", color=MUTED, label="mixed")]
    axes[1, -1].legend(handles=handles, loc="upper left", bbox_to_anchor=(1.0, 1.0))
    fig.tight_layout()
    return fig


# --------------------------------------------------------------------------------------------
# 4. main experiment
# --------------------------------------------------------------------------------------------
def label_main(row):
    p = row.perceived
    # response can be numeric, a string ('0') or several keys ('84,81'); perceived is the logged first percept key
    resp = str(row.response).strip() if "response" in row else ""
    if resp in ("0", "0.0", "", "nan") or (p == "mixed" and pd.isna(row.rt)):
        return "noResp"
    if p == "mixed":
        return "mixed"
    if p in ("house", "face"):
        if row.leftEye == p:
            return p.capitalize() + "L"
        if row.rightEye == p:
            return p.capitalize() + "R"
        return "catch_" + p  # report catch trial: same image in both eyes
    return "invalid"


def catch_shown(row):
    """What a report catch trial showed in both eyes: house, face or mixed (house/face patches)."""
    s = str(row.leftEye).lower()
    has_h, has_f = "house" in s, "face" in s
    if has_h and has_f:
        return "mixed"
    return "house" if has_h else ("face" if has_f else "?")


def load_main(sub, subdir):
    frames = []
    for f in sorted(subdir.glob(f"sub-{sub}_run-*_*.csv")):
        m = re.search(r"_run-(\d+)_([a-z]+)_", f.name)
        if not m or m.group(2) not in TASKS:
            continue
        d = read_csv(f)
        d["subject"], d["task"], d["run"], d["file"] = f"sub-{sub}", TASKS[m.group(2)], int(m.group(1)), f.name
        d["runStart"] = ts_from_name(f.name)
        frames.append(d)
    if not frames:
        return pd.DataFrame()
    d = pd.concat(frames, ignore_index=True)
    d["cue"] = d.cue.astype(str)
    d.loc[d.condition == "baseline", "cue"] = "-"   # older runs logged a (meaningless) cue on baseline trials
    d["isCatchTrial"] = d.isCatchTrial.fillna(0).astype(int)
    rep = d.task.isin(["report", "dual"])
    d["label"] = None
    d.loc[rep, "label"] = d[rep].apply(label_main, axis=1)
    d.loc[~rep, "label"] = "noReport"
    d["houseEye"] = np.where(d.leftEye.eq("house"), "L", np.where(d.rightEye.eq("house"), "R", ""))
    d["eyeConfig"] = np.where(d.houseEye.eq("L"), "HouseL_FaceR", np.where(d.houseEye.eq("R"), "FaceL_HouseR", "catch"))
    d["perceivedStim"] = d.label.map(lambda x: "house" if str(x).startswith("House") else
                                     ("face" if str(x).startswith("Face") else ""))
    d["congruent"] = np.where(d.perceivedStim.eq(""), np.nan,
                              np.where(d.cue.isin(CUES), (d.perceivedStim == d.cue).astype(float), np.nan))
    d["rt"] = pd.to_numeric(d.get("rt"), errors="coerce")
    d.loc[d.label.eq("noResp"), "rt"] = np.nan
    d["rating"] = pd.to_numeric(d.rating, errors="coerce")
    # chronological order of runs within subject
    order = d.groupby(["subject", "task", "run"]).runStart.first().sort_values()
    order = order.reset_index().reset_index().rename(columns={"index": "runOrder"})
    d = d.merge(order[["subject", "task", "run", "runOrder"]], on=["subject", "task", "run"])
    d["runOrder"] = d.groupby("subject").runOrder.transform(lambda x: x.rank(method="dense").astype(int))
    return d


def main_condition_table(d, subject_name):
    """Rows: per task x condition x cue (+ aggregates). d = non-catch report/dual trials."""
    rows = []

    def add(task, cond, cue, g):
        extra = dict(subject=subject_name, task=task, condition=cond, cue=cue)
        congr = g.congruent.dropna()
        extra["pCongruent"] = congr.mean() if len(congr) else np.nan
        extra["nCongruent"] = int(congr.sum()) if len(congr) else 0
        for cfg in ["HouseL_FaceR", "FaceL_HouseR"]:
            gg = g[g.eyeConfig == cfg]
            hf = gg.perceivedStim.isin(CUES)
            extra[f"pHouse_given_{cfg}"] = (gg.perceivedStim[hf] == "house").mean() if hf.any() else np.nan
            extra[f"nHouseFace_{cfg}"] = int(hf.sum())
        extra["rating_mean"] = g.rating.mean()
        rows.append(percept_summary(g.label.tolist(), g.rt, extra))

    for task in ["report", "dual"]:
        t = d[d.task == task]
        if t.empty:
            continue
        add(task, "baseline", "-", t[t.condition == "baseline"])
        for cond in CONDITIONS[1:]:
            for cue in CUES:
                add(task, cond, cue, t[(t.condition == cond) & (t.cue == cue)])
            add(task, cond, "both", t[t.condition == cond])
        for cue in CUES:
            add(task, "all cued", cue, t[(t.condition != "baseline") & (t.cue == cue)])
        add(task, "all cued", "both", t[t.condition != "baseline"])
        add(task, "ALL", "all", t)
    if d.task.nunique() > 1:
        add("report+dual", "baseline", "-", d[d.condition == "baseline"])
        add("report+dual", "ALL", "all", d)
    out = pd.DataFrame(rows)
    first = ["subject", "task", "condition", "cue"]
    return out[first + [c for c in out.columns if c not in first]]


def cue_effect_table(d, subject_name):
    """Fisher tests on P(house | house/face): house cue vs face cue, and each cue vs baseline."""
    rows = []
    for task in ["report", "dual"]:
        t = d[(d.task == task) & d.perceivedStim.isin(CUES)]
        if t.empty:
            continue
        base = t[t.condition == "baseline"]
        kb, nb = int((base.perceivedStim == "house").sum()), len(base)
        for cond in CONDITIONS[1:]:
            g = t[t.condition == cond]
            kh = int((g[g.cue == "house"].perceivedStim == "house").sum()); nh = int((g.cue == "house").sum())
            kf = int((g[g.cue == "face"].perceivedStim == "house").sum()); nf = int((g.cue == "face").sum())
            rows.append(dict(subject=subject_name, task=task, condition=cond,
                             pHouse_houseCue=kh / nh if nh else np.nan, n_houseCue=nh,
                             pHouse_faceCue=kf / nf if nf else np.nan, n_faceCue=nf,
                             pHouse_baseline=kb / nb if nb else np.nan, n_baseline=nb,
                             cueEffect_houseMinusFace=(kh / nh if nh else np.nan) - (kf / nf if nf else np.nan),
                             fisher_p_houseCue_vs_faceCue=fisher_p(kh, nh, kf, nf),
                             fisher_p_houseCue_vs_baseline=fisher_p(kh, nh, kb, nb),
                             fisher_p_faceCue_vs_baseline=fisher_p(kf, nf, kb, nb)))
    return pd.DataFrame(rows)


def catch_table(dall, subject_name):
    rows = []
    c = dall[(dall.isCatchTrial == 1) & dall.task.isin(["report", "dual"])].copy()
    for task, g in c.groupby("task"):
        if task == "report":
            g = g.copy()
            g["shown"] = g.apply(catch_shown, axis=1)
            g["reported"] = g.perceived.where(g.label != "noResp", "noResp")
            for shown, gg in g.groupby("shown"):
                correct = (gg.reported == shown).sum()
                rows.append(dict(subject=subject_name, task=task, catchType=f"same image both eyes: {shown}",
                                 n=len(gg), nCorrect=int(correct),
                                 reported=", ".join(f"{k} {v}" for k, v in gg.reported.value_counts().items())))
        else:
            for nd, gg in g.groupby(g.fixDotPosHouse.astype(str).str.contains(",")):
                rows.append(dict(subject=subject_name, task=task,
                                 catchType="2 fixation dots (BR as usual)" if nd else "1 fixation dot per eye, same position",
                                 n=len(gg), nCorrect=np.nan,
                                 reported=", ".join(f"{k} {v}" for k, v in gg.label.value_counts().items())))
    return pd.DataFrame(rows)


def run_table(d, subject_name):
    rows = []
    for (task, run), g in d.groupby(["task", "run"]):
        s = percept_summary(g.label.tolist(), g.rt)
        rows.append(dict(subject=subject_name, task=task, run=run, runOrder=g.runOrder.iloc[0],
                         start=g.runStart.iloc[0].strftime("%H:%M") if pd.notna(g.runStart.iloc[0]) else "",
                         duration_min=(g.ITIOnset.max() - g.cueOnset.min()) / 60 + 0.0,
                         **{k: s[k] for k in ["n", *PERCEPTS[:6], "pHouse", "pLeftEye", "pMixedOrNoResp", "rt_median"]},
                         rating_mean=g.rating.mean()))
    return pd.DataFrame(rows).sort_values(["subject", "runOrder"]) if rows else pd.DataFrame()


def sequential_table(d, subject_name):
    """Repetition of perceived stimulus / eye on consecutive non-catch trials within a run."""
    rows = []
    for task, t in d.groupby("task"):
        same_s = same_e = n = 0
        exp_s = exp_e = 0.0   # expected repetitions under independence, from each subject's own rates
        for subj, ts in t.groupby("subject"):
            hf = ts.label[ts.label.isin(HF)]
            ph = hf.str.startswith("House").mean() if len(hf) else np.nan
            pl = hf.str.endswith("L").mean() if len(hf) else np.nan
            for _, g in ts.sort_values("trial").groupby("run"):
                lab = g.label.tolist()
                for a, b in zip(lab[:-1], lab[1:]):
                    if a in HF and b in HF:
                        n += 1
                        same_s += a[:-1] == b[:-1]
                        same_e += a[-1] == b[-1]
                        exp_s += ph ** 2 + (1 - ph) ** 2
                        exp_e += pl ** 2 + (1 - pl) ** 2
        es, ee = (exp_s / n, exp_e / n) if n else (np.nan, np.nan)
        rows.append(dict(subject=subject_name, task=task, nPairs=n,
                         pSameStimulus=same_s / n if n else np.nan, pSameStimulus_expected=es,
                         binom_p_sameStimulus=binom_p(same_s, n, es) if n else np.nan,
                         pSameEye=same_e / n if n else np.nan, pSameEye_expected=ee,
                         binom_p_sameEye=binom_p(same_e, n, ee) if n else np.nan))
    return pd.DataFrame(rows)


def rating_table(dall, subject_name):
    rows = []
    d = dall[dall.isCatchTrial == 0]
    for (task, cond, cue), g in d.groupby(["task", "condition", "cue"]):
        r = g.rating.dropna()
        rows.append(dict(subject=subject_name, task=task, condition=cond, cue=cue, n=len(r), rating_mean=r.mean(),
                         rating_sd=r.std(), rating_sem=r.std() / np.sqrt(len(r)) if len(r) > 1 else np.nan,
                         nMissing=int(g.rating.isna().sum())))
    out = pd.DataFrame(rows)
    if out.empty:
        return out
    out["task"] = pd.Categorical(out.task, TASK_ORDER, ordered=True)
    out["condition"] = pd.Categorical(out.condition, CONDITIONS, ordered=True)
    return out.sort_values(["task", "condition", "cue"]).astype({"task": str, "condition": str})


# ---------------------------------------------- main-experiment plots
XCOND = [("baseline", "-", "Baseline"), ("perception", "house", "P · house"), ("perception", "face", "P · face"),
         ("attention", "house", "A · house"), ("attention", "face", "A · face"),
         ("imagery", "house", "I · house"), ("imagery", "face", "I · face")]


def stacked_bars(ax, rows, labels, title, horizontal=False, label_n=True):
    bottom = np.zeros(len(rows))
    cats = ["HouseL", "FaceL", "HouseR", "FaceR", "mixed", "noResp", "invalid"]
    cats = [c for c in cats if c not in ("invalid",) or any(r.get(c, 0) for r in rows)]
    pos = np.arange(len(rows))
    for c in cats:
        v = np.array([100 * r[c] / r["n"] if r["n"] else 0 for r in rows])
        cnt = [r[c] for r in rows]
        if horizontal:
            ax.barh(pos, v, left=bottom, color=COL[c], edgecolor=SURFACE, linewidth=1, height=0.68)
        else:
            ax.bar(pos, v, bottom=bottom, color=COL[c], edgecolor=SURFACE, linewidth=1, width=0.68)
        for j, (vv, bb, k) in enumerate(zip(v, bottom, cnt)):
            if vv >= 8:
                xy = (bb + vv / 2, j) if horizontal else (j, bb + vv / 2)
                ax.text(*xy, str(k), ha="center", va="center", fontsize=7,
                        color="white" if c in ("HouseL", "FaceL", "mixed", "invalid") else INK)
        bottom += v
    if horizontal:
        ax.set_yticks(pos, labels)
        ax.invert_yaxis()
        ax.set_xlim(0, 100)
        ax.set_xlabel("% of trials (numbers = trial counts)")
        ax.grid(axis="y", visible=False)
        if label_n:
            for j, r in enumerate(rows):
                ph = r.get("pHouse", np.nan)
                pl = r.get("pLeftEye", np.nan)
                ax.text(101, j, f"n={r['n']}  house {ph:.2f}  left {pl:.2f}", va="center", fontsize=7.5, color=INK2)
    else:
        ax.set_xticks(pos, labels)
        ax.set_ylim(0, 108)
        ax.set_ylabel("% of trials (numbers = counts)")
        ax.grid(axis="x", visible=False)
        if label_n:
            for j, r in enumerate(rows):
                ax.text(j, 101.5, f"n={r['n']}", ha="center", fontsize=7, color=INK2)
    ax.set_title(title)


def plot_main_percepts(d, title):
    tasks = [t for t in ["report", "dual"] if (d.task == t).any()]
    fig, axes = plt.subplots(1, len(tasks), figsize=(5.4 * len(tasks) + 1.4, 4.2), squeeze=False)
    for ax, task in zip(axes[0], tasks):
        t = d[d.task == task]
        rows = [counts_of(t[(t.condition == c) & (t.cue == q)].label) |
                {"n": int(((t.condition == c) & (t.cue == q)).sum())} for c, q, _ in XCOND]
        rows.append(counts_of(t.label) | {"n": len(t)})
        stacked_bars(ax, rows, [x[2] for x in XCOND] + ["all"], f"{title} - {task}: percept per condition & cue")
        ax.tick_params(axis="x", labelrotation=35)
    percept_legend(axes[0, -1])
    fig.tight_layout()
    return fig


def dot_ci(ax, x, k, n, color, marker="o", filled=True, label=None):
    if n == 0:
        return
    p = k / n
    lo, hi = wilson(k, n)
    ax.plot([x, x], [lo, hi], color=color, lw=2, solid_capstyle="round")
    ax.plot(x, p, marker=marker, ms=8, color=color, mfc=color if filled else SURFACE, mec=color, mew=1.6,
            ls="", label=label)


def plot_main_dominance(d, title, subjects=None):
    """Stimulus dominance P(house) and eye dominance P(left) with Wilson 95 % CI per condition & cue."""
    tasks = [t for t in ["report", "dual"] if (d.task == t).any()]
    fig, axes = plt.subplots(2, len(tasks), figsize=(5.6 * len(tasks), 6.6), squeeze=False, sharey=True)
    for j, task in enumerate(tasks):
        t = d[(d.task == task) & d.label.isin(HF)]
        for i, (measure, ylabel) in enumerate([("house", "P(house | house or face)"),
                                               ("left", "P(left eye | house or face)")]):
            ax = axes[i, j]
            hit = (t.perceivedStim == "house") if measure == "house" else t.label.isin(["HouseL", "FaceL"])
            base = t.condition == "baseline"
            kb, nb = int(hit[base].sum()), int(base.sum())
            if nb:
                lo, hi = wilson(kb, nb)
                ax.axhspan(lo, hi, color=MUTED, alpha=0.12, lw=0)
                ax.axhline(kb / nb, color=MUTED, lw=1, ls=":")
            ax.axhline(0.5, color=AXIS, lw=1)
            positions = list(range(len(XCOND))) + [len(XCOND) + 0.4]
            for x, (c, q, _) in zip(positions, XCOND + [("ALL", "all", "all")]):
                sel = (t.condition == c) & (t.cue == q) if c != "ALL" else pd.Series(True, index=t.index)
                col = COL["-"] if q in ("-", "all") else COL[q]
                dot_ci(ax, x, int(hit[sel].sum()), int(sel.sum()), col)
                ax.text(x, -0.07, f"{int(hit[sel].sum())}/{int(sel.sum())}", ha="center", fontsize=7, color=INK2)
                if subjects is not None and c != "ALL":
                    for si, s in enumerate(subjects):
                        ss = sel & (t.subject == s)
                        if ss.sum():
                            ax.plot(x + 0.22, hit[ss].mean(), marker=["s", "^", "D", "v", "P"][si % 5], ms=4.5,
                                    color=MUTED, ls="")
            ax.set_xticks(positions, [x[2] for x in XCOND] + ["all"])
            ax.tick_params(axis="x", labelrotation=35)
            ax.set_ylim(-0.12, 1.04)
            ax.set_ylabel(ylabel)
            ax.set_title(f"{title} - {task}: {'stimulus' if measure == 'house' else 'eye'} dominance")
            ax.grid(axis="x", visible=False)
    handles = [Line2D([], [], marker="o", ls="-", color=COL["house"], label="house cue"),
               Line2D([], [], marker="o", ls="-", color=COL["face"], label="face cue"),
               Line2D([], [], marker="o", ls="-", color=COL["-"], label="baseline / all"),
               Patch(facecolor=MUTED, alpha=0.25, label="baseline 95 % CI")]
    if subjects is not None:
        handles += [Line2D([], [], marker=["s", "^", "D", "v", "P"][i % 5], ls="", color=MUTED, label=s)
                    for i, s in enumerate(subjects)]
    axes[0, -1].legend(handles=handles, loc="upper left", bbox_to_anchor=(1.0, 1.0))
    fig.text(0.01, 0.0, "Dots: proportion with Wilson 95 % CI; numbers: k / n (house-or-face trials only); "
             "dotted line + band: baseline.", fontsize=7.5, color=INK2)
    fig.tight_layout()
    return fig


def plot_main_rt(d, title):
    tasks = [t for t in ["report", "dual"] if (d.task == t).any()]
    fig, axes = plt.subplots(2, len(tasks), figsize=(5.8 * len(tasks) + 1.2, 7.4), squeeze=False,
                             gridspec_kw={"height_ratios": [3, 2]})
    rng = np.random.default_rng(1)
    for j, task in enumerate(tasks):
        t = d[(d.task == task) & d.rt.notna()]
        ax = axes[0, j]
        for x, (c, q, _) in enumerate(XCOND):
            g = t[(t.condition == c) & (t.cue == q)]
            for lab in HF + ["mixed", "invalid"]:
                gg = g[g.label == lab]
                if len(gg):
                    ax.scatter(x + rng.uniform(-0.25, 0.25, len(gg)), gg.rt, s=16, color=COL[lab],
                               edgecolors=SURFACE, linewidths=0.5, zorder=3)
            if len(g):
                ax.plot([x - 0.32, x + 0.32], [g.rt.median()] * 2, color=INK, lw=2, zorder=4)
                ax.text(x, ax.get_ylim()[1] if False else g.rt.max() + 0.08, f"{g.rt.median():.2f}",
                        ha="center", fontsize=7, color=INK2)
        ax.set_xticks(range(len(XCOND)), [x[2] for x in XCOND])
        ax.tick_params(axis="x", labelrotation=35)
        ax.set_ylabel("RT from rivalry onset (s)")
        ax.set_title(f"{title} - {task}: RT per condition & cue (bar = median)")
        ax.grid(axis="x", visible=False)
        # by percept
        ax = axes[1, j]
        labs = [l for l in HF + ["mixed"] if (t.label == l).any()]
        data = [t.rt[t.label == l].values for l in labs]
        bp = ax.boxplot(data, positions=range(len(labs)), widths=0.55, patch_artist=True, showfliers=False,
                        medianprops=dict(color=INK, lw=1.8), whiskerprops=dict(color=MUTED),
                        capprops=dict(color=MUTED))
        for patch, l in zip(bp["boxes"], labs):
            patch.set_facecolor(COL[l]); patch.set_edgecolor(SURFACE); patch.set_alpha(0.9)
        for x, (l, v) in enumerate(zip(labs, data)):
            ax.scatter(x + rng.uniform(-0.18, 0.18, len(v)), v, s=8, color=INK2, alpha=0.5, zorder=3)
        ax.set_xticks(range(len(labs)), [f"{l}\nn={len(v)}" for l, v in zip(labs, data)])
        ax.set_ylabel("RT (s)")
        ax.set_title(f"{task}: RT per percept (all conditions)")
        ax.grid(axis="x", visible=False)
    percept_legend(axes[0, -1], cats=HF + ["mixed"])
    fig.tight_layout()
    return fig


def plot_stage_overview(stages, title):
    """stages: list of (label, labels list) -> horizontal 100 % stacked bars."""
    rows = [percept_summary(lab) for _, lab in stages]
    fig, ax = plt.subplots(figsize=(10.5, 0.55 * len(rows) + 1.4))
    stacked_bars(ax, rows, [s for s, _ in stages],
                 f"{title} - percepts per stage (house/left = share of house-or-face trials)", horizontal=True)
    percept_legend(ax, loc="upper left", bbox_to_anchor=(0.0, -0.18), ncol=7)
    fig.tight_layout()
    return fig


def plot_eye_config(stage_trials, title):
    """P(house) separately for the two eye configurations, per stage (shows eye x stimulus interplay)."""
    fig, ax = plt.subplots(figsize=(max(6, 1.15 * len(stage_trials) + 2), 4.0))
    for x, (name, lab, cfg) in enumerate(stage_trials):
        lab, cfg = pd.Series(lab), pd.Series(cfg)
        for c, mk, dx, filled in [("HouseL_FaceR", "o", -0.12, True), ("FaceL_HouseR", "o", 0.12, False)]:
            sel = (cfg.values == c) & lab.isin(HF).values
            k = int(lab[sel].str.startswith("House").sum())
            dot_ci(ax, x + dx, k, int(sel.sum()), COL["house"], filled=filled)
    ax.axhline(0.5, color=AXIS, lw=1)
    ax.set_xticks(range(len(stage_trials)), [s[0] for s in stage_trials])
    ax.tick_params(axis="x", labelrotation=30)
    ax.set_ylim(-0.03, 1.03)
    ax.set_ylabel("P(house | house or face)")
    ax.set_title(f"{title} - house seen, split by eye configuration")
    ax.grid(axis="x", visible=False)
    ax.legend(handles=[Line2D([], [], marker="o", color=COL["house"], label="house in LEFT eye (HouseL/FaceR)"),
                       Line2D([], [], marker="o", mfc=SURFACE, color=COL["house"],
                              label="house in RIGHT eye (FaceL/HouseR)")],
              loc="upper left", bbox_to_anchor=(1.0, 1.0))
    fig.tight_layout()
    return fig


def plot_runs(runs, title):
    fig, ax = plt.subplots(figsize=(max(7, 0.42 * len(runs) + 3), 3.6))
    runs = runs.reset_index(drop=True)
    x = np.arange(len(runs))
    for col, lab, c, mk in [("pHouse", "P(house)", COL["house"], "o"), ("pLeftEye", "P(left eye)", INK2, "s"),
                            ("pMixedOrNoResp", "P(mixed or no response)", MUTED, "^")]:
        for task, ls in [("report", "-"), ("dual", "--")]:
            first = True
            for _, g in runs[runs.task == task].groupby("subject"):   # no lines across subjects
                ax.plot(x[g.index], g[col], marker=mk, color=c, ls=ls, lw=2, ms=6,
                        label=f"{lab} ({task})" if first else None)
                first = False
    ax.axhline(0.5, color=AXIS, lw=1)
    ax.set_xticks(x, [f"{r.subject[-2:]} {r.task[:2]}{r.run}\n{r.start}" for r in runs.itertuples()], fontsize=7)
    ax.set_ylim(-0.03, 1.03)
    ax.set_ylabel("proportion (non-catch trials)")
    ax.set_title(f"{title} - time course over runs (chronological)")
    ax.grid(axis="x", visible=False)
    ax.legend(loc="upper left", bbox_to_anchor=(1.0, 1.0))
    fig.tight_layout()
    return fig


def plot_ratings(dall, title):
    d = dall[dall.isCatchTrial == 0]
    tasks = [t for t in TASK_ORDER if (d.task == t).any()]
    fig, ax = plt.subplots(figsize=(9, 3.8))
    width = 0.8 / len(tasks)
    for i, task in enumerate(tasks):
        t = d[d.task == task]
        for x, (c, q, _) in enumerate(XCOND):
            r = t[(t.condition == c) & (t.cue == q)].rating.dropna()
            if not len(r):
                continue
            xx = x - 0.4 + width * (i + 0.5)
            se = r.std() / np.sqrt(len(r)) if len(r) > 1 else 0
            ax.bar(xx, r.mean(), width=width * 0.9, color=["#6250d6", "#1baf7a", "#898781"][i % 3],
                   edgecolor=SURFACE, alpha=0.9, label=task if x == 0 else None)
            ax.plot([xx, xx], [r.mean() - se, r.mean() + se], color=INK, lw=1.2)
    ax.set_xticks(range(len(XCOND)), [x[2] for x in XCOND])
    ax.set_ylim(1, 5.2)
    ax.set_ylabel("rating 1-5 (mean ± SEM)")
    ax.set_title(f"{title} - self-rated task performance (P/A/I/x task)")
    ax.grid(axis="x", visible=False)
    ax.legend(loc="upper left", bbox_to_anchor=(1.0, 1.0))
    fig.tight_layout()
    return fig


def plot_calib_rt(stage_rt, title):
    fig, ax = plt.subplots(figsize=(max(6, 1.0 * len(stage_rt) + 2), 3.6))
    rng = np.random.default_rng(2)
    for x, (name, rt, lab) in enumerate(stage_rt):
        rt, lab = pd.Series(rt, dtype=float), pd.Series(lab)
        ok = rt.notna()
        for l in HF + ["mixed", "invalid"]:
            s = ok & (lab == l)
            if s.any():
                ax.scatter(x + rng.uniform(-0.25, 0.25, s.sum()), rt[s], s=12, color=COL[l], edgecolors=SURFACE,
                           linewidths=0.4, zorder=3)
        if ok.any():
            ax.plot([x - 0.32, x + 0.32], [rt[ok].median()] * 2, color=INK, lw=2, zorder=4)
    ax.set_xticks(range(len(stage_rt)), [s[0] for s in stage_rt])
    ax.tick_params(axis="x", labelrotation=30)
    ax.set_ylabel("RT from rivalry onset (s)")
    ax.set_title(f"{title} - RT per stage (bar = median)")
    ax.grid(axis="x", visible=False)
    percept_legend(ax, cats=HF + ["mixed"])
    fig.tight_layout()
    return fig


# --------------------------------------------------------------------------------------------
# driver
# --------------------------------------------------------------------------------------------
def analyse_subject(sub, raw, out, include_dual_catch):
    subdir = raw / f"sub-{sub}"
    name = f"sub-{sub}"
    tdir, fdir = out / name / "tables", out / name / "figures"
    res = {"name": name, **design_info(subdir)}

    # 1 sustained BR
    br = load_sustained_br(sub, subdir)
    res["br"] = br
    if len(br):
        res["br_summary"] = summarise_sustained_br(br, name)
        save_table(br, tdir, "01_sustainedBR_periods")
        save_table(res["br_summary"], tdir, "01_sustainedBR_summary")
        savefig(plot_sustained_br(br, res["br_summary"], name), fdir, "01_sustainedBR")

    # 2/3 calibrations, tests
    cal_df, cal_trials = load_calibrations(sub, subdir)
    tests, test_trials = load_tests(sub, subdir, cal_df)
    res.update(cal=cal_df, cal_trials=cal_trials, tests=tests, test_trials=test_trials)
    if len(cal_df):
        save_table(cal_df, tdir, "03_calibration_summary")
        save_table(cal_trials, tdir, "03_calibration_trials")
        savefig(plot_calibration(cal_trials, cal_df, name), fdir, "03_calibration")
        rows = []
        for (k, stage), g in cal_trials.groupby(["calibration", "stage"]):
            for v, gg in ([("all", g)] + list(g.groupby("validation")) if stage == "validation" else [("all", g)]):
                if stage == "validation" and v != "all" and g.validation.nunique() == 1:
                    continue
                rows.append(dict(subject=name, calibration=k, stage=stage, validation=v,
                                 **percept_summary(gg.label.tolist(), gg.rt)))
        res["cal_percepts"] = pd.DataFrame(rows)
        save_table(res["cal_percepts"], tdir, "03_calibration_validation_percepts")
    if len(tests):
        save_table(tests, tdir, "02_questplus_tests")

    # 4 main
    dall = load_main(sub, subdir)
    res["main_all"] = dall
    if dall.empty:
        return res
    save_table(dall, tdir, "04_main_trials_long")
    rep = dall[dall.task.isin(["report", "dual"])]
    keep = rep.isCatchTrial.eq(0) | (include_dual_catch & rep.task.eq("dual"))
    d = rep[keep & ~rep.label.str.startswith("catch_")].copy()
    res["main"] = d
    tabs = {
        "04_main_percepts_by_condition": main_condition_table(d, name),
        "04_main_cue_effects": cue_effect_table(d, name),
        "04_main_catch_trials": catch_table(dall, name),
        "04_main_runs": run_table(d, name),
        "04_main_sequential": sequential_table(d, name),
        "04_main_ratings": rating_table(dall, name),
    }
    res.update(tabs)
    for k, v in tabs.items():
        save_table(v, tdir, k)

    savefig(plot_main_percepts(d, name), fdir, "04_main_percepts")
    savefig(plot_main_dominance(d, name), fdir, "05_main_dominance")
    savefig(plot_main_rt(d, name), fdir, "06_main_rt")
    savefig(plot_runs(tabs["04_main_runs"], name), fdir, "08_runs_timecourse")
    savefig(plot_ratings(dall, name), fdir, "09_ratings")

    # chronological stage overview (tests, calibrations, validations, main)
    stages, stage_cfg, stage_rt = [], [], []
    chunks = []
    if len(test_trials):
        for st, g in test_trials.groupby("stage"):
            chunks.append((g.file.iloc[0], st, g.label.tolist(), g.eyeConfig.tolist(), g.rt.tolist()))
    if len(cal_trials):
        for (k, stage), g in cal_trials.groupby(["calibration", "stage"]):
            nm = f"calib. {k}" + (" validation" if stage == "validation" else " adaptive")
            chunks.append((g.file.iloc[0] + ("_v" if stage == "validation" else "_a"), nm,
                           g.label.tolist(), g.eyeConfig.tolist(), g.rt.tolist()))
    chunks.sort(key=lambda c: (ts_from_name(c[0]), c[0]))
    for task in ["report", "dual"]:
        t = d[d.task == task]
        if len(t):
            b = t[t.condition == "baseline"]
            chunks.append(("", f"{task} baseline", b.label.tolist(), b.eyeConfig.tolist(), b.rt.tolist()))
            chunks.append(("", f"{task} all", t.label.tolist(), t.eyeConfig.tolist(), t.rt.tolist()))
    for _, nm, lab, cfg, rt in chunks:
        stages.append((nm, lab))
        stage_cfg.append((nm, lab, cfg))
        stage_rt.append((nm, rt, lab))
    res["stages"], res["stage_cfg"], res["stage_rt"] = stages, stage_cfg, stage_rt
    save_table(pd.DataFrame([dict(subject=name, stage=s, **percept_summary(l)) for s, l in stages]),
               tdir, "02_stage_overview")
    savefig(plot_stage_overview(stages, name), fdir, "02_stage_overview")
    savefig(plot_eye_config(stage_cfg, name), fdir, "07_house_by_eye_configuration")
    savefig(plot_calib_rt(stage_rt, name), fdir, "06b_rt_per_stage")
    return res


def analyse_pooled(results, out):
    name = "pooled"
    tdir, fdir = out / name / "tables", out / name / "figures"
    subs = [r["name"] for r in results]
    pooled = {}
    # sustained BR
    brs = [r["br"] for r in results if len(r.get("br", []))]
    if brs:
        br = pd.concat(brs, ignore_index=True)
        summ = pd.concat([summarise_sustained_br(br[br.subject == s], s) for s in br.subject.unique()]
                         + [summarise_sustained_br(br, name).query("run == 'all'")], ignore_index=True)
        pooled["br_summary"] = summ
        save_table(summ, tdir, "01_sustainedBR_summary")
        savefig(plot_sustained_br(br, summ, name), fdir, "01_sustainedBR")
    # main
    mains = [r["main"] for r in results if "main" in r]
    if not mains:
        return pooled
    d = pd.concat(mains, ignore_index=True)
    dall = pd.concat([r["main_all"] for r in results if "main_all" in r], ignore_index=True)
    tabs = {
        "04_main_percepts_by_condition": main_condition_table(d, name),
        "04_main_cue_effects": cue_effect_table(d, name),
        "04_main_catch_trials": catch_table(dall, name),
        "04_main_sequential": sequential_table(d, name),
        "04_main_ratings": rating_table(dall, name),
    }
    pooled.update(tabs)
    for k, v in tabs.items():
        save_table(v, tdir, k)
    savefig(plot_main_percepts(d, name), fdir, "04_main_percepts")
    savefig(plot_main_dominance(d, name, subjects=subs), fdir, "05_main_dominance")
    savefig(plot_main_rt(d, name), fdir, "06_main_rt")
    savefig(plot_ratings(dall, name), fdir, "09_ratings")
    runs = pd.concat([r["04_main_runs"] for r in results if "04_main_runs" in r], ignore_index=True)
    savefig(plot_runs(runs, "all subjects"), fdir, "08_runs_timecourse")
    # stage overview: validation of the calibration used for the main runs + main
    stages, cfgs, rts = [], [], []

    def add(nm, lab, cfg, rt):
        stages.append((nm, lab)); cfgs.append((nm, lab, cfg)); rts.append((nm, rt, lab))

    vt = []
    for r in results:
        c, ct = r.get("cal"), r.get("cal_trials")
        if c is not None and len(c) and "usedForMain" in c:
            k = c.loc[c.usedForMain.fillna(False).astype(bool), "calibration"]
            if len(k):
                vt.append(ct[(ct.calibration == k.iloc[0]) & (ct.stage == "validation")])
    if vt:
        v = pd.concat(vt)
        add("validation (used calib.)", v.label.tolist(), v.eyeConfig.tolist(), v.rt.tolist())
    for task in ["report", "dual"]:
        t = d[d.task == task]
        if len(t):
            b = t[t.condition == "baseline"]
            add(f"{task} baseline", b.label.tolist(), b.eyeConfig.tolist(), b.rt.tolist())
            add(f"{task} all", t.label.tolist(), t.eyeConfig.tolist(), t.rt.tolist())
    save_table(pd.DataFrame([dict(subject=name, stage=s, **percept_summary(l)) for s, l in stages]),
               tdir, "02_stage_overview")
    savefig(plot_stage_overview(stages, name), fdir, "02_stage_overview")
    savefig(plot_eye_config(cfgs, name), fdir, "07_house_by_eye_configuration")
    savefig(plot_calib_rt(rts, name), fdir, "06b_rt_per_stage")
    return pooled


def fmt(x, nd=2):
    return "-" if x is None or (isinstance(x, float) and np.isnan(x)) else (f"{x:.{nd}f}" if isinstance(x, float) else str(x))


def write_summary(results, pooled, out, include_dual_catch):
    L = ["# PerImAt - behavioural summary", "",
         f"Generated {datetime.now():%Y-%m-%d %H:%M} by `analysis/perimat_analysis.py`. "
         f"Dual catch trials {'included' if include_dual_catch else 'excluded'}; report catch trials always excluded "
         "from percept tables (see `04_main_catch_trials.csv`). Practice trials skipped.", "",
         "Percepts: HouseL/FaceL/HouseR/FaceR = stimulus seen + eye it was shown to; noResp = no key "
         "(logged as perceived 'mixed', response 0). Stimulus dominance = P(house | house or face); "
         "eye dominance = P(left eye | house or face); p = two-sided binomial test vs 0.5.", ""]

    def pct_line(r):
        return (f"n={r['n']}: HouseL {r['HouseL']}, FaceL {r['FaceL']}, HouseR {r['HouseR']}, FaceR {r['FaceR']}, "
                f"mixed {r['mixed']}, noResp {r['noResp']}" + (f", invalid {r['invalid']}" if r.get('invalid') else "")
                + f" | house {fmt(r['pHouse'])} (p={fmt(r['pHouse_binom_p'], 3)}), "
                  f"left eye {fmt(r['pLeftEye'])} (p={fmt(r['pLeftEye_binom_p'], 3)})")

    L += ["**Notes / assumptions**", "",
          "- Sustained BR: run 1 = face left / house right, run 2 = house left / face right (as in the current "
          "`binocularRivalryTraining.m`); for subjects recorded with an older code version this mapping is assumed. "
          "Older files: no key and two keys are both logged as mixed; newer files (from 2026-11) separate 'none' (no key held) from 'mixed' (two keys). The first period (before the first key press) is mixed/none time; mean durations exclude the first and "
          "the last (cut) period.",
          "- Calibration time = first trial's mask onset to the end of the last calibration trial; validation time "
          "includes nothing before its first trial (break and fusion alignment are in 'break').",
          "- The training file used by the main runs is read from `design.mat` (`trainingFile`) when it exists, "
          "otherwise the latest `XX_training_n.mat` is assumed (what `loadLatestTrainingParameters` loads).",
          "- Pooled = trials of all subjects summed; per-subject markers are drawn in the pooled dominance plot.",
          "- RT = time from rivalry onset to the first percept key.", ""]
    for r in results:
        if not np.isnan(r.get("rivalry_s_main", np.nan)):
            L.append(f"- {r['name']}: rivalry duration in the main runs (design.mat) = {r['rivalry_s_main']:.2f} s.")
    L.append("")
    for r in results + ([dict(name="pooled", **pooled)] if pooled else []):   # no pooled section for one subject
        L += [f"## {r['name']}", ""]
        bs = r.get("br_summary")
        if bs is not None and len(bs):
            L += ["**Sustained BR** (2 × 60 s, default contrasts; time-based):", ""]
            for b in bs.itertuples():
                L.append(f"- {b.subject} run {b.run}: house {fmt(b.pHouse_time)}, left eye {fmt(b.pLeftEye_time)}, "
                         f"mixed {fmt(b.pctTime_mixed, 0)} %, no key {fmt(b.pctTime_none, 0)} % of time; HouseL {fmt(b.pctTime_HouseL, 0)} %, "
                         f"FaceL {fmt(b.pctTime_FaceL, 0)} %, HouseR {fmt(b.pctTime_HouseR, 0)} %, "
                         f"FaceR {fmt(b.pctTime_FaceR, 0)} %; {b.alternations} alternations "
                         f"({fmt(b.alternations_per_min, 1)}/min)")
            L.append("")
        tests = r.get("tests")
        if tests is not None and len(tests):
            L += ["**QUEST+ tests:**", ""]
            for t in tests.to_dict("records"):
                L.append(f"- {t['stage']} - {t['position']}, contrasts: {t['contrasts']}: {pct_line(t)}")
            L.append("")
        cal = r.get("cal")
        if cal is not None and len(cal):
            L += ["**Calibration(s):**", ""]
            for c in cal.to_dict("records"):
                L.append(f"- calibration {c['calibration']} ({c['start']}){' - USED FOR MAIN' if c.get('usedForMain') else ''}: "
                         f"{c['nTrials_calibration']} calibration trials ({c['nCalibration_houseFace']} house/face, "
                         f"{c['nCalibration_mixed']} mixed{', ' + str(c['nWarmup']) + ' warm-up' if c['nWarmup'] else ''}) "
                         f"in {fmt(c['time_calibration_min'], 1)} min; break {fmt(c['time_break_min'], 1)} min; "
                         f"{c['nTrials_validation']} validation trials in {fmt(c['time_validation_min'], 1)} min; "
                         f"total {fmt(c['time_total_min'], 1)} min. Final θS {fmt(c['final_thetaS_log2'])} ± "
                         f"{fmt(c['final_thetaS_sd'])}, θE {fmt(c['final_thetaE_log2'])} ± {fmt(c['final_thetaE_sd'])} log2.")
                if "final_texture_HouseL" in c:
                    L.append(f"  Final texture contrasts: HouseL {fmt(c['final_texture_HouseL'], 3)}, "
                             f"FaceL {fmt(c['final_texture_FaceL'], 3)}, HouseR {fmt(c['final_texture_HouseR'], 3)}, "
                             f"FaceR {fmt(c['final_texture_FaceR'], 3)} ({c['trainingFile']}; {c['stopReason']}; "
                             f"which file the main runs used: {c.get('usedForMain_source', '-')}).")
            cp = r.get("cal_percepts")
            if cp is not None:
                for c in cp.to_dict("records"):
                    L.append(f"  - calibration {c['calibration']} {c['stage']}"
                             f"{'' if c['validation'] == 'all' else ' ' + str(c['validation'])}: {pct_line(c)}")
            L.append("")
        tab = r.get("04_main_percepts_by_condition")
        if tab is not None and len(tab):
            L += ["**Main experiment** (non-catch trials):", "",
                  "| task | condition | cue | n | HouseL | FaceL | HouseR | FaceR | mixed | noResp | P(house) [95 % CI] | "
                  "P(left eye) [95 % CI] | P(cued stim.) | RT median (s) |",
                  "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
            for t in tab.to_dict("records"):
                L.append(f"| {t['task']} | {t['condition']} | {t['cue']} | {t['n']} | {t['HouseL']} | {t['FaceL']} | "
                         f"{t['HouseR']} | {t['FaceR']} | {t['mixed']} | {t['noResp']} | "
                         f"{fmt(t['pHouse'])} [{fmt(t['pHouse_ci_lo'])}, {fmt(t['pHouse_ci_hi'])}] | "
                         f"{fmt(t['pLeftEye'])} [{fmt(t['pLeftEye_ci_lo'])}, {fmt(t['pLeftEye_ci_hi'])}] | "
                         f"{fmt(t['pCongruent'])} | {fmt(t['rt_median'])} |")
            L.append("")
            ce = r.get("04_main_cue_effects")
            if ce is not None and len(ce):
                L += ["Cue effects on P(house) (Fisher exact):", ""]
                for c in ce.to_dict("records"):
                    L.append(f"- {c['task']} {c['condition']}: house cue {fmt(c['pHouse_houseCue'])} (n={c['n_houseCue']}) "
                             f"vs face cue {fmt(c['pHouse_faceCue'])} (n={c['n_faceCue']}), p={fmt(c['fisher_p_houseCue_vs_faceCue'], 3)}; "
                             f"baseline {fmt(c['pHouse_baseline'])}")
                L.append("")
            ct = r.get("04_main_catch_trials")
            if ct is not None and len(ct):
                L += ["Catch trials:", ""]
                for c in ct.to_dict("records"):
                    acc = "" if pd.isna(c["nCorrect"]) else f", correct {int(c['nCorrect'])}/{c['n']}"
                    L.append(f"- {c['task']}, {c['catchType']}: n={c['n']}{acc} ({c['reported']})")
                L.append("")
            sq = r.get("04_main_sequential")
            if sq is not None and len(sq):
                L += ["Sequential effects (consecutive house/face trials in a run):", ""]
                for c in sq.to_dict("records"):
                    L.append(f"- {c['task']}: same stimulus {fmt(c['pSameStimulus'])} (expected {fmt(c['pSameStimulus_expected'])}, "
                             f"p={fmt(c['binom_p_sameStimulus'], 3)}), same eye {fmt(c['pSameEye'])} "
                             f"(expected {fmt(c['pSameEye_expected'])}, p={fmt(c['binom_p_sameEye'], 3)}), n={c['nPairs']} pairs")
                L.append("")
    (out / "summary.md").write_text("\n".join(L))


def main():
    here = Path(__file__).resolve().parent
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=here.parent, help="project folder containing rawdata/")
    ap.add_argument("--subjects", nargs="*", help="subject numbers, e.g. 01 03 (default: all sub-* in rawdata)")
    ap.add_argument("--out", type=Path, default=None, help="output folder (default: <root>/derivatives)")
    ap.add_argument("--include-dual-catch", action="store_true",
                    help="count dual catch trials (fixation-dot catch, BR as usual) as normal trials")
    a = ap.parse_args()
    raw = a.root / "rawdata"
    out = a.out or a.root / "derivatives"
    subs = a.subjects or sorted(p.name[4:] for p in raw.glob("sub-*") if p.is_dir())
    print(f"rawdata: {raw}\noutput:  {out}\nsubjects: {', '.join(subs)}")
    results = []
    for s in subs:
        print(f"-- sub-{s}")
        results.append(analyse_subject(s, raw, out, a.include_dual_catch))
    pooled = analyse_pooled(results, out) if len(results) > 1 else {}
    # group tables: every subject + pooled in one file
    gdir = out / "group_tables"
    for key in ["br_summary", "tests", "cal", "cal_percepts", "04_main_percepts_by_condition", "04_main_cue_effects",
                "04_main_catch_trials", "04_main_runs", "04_main_sequential", "04_main_ratings"]:
        parts = [r[key] for r in results if isinstance(r.get(key), pd.DataFrame) and len(r[key])]
        if isinstance(pooled.get(key), pd.DataFrame) and key != "br_summary":
            parts.append(pooled[key])
        if key == "br_summary" and "br_summary" in pooled:
            parts.append(pooled["br_summary"][pooled["br_summary"].subject == "pooled"])
        if parts:
            save_table(pd.concat(parts, ignore_index=True), gdir, {"cal": "calibration_summary",
                                                                     "cal_percepts": "calibration_validation_percepts",
                                                                     "tests": "questplus_tests",
                                                                     "br_summary": "sustainedBR_summary"}.get(key, key))
    write_summary(results, pooled, out, a.include_dual_catch)
    print(f"done -> {out}")


if __name__ == "__main__":
    main()
