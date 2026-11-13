# PerImAt – perception, attention and imagery in onset binocular rivalry

MATLAB / Psychtoolbox experiment. On every trial a house and a face are shown, one to each eye (onset binocular
rivalry), and the first dominant percept is measured. Before the rivalry, a cued 6-s task (perceive, attend to or
imagine the house or the face, or just fixate) may bias which image wins. The percept is reported with keys (report),
read out from the eyes following fixation dots on the images (no-report), or both (dual). Before the main experiment,
the contrasts of the four rivalry textures are calibrated per subject with QUEST+, so that house/face and left/right
eye are balanced in a baseline without a task.

There are two versions: **offline** (behaviour + EyeLink, stereoscope; set-up `CIN-experimentroom`) and **fMRI**
(set-up `MPI`, shutter glasses, scanner triggers).

---

## Contents

1. [Requirements](#requirements)
2. [Repository layout](#repository-layout)
3. [Running the experiment](#running-the-experiment)
4. [Session (offline)](#session-offline)
5. [Design of the main experiment](#design-of-the-main-experiment)
6. [QUEST+ contrast calibration](#quest-contrast-calibration)
7. [Stimuli](#stimuli)
8. [Texture statistics](#texture-statistics)
9. [Data files](#data-files)
10. [Analysis](#analysis)
11. [Instructions and questionnaires](#instructions-and-questionnaires)
12. [Tests and pilot tools](#tests-and-pilot-tools)
13. [Further documentation](#further-documentation)

---

## Requirements

| What | Needed for |
|---|---|
| MATLAB | everything in `Code/` |
| [Psychtoolbox-3](http://psychtoolbox.org) | screen, keyboard queues, stereo modes |
| Image Processing Toolbox | `imresize` (textures, fusion mask), `imfill` (stimulus masks, texture statistics), `createFMRIStimuli` |
| EyeLink Developers Kit (`Eyelink` mex) | offline main runs with `useEyetracker = true` |
| VPixx DataPixx | fMRI set-up `MPI` (frame-sequential stereo) |
| Python 3 + numpy, pandas, scipy, matplotlib | `analysis/perimat_analysis.py` |
| Python 3 + playwright (Chromium), numpy, pillow | re-making the instruction figures (`stimulusPreparation/makeInstructionFigures.py`) |
| Node.js + `docx` | re-making the questionnaires (`Questionnaires/make_questionnaire.js`) |
| Octave 8 (optional) | dry runs of the calibration without Psychtoolbox (`Code/tests/`) |

---

## Repository layout

```
Code/                      experiment (run from here)
  main.m                   entry point: set-up, subject, menu
  perImAtOffline.m         main experiment, offline (+ trialProcedurePerImAtOffline.m)
  perImAtOnline.m          main experiment, fMRI   (+ trialProcedurePerImAtOnline.m)
  questPlusCalibration.m   QUEST+ calibration + validation
  questPlusTest.m          test of fixed contrasts
  binocularRivalryTraining.m, consentForm.m, presentFixDotLocations.m, keyBindingTraining.m
  fixDotPilot.m, rivalryDurationPilot.m          pilot tools (not part of the session)
  settings/                getPTBSettings (set-ups, keys), getVisualDesignSettings (geometry, textures, dots),
                           getInstructions (DE/EN texts), getKeyAssignment (counterbalancing),
                           getQuestPlusSettings, getPaths, loadLatestTrainingParameters, getParticipantInfo
  utils/                   packages: +questplus, +generate, +draw, +display, +input, +save_utils,
                           +image_stats, +eyetracking, +mri, +gamma_correct; createCatchTrialOrder.m
  tests/                   dry run of the calibration with a simulated observer (mocks for PTB)
condition/                 stimLookupTable.csv, pictograms, frame/background images
instructions/              participant slide decks (DE, EN) and figures/ (shown on screen by the code)
stimulusPreparation/       createFMRIStimuli.m (stimulus images), makeInstructionFigures.py
monitor_calibration/       EIZO measurements; gamma correction (offline)
analysis/                  perimat_analysis.py
derivatives/               analysis output (tables, figures, summary.md)
Questionnaires/            post-experiment questionnaire (DE/EN), VVIQ, generator script
CHANGES_2026-11.md         change log of November 2026
```

**Not in the repository**, but needed:

* `stimuli/` – the stimulus images (see [Stimuli](#stimuli)). Copy it next to `Code/` on every machine.
* `rawdata/` – the data, created by the experiment (`rawdata/sub-XX/`). It contains personal data and is ignored by
  git (`.gitignore`).

All paths are relative to `Code/` (`settings/getPaths.m`): `../stimuli`, `../condition`, `../rawdata`,
`../instructions/figures`, `../monitor_calibration`.

---

## Running the experiment

```matlab
cd Code
main('CIN-experimentroom')     % set-up: 'CIN-experimentroom' (default), 'CIN-personal', 'MPI', 'personal'
```

`main` asks for the subject ID, loads/asks the participant information (`getParticipantInfo`, first time only),
builds the textures from the subject's latest contrast file (`<ID>_training_<n>.mat`) and shows the menu.

Switches at the top of `main.m`:

| Variable | Default | Meaning |
|---|---|---|
| `offline` | `true` | `true` = behavioural version (`perImAtOffline`), `false` = fMRI version (`perImAtOnline`, always 10 runs) |
| `useEyetracker` | `true` | EyeLink in the main runs (switched off automatically in all other parts) |
| `dummymode` | `false` | EyeLink dummy mode |
| `debugTrigger` | `false` | fMRI version without scanner: the trigger `w` can be typed on the keyboard |

Set-ups (`settings/getPTBSettings.m`):

| Set-up | Display | Stereo | Subject keys: left / right / lower; rating 1–5 |
|---|---|---|---|
| `CIN-experimentroom` | full screen, 600 × 340 mm at 560 mm | side by side (stereoscope) | response box `4` / `8` / `0`; rating `0 4 8 9 +`; experimenter keyboard separate |
| `CIN-personal` | 1920 × 1200 window | side by side | ← / → / space; rating space ← → ↑ ↓ |
| `personal` | 2560 × 1440 window (laptop) | side by side | ← / → / space; rating space ← → ↑ ↓ |
| `MPI` | full screen, 470 × 265 mm at 1050 mm | frame-sequential, shutter glasses, DataPixx | button box `4` / `3` / `5`; no rating; scanner trigger `w` |

### Menu

| Option | What it does |
|---|---|
| consent form | fusion alignment, consent text, confirmation saved (`sub-XX_consent_<time>.mat`) |
| main experiment | next run of the next report condition (chosen automatically from the files present) |
| training | 14 practice trials (each trial type once) of a report condition, all instructions |
| present fixDot locations | fixation-dot positions on house and face, then the 7-trial dual practice |
| key binding training | house/face key training with feedback (not part of the session) |
| BR training | sustained rivalry, 2 × 60 s at default contrasts, continuous report |
| QUEST+ calibration | contrast calibration + validation, saves `<ID>_training_<n>.mat` |
| QUEST+ test | 40 house/face trials at the saved contrasts (calibration trial structure) |
| QUEST+ recover | contrasts from an interrupted calibration (checkpoint after every trial) |

If a part that shows the subject's textures (main experiment, training, fixDot locations, QUEST+ test) is chosen and
no training file exists, the experimenter is asked: Enter = continue with contrast 1.0, `m` = type the contrasts,
`a` = abort.

---

## Session (offline)

About 4 h:

1. Slides (`instructions/PerImAt – Einführung für Teilnehmende.pptx` / `… Introduction for participants.pptx`)
2. **consent form** (includes the first fusion alignment)
3. **BR training** (2 × 60 s)
4. **QUEST+ calibration** (~10–15 min incl. validation; see below)
5. **present fixDot locations** (dot demonstration + 7-trial dual practice)
6. **main experiment**: 3 report conditions × 5 runs (~8 min each), in the subject's block order
7. Questionnaires (`Questionnaires/`)

---

## Design of the main experiment

### Conditions

* **Task conditions** (cue letter on the fixation cross; the cross colour says house or face):
  `P` perception (the faint house/face, `house_low.png` / `face_low.png`, in both eyes), `A` attention (attend to the
  cued image in the superimposed house + face, `superimposed.png`), `I` imagery (imagine the cued image on a grey
  square), `x` baseline (fixate, grey square, no cue).
* **Report conditions** (blocked, 5 runs each offline):
  * `r` report – press house / face / lower key (mixture) for the first clear image;
  * `nr` no-report – no key; fixation dots on house and face, the subject fixates the dot of the image they see
    (two dots → the central cross); gaze recorded with EyeLink;
  * `du` dual – both.
* After each trial: rating 1–5, "How well did you do the task?" (offline only).

### Runs and trials

* Offline: `maxRunNr = 5` runs per report condition (15 runs); fMRI: 10 runs each for report and no-report.
* Per run: each of the 4 rows of `condition/stimLookupTable.csv` (cue × which eye gets the house) twice for perception,
  attention and imagery (8 each) and rows 1–2 twice for baseline (4) = **28 trials + 2 catch trials = 30**. The four
  task conditions are miniblocks in random order, trials random within a miniblock.
* Catch trials (`utils/createCatchTrialOrder.m`, one file per report condition and subject): 2 per run, in two
  different conditions; over all runs imagery/perception/attention/baseline = 3/3/3/1 (5 runs) or 6/6/6/2 (10 runs).
  Report: the same image in both eyes (house, face, or a house–face mixture built from the rivalry textures);
  no-report/dual: one or two dots per eye.

### Trial (offline)

| Phase | Duration |
|---|---|
| cue (letter + coloured cross; first trial of a miniblock with the colour legend) | 1 s (3 s) |
| task screen | 6 s |
| rivalry (house + face) | 3 s |
| fixation cross (percept key still counts) | 2 s |
| "1 – 5?" rating | 2 s |
| Gaussian noise mask (rating key still counts) | 2 s |

16 s per trial (18 s for the first of a miniblock), ≈ 8 min per run. Percept = first percept key from rivalry onset
until the end of the cross phase; no key = `mixed`.

**fMRI version** (`perImAtOnline`): same trial without rating screen and with a 5-s blank ITI: cue 1 (3) + task 6 +
rivalry 3 + response 2 + mask 2 + ITI 5 = 19 s (21 s); run ≈ 578 s. The run starts after `design.nDummies` dummy
triggers (5 at the MPI); `scanStart` is saved with every trial. TR (1.75 s) and volume count are preliminary.
Instructions are text screens (no figures).

### Counterbalancing (`settings/getKeyAssignment.m`)

With i = subject ID − 1:

* house key: left if `mod(floor(i/2), 2) == 0`, else right;
* house cue colour: red if `mod(i + floor(i/12), 2) == 0`, else teal (the face gets the other one);
* order of the report conditions: offline `mod(i, 6) + 1` of the 6 permutations, fMRI `mod(floor(i/4), 2) + 1`.

Offline, all 24 order × key × colour combinations occur once per 24 subjects (fMRI: all 8 per 8 subjects).
The start-up line prints keys, colours and block order.

---

## QUEST+ contrast calibration

Per-subject calibration of the house/face and left/right-eye contrasts for onset rivalry (options "QUEST+
calibration", "QUEST+ test" and "QUEST+ recover"). Texture contrast = stimulus factor (house/face) × eye factor
(left/right).

* Model: P(house) = λ/2 + (1−λ)/(1 + exp(−β(x − θS − h·θE))), x = log2 ratio of the house and face texture shown,
  h = ±1 for the eye configuration; grid posterior over θS, θE, slope β and lapse λ.
* Trial: noise mask 2 s → cross 1 s → rivalry 3 s → answer at the latest 2 s after the rivalry (missed / mixed
  trials are repeated). Eye configuration in shuffled blocks of 4; contrast ratio chosen by minimum expected entropy.
* Stop: posterior SD of both balance points ≤ 0.15 log2, at least 80 house/face trials, at most 150 trials.
  Then 40-trial validation(s) at fixed contrasts with binomial tests; the experimenter decides (Enter / `v` / `r` /
  `s`) and chooses the contrasts to save. A checkpoint is written after every trial.

Documentation: [`Code/utils/+questplus/README.md`](Code/utils/+questplus/README.md),
settings: [`Code/settings/getQuestPlusSettings.m`](Code/settings/getQuestPlusSettings.m).
Dry run without screen (simulated observer, MATLAB or Octave): [`Code/tests/README.md`](Code/tests/README.md).

---

## Stimuli

Expected in `stimuli/` (next to `Code/`):

| File | Used for |
|---|---|
| `house.png`, `face.png` | rivalry textures (contrast-adjusted per subject and eye, with fixation dots) |
| `house_low.png`, `face_low.png` | perception task screen |
| `superimposed.png` | attention task screen |
| `grey_square.png` | imagery / baseline task screen |
| `catch_houseface.png`, `catch_facehouse.png` (+ `_weights.png`) | report catch trials (rebuilt from the subject's rivalry textures with the weight maps; without them one contrast is used for the whole image, with a warning) |

The images are made with `stimulusPreparation/createFMRIStimuli.m` (mean luminance and RMS contrast matched on the
region visible through the frame aperture; catch images and weight maps; see the header of the script and
`CHANGES_2026-11.md` §1). `getVisualDesignSettings` writes debug copies of the textures to `stimuli/debugImages/`.

Textures are shown on a pink-noise background inside a circular aperture with a black frame (3° stimulus). Contrasts
are applied around the mean of the visible stimulus content (`design.contrastReference = 'visible'`; calibrations
made before 2026-11-10 used `'image'`, a warning appears if they are mixed). Gamma correction (offline only) uses
`monitor_calibration/EIZO_CIN5th_Brightness50_SpectraScan670_derived.mat`.

Fixation dots (no-report/dual): 6 positions, Gaussian dot (σ 0.05°, "big dot"), luminance step set from the local
image under the dot (`design.fixDotContrastMode = 'local'`, Weber 0.33); settings in `getVisualDesignSettings.m`.

---

## Texture statistics

At every start, `getVisualDesignSettings` compares the house and face textures that are shown together
(HouseL vs FaceR, HouseR vs FaceL, at the subject's contrasts) with `image_stats.textureStats`: fraction of
the aperture covered, RMS contrast of the stimulus and of the aperture, mean grey level, local RMS contrast, contrast
per spatial-frequency band and orientation. The result is printed and saved as `design.textureStats` in
`design.mat` (written when `main` ends and overwritten at every start). Needs the Image Processing Toolbox; without
it only a warning is printed. For the full analysis with plots (from `Code/`):

```matlab
image_stats.compareStimulusStats('../stimuli/house.png', '../stimuli/face.png')
```

---

## Data files

Everything goes to `rawdata/sub-XX/` (XX = subject ID; `<time>` = `yyyy-MM-dd_HHmmss`):

| File | Content |
|---|---|
| `participantInfo.mat` | language, handedness, dominant eye, age, gender, colour vision, vision correction, eye conditions, fusion offsets |
| `sub-XX_consent_<time>.mat` | consent confirmation |
| `sub-XX_BRtraining_run-1.csv`, `run-2.csv` | sustained rivalry: percepts, onsets, durations |
| `sub-XX_questplus_<time>.csv/.mat` | calibration trials and results; `sub-XX_questplusCheckpoint_<time>.mat` |
| `XX_training_<n>.mat` | saved contrasts (the latest one is used by all later parts) |
| `sub-XX_questplus-test_<time>.csv/.mat` | QUEST+ test |
| `sub-XX_practice_du_<time>.csv`, `sub-XX_train_<r|nr|du>_<time>.csv` | practice / training runs |
| `sub-XX_run-NN_<r|nr|du>_<time>.csv` | main runs: one row per trial (condition, cue, images per eye, catch, percept, RT, rating, dot positions, onsets, contrasts used) |
| `catchTrialOrderR.csv`, `catchTrialOrderNR.csv`, `catchTrialOrderDual.csv` | catch-trial plan of the subject |
| `log_run-<n>_<cond>_<time>.mat`, `design.mat`, `ptb.mat` | full log, design (incl. texture statistics) and Psychtoolbox settings |
| `vXXrNN<r|nr|du>.edf` | EyeLink data of the main runs |

---

## Analysis

```bash
python analysis/perimat_analysis.py                    # all subjects in rawdata/
python analysis/perimat_analysis.py --subjects 01 03
python analysis/perimat_analysis.py --include-dual-catch
```

Writes `derivatives/sub-XX/` and `derivatives/pooled/` (tables, figures), `derivatives/group_tables/` and
`derivatives/summary.md`: sustained BR, QUEST+ calibrations and tests, percepts per condition and cue (HouseL / FaceL /
HouseR / FaceR / mixed / no response), P(house), P(left eye), cue effects, RTs, ratings, catch trials, run time course,
sequential effects. Details in the header of the script.

---

## Instructions and questionnaires

* On-screen texts: `Code/settings/getInstructions.m` (German *du*, English), chosen from `participantInfo.language`.
* Task figures shown on screen: `instructions/figures/` (per report condition, language, key mapping and cue colour;
  run 1 of a block in four steps). Re-make with
  `python3 stimulusPreparation/makeInstructionFigures.py condition instructions/figures`.
  If a figure is missing, the text screens are shown instead.
* Participant slides: `instructions/*.pptx`.
* Questionnaires: `Questionnaires/Questionnaire_BR_deutsch_2026-11-11.docx`, `…_en_2026-11-11.docx` (generated by
  `node make_questionnaire.js <outdir>`), `VVIQ.docx`.

---

## Tests and pilot tools

* `Code/tests/dryRunCalibration.m` – calibration and QUEST+ test end to end with a simulated observer, no screen
  needed (MATLAB or Octave): see [`Code/tests/README.md`](Code/tests/README.md).
* `Code/fixDotPilot.m` – viewer and yes/no detection test for the fixation dots.
* `Code/rivalryDurationPilot.m` – how long the rivalry must last until a dot is clearly seen.

---

## Further documentation

* [`CHANGES_2026-11.md`](CHANGES_2026-11.md) – all changes of November 2026 with reasons
* [`Code/utils/+questplus/README.md`](Code/utils/+questplus/README.md) – calibration procedure in detail
* [`Code/tests/README.md`](Code/tests/README.md) – dry runs
