"""Instruction figures for PerImAt, German + English.

usage: python3 makeInstructionFigures.py <pictogram dir> <out dir>
   e.g. python3 makeInstructionFigures.py ../condition ../instructions/figures
needs: pip install playwright numpy pillow && playwright install chromium
[added 2026-11-10; v5 2026-11-11: on-screen figures with min. font 22 px (shown 20 % smaller); v4 2026-11-10: shown in steps, "fixate the dot", no sub-header,
 parts separated in the overview, figures for the BR training and the calibration]

Writes (lang = de | en)
  block_<cond>_<lang>_house<L|R>_house<Red|Teal>[_step1|_step2|_step3].png
      cond = report | noReport | dual; shown on screen (subject's keys and cue colours).
      step1 = screens, step2 = + eyes, step3 = + keys, no suffix = complete (+ colours, P/A/I/x)
  brtraining_<lang>_house<L|R>.png, calibration_<lang>_house<L|R>.png   - shown on screen
  slides_<report|noReport|dual|all|brtraining|calibration>_<lang>.png    - for the slides:
      no colour-image or key assignment (both colours and both images shown)
"""
import base64, io, sys, pathlib, html
import numpy as np
from PIL import Image
from playwright.sync_api import sync_playwright

PICT = pathlib.Path(sys.argv[1])
OUT = pathlib.Path(sys.argv[2]); OUT.mkdir(parents=True, exist_ok=True)

def b64(p):
    return "data:image/png;base64," + base64.b64encode(p.read_bytes()).decode()
HOUSE = b64(PICT / "house_pictogram.png")
FACE = b64(PICT / "face_pictogram.png")

def noise_png(n=32, seed=7):
    """as generate.createStereoGaussianNoiseTextures: mean 128, SD 30, clipped, one value per
    4-px element (~32 x 32 over the stimulus); shown enlarged, pixelated"""
    rng = np.random.default_rng(seed)
    a = np.clip(128 + 30 * rng.standard_normal((n, n)), 0, 255).astype(np.uint8)
    buf = io.BytesIO(); Image.fromarray(a, "L").save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()
NOISE = noise_png()

BG = "#808080"; SCREEN = "#9b9b9b"; BAND = "#8b8b8b"; CELL = "#d9d9d9"; STRONG = "#ffffff"
INK = "#000000"; QUIET = "#262626"
RED = "rgb(217,13,13)"      # design.conditionColors(1,:)
TEAL = "rgb(0,115,140)"     # design.conditionColors(2,:)
FONT = "DejaVu Sans, Arial, sans-serif"

T = {
 "de": dict(
   title={"report": "Tasten-Teil", "noReport": "Punkt-Teil", "dual": "Tasten + Punkt",
          "all": "Drei Teile: was du wann tust", "brtraining": "Binokulare Rivalität",
          "calibration": "Onset-Rivalität"},
   ph={"cue": "Hinweis", "task": "Aufgabe", "rivalry": "Rivalität", "cross": "Kreuz", "rating": "Bewertung",
       "noise": "Rauschen", "blank": "Kreuz", "answer": "Antwort"},
   task_end="endet mit der Rivalität",
   eyes="Augen", keys="Tasten",
   cross="Kreuz", cross_all="auf das Kreuz, die ganze Zeit",
   dot1="Punkt fixieren", dot2="2 Punkte: Kreuz", then_cross="danach Kreuz",
   none="keine Taste", none_strong="KEINE Taste",
   percept_when="erstes deutliches Bild", answer_note="spätestens 2 s nach der Rivalität",
   house="Haus", face="Gesicht", mixed="Mischung",
   left="links", right="rechts", lower="unten",
   rating=["Wie gut hast du die", "Aufgabe gemacht?"], rating3="1 nicht gut … 5 sehr gut",
   tasks=[("P", "das blasse Bild wahrnehmen"), ("A", "auf das Bild der Farbe achten"),
          ("I", "Bild der Farbe vorstellen"), ("x", "nur auf das Kreuz schauen (schwarzes Kreuz)")],
   colour="Farbe des Kreuzes:", or_="oder",
   colour_neutral="Eine Farbe steht für das Haus, die andere für das Gesicht.",
   colour_neutral2="Welche Farbe welches Bild ist und welche Taste Haus und welche Gesicht ist, zeigt dir der Bildschirm.",
   row_lines={"report": ("Tasten-", "Teil"), "noReport": ("Punkt-", "Teil"), "dual": ("Tasten +", "Punkt")},
   all_parts="in allen Teilen",
   dots_note="Punkte nur im Punkt-Teil und bei Tasten + Punkt",
   br_seen="Was du siehst:", br_hold="halten", br_time="Zeit",
   br_rule="Halte die Taste, solange du das Bild deutlich siehst. Wechselt das Bild, wechsle die Taste.",
   br_eyes="Augen: die ganze Zeit auf das Kreuz",
 ),
 "en": dict(
   title={"report": "Keys part", "noReport": "Dot part", "dual": "Keys + dot part",
          "all": "Three parts: what to do when", "brtraining": "Binocular rivalry",
          "calibration": "Onset rivalry"},
   ph={"cue": "Cue", "task": "Task", "rivalry": "Rivalry", "cross": "Cross", "rating": "Rating",
       "noise": "Noise", "blank": "Cross", "answer": "Answer"},
   task_end="ends with the rivalry",
   eyes="Eyes", keys="Keys",
   cross="cross", cross_all="on the cross, the whole time",
   dot1="fixate the dot", dot2="2 dots: cross", then_cross="then cross",
   none="no key", none_strong="NO key",
   percept_when="first clear image", answer_note="at the latest 2 s after the rivalry",
   house="house", face="face", mixed="mixture",
   left="left", right="right", lower="lower",
   rating=["How well did you", "do the task?"], rating3="1 not well … 5 very well",
   tasks=[("P", "perceive the faint image"), ("A", "attend to the image of the colour"),
          ("I", "imagine the image of the colour"), ("x", "just look at the cross (black cross)")],
   colour="Colour of the cross:", or_="or",
   colour_neutral="One colour stands for the house, the other for the face.",
   colour_neutral2="Which colour is which image, and which key is house and which is face, is shown on the screen.",
   row_lines={"report": ("Keys", "part"), "noReport": ("Dot", "part"), "dual": ("Keys +", "dot part")},
   all_parts="in all parts",
   dots_note="dots only in the dot part and the keys + dot part",
   br_seen="What you see:", br_hold="hold", br_time="time",
   br_rule="Hold the key as long as you see the image clearly. When the image changes, switch the key.",
   br_eyes="Eyes: on the cross the whole time",
 ),
}
DUR = {"cue": "1 s", "task": "6 s", "rivalry": "3 s", "cross": "2 s", "rating": "2 s", "noise": "2 s",
       "blank": "1 s", "answer": "≤ 2 s"}
esc = html.escape

# [added 2026-11-11] smallest font (figure px) of the figures shown ON SCREEN: they are shown
# 20 % smaller (display.stereo.figureInstruction: 76 % of the eye buffer width, was 95 %), so
# 22 px -> ~13 screen px, the size of the smallest text before (17 px x 0.76). The slides_*
# figures keep their original sizes (SCREEN_MIN_FONT is 0 while they are built).
SCREEN_MIN_FONT = 22
MIN_FONT = 0

def text(x, y, s, size=30, weight=400, anchor="start", fill=INK, italic=False):
    size = max(size, MIN_FONT)
    st = ' font-style="italic"' if italic else ""
    return (f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" text-anchor="{anchor}" '
            f'fill="{fill}" font-family="{FONT}"{st}>{esc(s)}</text>')

def cross(cx, cy, size=26, color=INK, width=4):
    h = size / 2
    return f'<path d="M{cx-h} {cy}H{cx+h}M{cx} {cy-h}V{cy+h}" stroke="{color}" stroke-width="{width}"/>'

def pict(href, x, y, s, opacity=1.0, pixelated=False):
    st = ' style="image-rendering:pixelated"' if pixelated else ""
    return f'<image href="{href}" x="{x}" y="{y}" width="{s}" height="{s}" opacity="{opacity}" preserveAspectRatio="none"{st}/>'

def rect(x, y, w, h, fill, stroke=INK, sw=2, rx=10):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'

def dot(cx, cy, r=8):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#ffffff" stroke="#3a3a3a" stroke-width="2"/>'

def arrow(x1, y, x2):
    return (f'<path d="M{x1} {y}H{x2-10}" stroke="{INK}" stroke-width="3"/>'
            f'<path d="M{x2-12} {y-8}L{x2} {y}L{x2-12} {y+8}z" fill="{INK}"/>')

def keycap(x, y, label, sub, w=136, h=70):
    out = rect(x, y, w, h, "#e6e6e6", INK, 2.5, 12)
    out += text(x + w / 2, y + (31 if sub else 44), label, 23 if len(label) > 6 else 26, 700, "middle")
    if sub:
        out += text(x + w / 2, y + 58, sub, 19, 400, "middle", QUIET)
    return out

def eye_icon(cx, cy, s=1.0):
    w, h = 30 * s, 14 * s
    return (f'<path d="M{cx-w} {cy}Q{cx} {cy-2*h} {cx+w} {cy}Q{cx} {cy+2*h} {cx-w} {cy}z" fill="none" '
            f'stroke="{INK}" stroke-width="3"/><circle cx="{cx}" cy="{cy}" r="{8*s}" fill="{INK}"/>')

def key_icon(cx, cy, s=1.0):
    return (f'<rect x="{cx-24*s}" y="{cy-18*s}" width="{48*s}" height="{36*s}" rx="8" fill="#e6e6e6" stroke="{INK}" '
            f'stroke-width="3"/><rect x="{cx-13*s}" y="{cy-7*s}" width="{26*s}" height="{6*s}" rx="3" fill="{INK}"/>')

def key_labels(L, house_left, neutral):
    if neutral:
        return [(L["house"], ""), (L["face"], ""), (L["mixed"], L["lower"])]
    if house_left:
        return [(L["house"], L["left"]), (L["face"], L["right"]), (L["mixed"], L["lower"])]
    return [(L["face"], L["left"]), (L["house"], L["right"]), (L["mixed"], L["lower"])]

class Grid:
    """one column per screen, starting at x0"""
    def __init__(self, widths, x0=200, gap=16):
        self.cw = widths; self.cx = []
        x = x0
        for w in widths:
            self.cx.append(x); x += w + gap
    def col(self, i): return self.cx[i], self.cx[i] + self.cw[i]
    def span(self, i, j): return self.cx[i], self.cx[j] + self.cw[j]
    def mid(self, i): return self.cx[i] + self.cw[i] / 2

PY, PH = 150, 220            # screens (titles at 106 / 136)
TOP = 76                     # column bands start

def screens(L, g, kinds, cue, dots):
    o = []
    cy = PY + PH / 2
    for i, k in enumerate(kinds):
        x, w = g.cx[i], g.cw[i]
        o.append(text(x + w / 2, 106, L["ph"][k], 27, 700, "middle"))
        o.append(text(x + w / 2, 136, DUR[k], 23, 400, "middle", QUIET))
        if i < len(kinds) - 1:
            o.append(arrow(x + w + 1, cy, g.cx[i + 1] - 1))
        o.append(rect(x, PY, w, PH, SCREEN))
        m = g.mid(i)
        if k == "cue":
            o.append(text(m, cy - 28, "I", 38, 700, "middle"))
            if cue is None:
                o.append(cross(m - 50, cy + 20, 30, RED, 6)); o.append(cross(m + 50, cy + 20, 30, TEAL, 6))
                o.append(text(m, cy + 28, L["or_"], 18, 400, "middle", QUIET))
            else:
                o.append(cross(m, cy + 16, 34, cue, 6))
        elif k == "task":
            mm, s = 100, 92
            gx, gy = x + 14, PY + 8
            cells = [(gx, gy), (gx + mm + 12, gy), (gx, gy + mm + 4), (gx + mm + 12, gy + mm + 4)]
            for (xx, yy), (letter, _) in zip(cells, L["tasks"]):
                o.append(f'<rect x="{xx}" y="{yy}" width="{mm}" height="{mm}" rx="6" fill="#8c8c8c"/>')
                if letter == "P":
                    o.append(pict(HOUSE, xx + 8, yy + 8, s - 8, 0.28))
                elif letter == "A":
                    o.append(pict(HOUSE, xx + 8, yy + 8, s - 8, 0.55)); o.append(pict(FACE, xx + 8, yy + 8, s - 8, 0.55))
                elif letter == "I":
                    o.append(f'<rect x="{xx+12}" y="{yy+12}" width="{mm-24}" height="{mm-24}" fill="#a8a8a8" stroke="{INK}" stroke-width="2" stroke-dasharray="6 5"/>')
                    o.append(pict(HOUSE, xx + 20, yy + 20, mm - 40, 0.22))
                o.append(cross(xx + mm / 2, yy + mm / 2, 16, INK, 3))
                o.append(rect(xx - 4, yy - 4, 30, 30, "#ffffff", INK, 1.5, 6))
                o.append(text(xx + 11, yy + 18, letter, 21, 700, "middle"))
        elif k == "rivalry":
            mm = 124
            lx, rx, yy = x + (w - 2 * mm) / 3, x + w - (w - 2 * mm) / 3 - mm, cy - mm / 2
            for xx, href, d in ((lx, HOUSE, (0.30, 0.34)), (rx, FACE, (0.66, 0.70))):
                o.append(f'<rect x="{xx}" y="{yy}" width="{mm}" height="{mm}" rx="6" fill="#8c8c8c"/>')
                o.append(pict(href, xx + 8, yy + 8, mm - 16, 0.95))
                o.append(cross(xx + mm / 2, yy + mm / 2, 16, INK, 3))
                if dots:
                    o.append(dot(xx + d[0] * mm, yy + d[1] * mm))
        elif k in ("cross", "blank", "answer"):
            o.append(cross(m, cy, 30, INK, 5))
        elif k == "rating":
            o.append(text(m, cy + 13, "1 – 5?", 36, 700, "middle"))
        elif k == "noise":
            ns = 128
            o.append(pict(NOISE, m - ns / 2, cy - ns / 2, ns, 1, pixelated=True))
            o.append(cross(m, cy, 16, INK, 3))
    return o

def bands(g, y1):
    return [f'<rect x="{g.cx[i]-6}" y="{TOP}" width="{g.cw[i]+12}" height="{y1-TOP}" rx="14" fill="{BAND}"/>'
            for i in range(len(g.cw))]

def cell(x1, x2, y, h, strong=False):
    return rect(x1, y, x2 - x1, h, STRONG if strong else CELL, INK, 3 if strong else 1.5, 14)

def keycaps(L, x1, x2, y, house_left, neutral):
    kw, g = 136, 10
    kx = x1 + (x2 - x1 - (3 * kw + 2 * g)) / 2
    return [keycap(kx + i * (kw + g), y, a, b, kw) for i, (a, b) in enumerate(key_labels(L, house_left, neutral))]

def rating_cell(L, x1, x2, y, h, icon=False):
    o = [cell(x1, x2, y, h, strong=True)]
    m = (x1 + x2) / 2
    y1 = y
    if icon:
        o.append(key_icon(m, y + 40)); y1 = y + 50
    o.append(text(m, y1 + 38, "1 – 5", 32, 700, "middle"))
    o.append(text(m, y1 + 68, L["rating"][0], 21, 400, "middle"))
    o.append(text(m, y1 + 94, L["rating"][1], 21, 400, "middle"))
    o.append(text(m, y1 + 120, L["rating3"], 18, 400, "middle", QUIET))
    return o

def row_label(icon, label, y, h):
    return [icon(70 + 40, y + h / 2 - 12), text(70 + 40, y + h - 10, label, 22, 700, "middle")]

def legend(L, y, house_col, face_col, neutral):
    o = []
    if neutral:
        o.append(text(70, y, L["colour"], 27, 700))
        x = 400
        o.append(cross(x, y - 9, 30, RED, 6)); o.append(cross(x + 50, y - 9, 30, TEAL, 6))
        o.append(pict(HOUSE, x + 110, y - 40, 62)); o.append(pict(FACE, x + 180, y - 40, 62))
        o.append(text(x + 270, y, L["colour_neutral"], 24, 400))
        o.append(text(70, y + 44, L["colour_neutral2"], 22, 400, "start", QUIET, italic=True))
        ty = y + 104
    else:
        o.append(text(70, y, L["colour"], 27, 700))
        x = 400
        for c, href in ((house_col, HOUSE), (face_col, FACE)):
            o.append(cross(x, y - 9, 30, c, 6)); o.append(arrow(x + 24, y - 9, x + 74))
            o.append(pict(href, x + 82, y - 40, 62)); x += 220
        ty = y + 70
    for i, (letter, what) in enumerate(L["tasks"]):
        c, r = i % 2, i // 2
        xx, yy = 70 + c * 730, ty + r * 40
        o.append(text(xx, yy, letter, 26, 700)); o.append(text(xx + 34, yy, what, 25))
    return o, ty + 40

def svg_doc(w, h, title, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f'<rect width="{w}" height="{h}" fill="{BG}"/>{text(70, 56, title, 46, 700)}{"".join(body)}</svg>')

MAIN = ["cue", "task", "rivalry", "cross", "rating", "noise"]
GM = Grid([176, 240, 284, 176, 176, 176])

def block_figure(lang, block, house_left, house_red, neutral=False, step=4):
    """step 1: screens, 2: + eyes, 3: + keys, 4: + colours and P/A/I/x (complete)"""
    L = T[lang]
    g = GM
    house_col, face_col = (RED, TEAL) if house_red else (TEAL, RED)
    cue = None if neutral else house_col
    ey, eh = 424, 84
    ky, kh = ey + eh + 18, 140
    bottom = {1: PY + PH + 44, 2: ey + eh + 14, 3: ky + kh + 14, 4: ky + kh + 14}[step]
    body = bands(g, bottom)
    body += screens(L, g, MAIN, cue, block in ("noReport", "dual"))
    body.append(text(g.mid(1), PY + PH + 28, L["task_end"], 20, 400, "middle", INK, italic=True))
    if step >= 2:
        body += row_label(eye_icon, L["eyes"], ey, eh)
        if block == "report":
            x1, x2 = g.span(0, 5)
            body.append(cell(x1, x2, ey, eh)); body.append(text((x1 + x2) / 2, ey + eh / 2 + 9, L["cross_all"], 26, 400, "middle"))
        else:
            for a, b in ((0, 1), (3, 5)):
                x1, x2 = g.span(a, b)
                body.append(cell(x1, x2, ey, eh)); body.append(text((x1 + x2) / 2, ey + eh / 2 + 9, L["cross"], 26, 400, "middle"))
            x1, x2 = g.col(2)
            body.append(cell(x1, x2, ey, eh, strong=True))
            body.append(text((x1 + x2) / 2, ey + 34, L["dot1"], 24, 700, "middle"))
            body.append(text((x1 + x2) / 2, ey + 64, L["dot2"], 21, 400, "middle"))
    if step >= 3:
        body += row_label(key_icon, L["keys"], ky, kh)
        x1, x2 = g.span(0, 1)
        body.append(cell(x1, x2, ky, kh)); body.append(text((x1 + x2) / 2, ky + kh / 2 + 9, L["none"], 26, 400, "middle"))
        x1, x2 = g.span(2, 3)
        body.append(cell(x1, x2, ky, kh, strong=True))
        if block == "noReport":
            body.append(text((x1 + x2) / 2, ky + kh / 2 + 12, L["none_strong"], 34, 700, "middle"))
        else:
            body += keycaps(L, x1, x2, ky + 14, house_left, neutral)
            body.append(text((x1 + x2) / 2, ky + kh - 22, L["percept_when"], 22, 700, "middle"))
        x1, x2 = g.span(4, 5)
        body += rating_cell(L, x1, x2, ky, kh)
    leg, end = legend(L, ky + kh + 14 + 64, house_col, face_col, neutral)
    if step >= 4:
        body += leg
    return svg_doc(1600, end + 20, L["title"][block], body), 1600, end + 20

def all_figure(lang):
    L = T[lang]
    g = GM
    y0 = 424
    rows = ["report", "noReport", "dual"]
    rh, rg = 150, 22
    tall = 3 * rh + 2 * rg
    bottom = y0 + tall + 14
    body = bands(g, bottom)
    # part bands: label column + the two middle columns, alternately shaded, a rule between parts
    for j in range(3):
        y = y0 + j * (rh + rg)
        fill = "#9a9a9a" if j % 2 == 0 else "#878787"
        body.append(f'<rect x="58" y="{y-8}" width="{200-58-14}" height="{rh+16}" rx="12" fill="{fill}"/>')
        x1, x2 = g.span(2, 3)
        body.append(f'<rect x="{x1-12}" y="{y-8}" width="{x2-x1+24}" height="{rh+16}" rx="12" fill="{fill}" stroke="{INK}" stroke-width="1.5"/>')
    body += screens(L, g, MAIN, None, True)
    body.append(text(g.mid(1), PY + PH + 28, L["task_end"], 20, 400, "middle", INK, italic=True))
    body.append(text((g.cx[2] + g.cx[3] + g.cw[3]) / 2, PY + PH + 28, L["dots_note"], 18, 400, "middle", INK, italic=True))
    x1, x2 = g.span(0, 1)
    m = (x1 + x2) / 2
    body.append(cell(x1, x2, y0, tall))
    body.append(eye_icon(m, y0 + 70)); body.append(text(m, y0 + 122, L["cross"], 26, 400, "middle"))
    body.append(key_icon(m, y0 + 220)); body.append(text(m, y0 + 272, L["none"], 26, 400, "middle"))
    body.append(text(m, y0 + tall - 22, L["all_parts"], 20, 400, "middle", QUIET, italic=True))
    x1, x2 = g.span(4, 5)
    body += rating_cell(L, x1, x2, y0, tall, icon=True)
    body.append(text((x1 + x2) / 2, y0 + 300, L["eyes"] + ": " + L["cross"], 22, 400, "middle"))
    body.append(text((x1 + x2) / 2, y0 + tall - 22, L["all_parts"], 20, 400, "middle", QUIET, italic=True))
    sh = (rh - 8) / 2
    x1, x2 = g.span(2, 3)
    for j, b in enumerate(rows):
        y = y0 + j * (rh + rg)
        l1, l2 = L["row_lines"][b]
        body.append(text(70, y + 62, l1, 22, 700)); body.append(text(70, y + 90, l2, 22, 700))
        dots = b != "report"
        body.append(cell(x1, x2, y, sh, strong=dots))
        body.append(eye_icon(x1 + 34, y + sh / 2, 0.6))
        if dots:
            body.append(text(x1 + 68, y + 30, f'{L["dot1"]}, {L["then_cross"]}', 19, 700))
            body.append(text(x1 + 68, y + 56, L["dot2"], 17, 400))
        else:
            body.append(text(x1 + 68, y + sh / 2 + 8, L["cross"], 22, 400))
        ky = y + sh + 8
        body.append(cell(x1, x2, ky, sh, strong=True))
        body.append(key_icon(x1 + 34, ky + sh / 2, 0.8))
        if b == "noReport":
            body.append(text(x1 + 68, ky + sh / 2 + 10, L["none_strong"], 28, 700))
        else:
            body.append(text(x1 + 68, ky + 30, f'{L["house"]} / {L["face"]} / {L["mixed"]}', 20, 700))
            body.append(text(x1 + 68, ky + 56, L["percept_when"], 18, 400))
    leg, end = legend(L, bottom + 64, None, None, True)
    body += leg
    return svg_doc(1600, end + 20, L["title"]["all"], body), 1600, end + 20

def calibration_figure(lang, house_left, neutral=False):
    L = T[lang]
    g = Grid([200, 200, 300, 220])
    kinds = ["noise", "blank", "rivalry", "answer"]
    ey, eh = 424, 84
    ky, kh = ey + eh + 18, 164
    bottom = ky + kh + 14
    body = bands(g, bottom) + screens(L, g, kinds, None, False)
    body += row_label(eye_icon, L["eyes"], ey, eh)
    x1, x2 = g.span(0, 3)
    body.append(cell(x1, x2, ey, eh)); body.append(text((x1 + x2) / 2, ey + eh / 2 + 9, L["cross_all"], 26, 400, "middle"))
    body += row_label(key_icon, L["keys"], ky, kh)
    x1, x2 = g.span(0, 1)
    body.append(cell(x1, x2, ky, kh)); body.append(text((x1 + x2) / 2, ky + kh / 2 + 9, L["none"], 26, 400, "middle"))
    x1, x2 = g.span(2, 3)
    body.append(cell(x1, x2, ky, kh, strong=True))
    body += keycaps(L, x1, x2, ky + 14, house_left, neutral)
    body.append(text((x1 + x2) / 2, ky + kh - 46, L["percept_when"], 22, 700, "middle"))
    body.append(text((x1 + x2) / 2, ky + kh - 18, L["answer_note"], 19, 400, "middle"))
    w = g.cx[-1] + g.cw[-1] + 70
    return svg_doc(w, bottom + 30, L["title"]["calibration"], body), w, bottom + 30

def brtraining_figure(lang, house_left, neutral=False):
    L = T[lang]
    o = []
    # left: the screen (one image per eye, cross)
    sx, sy, sw, sh = 70, 110, 330, 230
    o.append(rect(sx, sy, sw, sh, SCREEN))
    mm = 124
    for i, href in enumerate((HOUSE, FACE)):
        xx = sx + (sw - 2 * mm) / 3 + i * (mm + (sw - 2 * mm) / 3)
        yy = sy + (sh - mm) / 2
        o.append(f'<rect x="{xx}" y="{yy}" width="{mm}" height="{mm}" rx="6" fill="#8c8c8c"/>')
        o.append(pict(href, xx + 8, yy + 8, mm - 16, 0.95)); o.append(cross(xx + mm / 2, yy + mm / 2, 16, INK, 3))
    o.append(text(sx + sw / 2, sy + sh + 34, "2 × 60 s", 24, 700, "middle"))
    # right: what you see over time and the key you hold
    labs = {lab: sub for lab, sub in key_labels(L, house_left, neutral)}
    segs = [("house", 300), ("mixed", 170), ("face", 300), ("house", 210)]
    x0, y_img, y_bar, y_key = 470, 150, 290, 380
    o.append(text(x0, 120, L["br_seen"], 24, 700))
    x = x0
    for k, w in segs:
        fill = {"house": "#e8e8e8", "face": "#bcbcbc", "mixed": "#d2d2d2"}[k]
        o.append(rect(x, y_bar, w - 6, 34, fill, INK, 1.5, 8))
        cxm = x + (w - 6) / 2
        if k == "mixed":
            o.append(f'<defs><clipPath id="cl{x}"><rect x="{cxm-55}" y="{y_img}" width="55" height="110"/></clipPath>'
                     f'<clipPath id="cr{x}"><rect x="{cxm}" y="{y_img}" width="55" height="110"/></clipPath></defs>')
            o.append(f'<g clip-path="url(#cl{x})">{pict(HOUSE, cxm - 55, y_img, 110)}</g>')
            o.append(f'<g clip-path="url(#cr{x})">{pict(FACE, cxm - 55, y_img, 110)}</g>')
        else:
            o.append(pict(HOUSE if k == "house" else FACE, cxm - 55, y_img, 110))
        name = L[k]
        o.append(keycap(cxm - 68, y_key, name, labs[name], 136, 70))
        o.append(text(cxm, y_key + 100, L["br_hold"], 21, 400, "middle", QUIET, italic=True))
        x += w
    o.append(arrow(x0, y_bar + 54, x + 20)); o.append(text(x + 28, y_bar + 61, L["br_time"], 20, 400, "start", QUIET))
    r1, r2 = L["br_rule"].split(". ", 1)
    o.append(text(470, 530, r1 + ".", 24, 700)); o.append(text(470, 564, r2, 24, 700))
    o.append(text(470, 604, L["br_eyes"], 24, 400))
    return svg_doc(1600, 640, L["title"]["brtraining"], o), 1600, 640

jobs = []
for lang in ("de", "en"):
    for block in ("report", "noReport", "dual"):
        for hl in (True, False):
            for hr in (True, False):
                base = f"block_{block}_{lang}_house{'L' if hl else 'R'}_house{'Red' if hr else 'Teal'}"
                for st in (1, 2, 3, 4):
                    MIN_FONT = SCREEN_MIN_FONT; jobs.append((base + ("" if st == 4 else f"_step{st}"), *block_figure(lang, block, hl, hr, step=st))); MIN_FONT = 0
        jobs.append((f"slides_{block}_{lang}", *block_figure(lang, block, True, True, neutral=True)))
    jobs.append((f"slides_all_{lang}", *all_figure(lang)))
    for hl in (True, False):
        MIN_FONT = SCREEN_MIN_FONT; jobs.append((f"brtraining_{lang}_house{'L' if hl else 'R'}", *brtraining_figure(lang, hl))); MIN_FONT = 0
        MIN_FONT = SCREEN_MIN_FONT; jobs.append((f"calibration_{lang}_house{'L' if hl else 'R'}", *calibration_figure(lang, hl))); MIN_FONT = 0
    jobs.append((f"slides_brtraining_{lang}", *brtraining_figure(lang, True, neutral=True)))
    jobs.append((f"slides_calibration_{lang}", *calibration_figure(lang, True, neutral=True)))

with sync_playwright() as p:
    b = p.chromium.launch()
    pg = b.new_page(viewport={"width": 1600, "height": 1400}, device_scale_factor=1)
    for name, svg, w, h in jobs:
        pg.set_content(f'<html><body style="margin:0;background:{BG}">{svg}</body></html>')
        pg.screenshot(path=str(OUT / f"{name}.png"), clip={"x": 0, "y": 0, "width": w, "height": h})
    b.close()
print(len(jobs), "figures")
