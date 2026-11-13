// PerImAt experiment questionnaire (English + German), revised 2026-11-11;
// 2026-11-12: question on the report catch trials (no rivalry noticed?) in "At the end".
// usage: node make_questionnaire.js <outdir>
const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, WidthType, BorderStyle,
  ShadingType, AlignmentType, Footer, PageNumber, HeightRule, VerticalAlign,
} = require("docx");

const OUT = process.argv[2] || ".";
const FONT = "Calibri";
const CONTENT_W = 11906 - 1418 - 1134; // A4 minus margins (as in the original)
const NONE = { style: BorderStyle.NONE, size: 0, color: "FFFFFF" };
const NO_BORDERS = { top: NONE, bottom: NONE, left: NONE, right: NONE, insideHorizontal: NONE, insideVertical: NONE };

const run = (text, o = {}) => new TextRun({ text, font: FONT, size: o.size || 20, bold: o.bold, italics: o.italics, color: o.color });
const para = (children, o = {}) => new Paragraph({
  children: Array.isArray(children) ? children : [children],
  alignment: o.align, spacing: { before: o.before ?? 0, after: o.after ?? 80 }, indent: o.indent, keepNext: o.keepNext,
});

let qn = 0;
function question(text, note) {
  qn += 1;
  const ch = [run(`${qn}. `, { bold: true }), run(text, { bold: true })];
  if (note) ch.push(run(` ${note}`, { italics: true }));
  return para(ch, { before: 200, after: 80, keepNext: true });
}
const sub = (text) => para([run(text, { bold: true, size: 20 })], { before: 120, after: 40, keepNext: true, indent: { left: 284 } });
const section = (text) => para([run(text, { bold: true, size: 24 })], { before: 320, after: 80, keepNext: true });
const checkbox = (text, last) => para([run("☐  ", { size: 22 }), run(text)], { indent: { left: 567 }, after: last ? 80 : 30, keepNext: !last });
const line = (label) => para([run(label + " "), run("_".repeat(60), { color: "808080" })], { indent: { left: 567 }, after: 80 });

// 9-point scale: left anchor | 9 circles | right anchor, numbers under the circles, optional middle label
function scale(left, right, middle, indentLeft = 284) {
  const aw = 2040, cw = Math.floor((CONTENT_W - indentLeft - 2 * aw) / 9);
  const total = 2 * aw + 9 * cw;
  const cell = (children, w, align = AlignmentType.CENTER, kn = true) => new TableCell({
    children: [new Paragraph({ children, alignment: align, keepNext: kn, keepLines: true, spacing: { before: 0, after: 0 } })],
    width: { size: w, type: WidthType.DXA }, borders: NO_BORDERS, verticalAlign: VerticalAlign.CENTER,
    margins: { top: 20, bottom: 20, left: 40, right: 40 },
  });
  const cell2 = (top, bottom, w, align = AlignmentType.CENTER) => new TableCell({
    children: [
      new Paragraph({ children: top, alignment: align, keepNext: true, keepLines: true, spacing: { before: 0, after: 0 } }),
      new Paragraph({ children: bottom, alignment: AlignmentType.CENTER, keepNext: !!middle, keepLines: true, spacing: { before: 0, after: 0 } }),
    ],
    width: { size: w, type: WidthType.DXA }, borders: NO_BORDERS, verticalAlign: VerticalAlign.TOP,
    margins: { top: 20, bottom: 20, left: 40, right: 40 },
  });
  const row1 = new TableRow({ cantSplit: true, children: [
    cell2([run(left, { bold: true, size: 18 })], [run("", { size: 16 })], aw, AlignmentType.RIGHT),
    ...Array.from({ length: 9 }, (_, i) => cell2([run("○", { size: 30 })], [run(String(i + 1), { size: 16 })], cw)),
    cell2([run(right, { bold: true, size: 18 })], [run("", { size: 16 })], aw, AlignmentType.LEFT),
  ] });
  const rows = [row1];
  if (middle) {
    const mid = new TableCell({
      children: [new Paragraph({ children: [run(middle, { size: 16, bold: true })], alignment: AlignmentType.CENTER, spacing: { before: 0, after: 0 } })],
      width: { size: 3 * cw, type: WidthType.DXA }, columnSpan: 3, borders: NO_BORDERS,
      margins: { top: 0, bottom: 20, left: 0, right: 0 },
    });
    rows.push(new TableRow({ children: [
      cell([run("")], aw, AlignmentType.CENTER, false),
      ...Array.from({ length: 3 }, () => cell([run("")], cw, AlignmentType.CENTER, false)), mid, ...Array.from({ length: 3 }, () => cell([run("")], cw, AlignmentType.CENTER, false)),
      cell([run("")], aw, AlignmentType.CENTER, false),
    ] }));
  }
  return [new Table({ rows, width: { size: total, type: WidthType.DXA }, columnWidths: [aw, ...Array(9).fill(cw), aw],
    borders: NO_BORDERS, indent: { size: indentLeft, type: WidthType.DXA } }), para([run("")], { after: 40 })];
}

function box(height = 1500) {
  return [new Table({
    rows: [new TableRow({ height: { value: height, rule: HeightRule.ATLEAST }, children: [new TableCell({
      children: [new Paragraph({ children: [run("")] })], width: { size: CONTENT_W, type: WidthType.DXA },
      shading: { fill: "D9D9D9", type: ShadingType.CLEAR, color: "auto" },
      borders: { top: { style: BorderStyle.SINGLE, size: 4, color: "808080" }, bottom: { style: BorderStyle.SINGLE, size: 4, color: "808080" },
        left: { style: BorderStyle.SINGLE, size: 4, color: "808080" }, right: { style: BorderStyle.SINGLE, size: 4, color: "808080" } },
    })] })],
    width: { size: CONTENT_W, type: WidthType.DXA }, columnWidths: [CONTENT_W],
  }), para([run("")], { after: 40 })];
}

const T = {
  en: {
    file: "Questionnaire_BR_en_2026-11-12.docx",
    title: "Questionnaire: Binocular Rivalry",
    id: "Subject ID: ________   Date: ____________",
    intro: "Please answer every question. There are no right or wrong answers.",
    s1: "About the study",
    aim: "What do you think was the aim of the study?",
    assume: "Did your thoughts or assumptions about the aim of the study influence what you expected to see or how you responded during the experiment?",
    no: "No", yesHow: "Yes. Please describe how:",
    s2: "What you saw during the rivalry",
    dom: "Did you see one image (house or face) more often than the other, or both equally?",
    domL: "mostly the house", domR: "mostly the face", equal: "equal",
    mix: "How often did you see a mixture (parts of both images)?",
    never: "never", almostAlways: "almost always", always: "always", almostNever: "almost never", veryOften: "very often",
    // [changed 2026-11-12] about being unsure whether an image was clear enough (was: "the first image")
    unsure: "When you were unsure whether an image was clear enough (e.g. one image only slightly dominated, or the mixture did not fully clear up): which key did you mostly press?", unsureNote: "(keys part and keys + dot part; tick one)",
    unsureOpts: ["the lower key (mixture)", "the key of the image that was a bit stronger", "the key of the image of the colour", "it varied"],
    covert: "In the dot part (no keys for the images): did you still decide which image you saw?",
    s3: "Difficulty",
    diff: "How difficult did you find …", easy: "very easy", hard: "very difficult",
    diffItems: [
      ["… the experiment overall?"],
      ["Task before the rivalry", "I: imagining the image of the colour"],
      [null, "A: attending to the image of the colour in the overlaid images"],
      [null, "P: perceiving the faint image"],
      ["During the rivalry", "fixating the dot"],
      [null, "pressing the key for the first clear image"],
      [null, "deciding between a clear image and a mixture"],
      [null, "doing both at once (keys + dot part)"],
      ["After the rivalry", "the 1–5 rating"],
    ],
    diffComment: "What did you find difficult? Please comment:",
    s4: "How you did the tasks",
    imgContent: "I task: when you imagined the house or face, what did you imagine?", oneAnswer: "(tick one)",
    imgOpts: ["exactly the house / face from the experiment", "a house or face I know (a familiar person or place)",
      "a general house or face, not a specific one", "it changed from trial to trial",
      "no picture: I thought of it in words or just knew which one it was"],
    other: "other:",
    imgChange: "Did this change during the experiment? If yes, when?",
    imgWhere: "I task: where did you imagine it?",
    whereOpts: ["on the grey square, about the same size", "on the grey square, but in a different size",
      "somewhere else (“in my head”)", "no particular place"],
    vivid: "I task: how vivid were your images in this experiment?", noImage: "no image at all", asSeeing: "as vivid as seeing",
    attend: "A task: how did you attend to the image of the colour?", tickAll: "(tick all that apply)",
    attendOpts: ["I looked at its parts (e.g. windows, eyes)", "I tried to ignore the other image",
      "I imagined it stronger", "I moved my eyes over it"],
    faint: "P task: how closely did you look at the faint image during the task?", faintL: "not closely at all", faintR: "very closely",
    ratingBasis: "What did your 1–5 ratings mostly reflect?",
    ratingOpts: ["how clear or vivid it was", "how much effort it took", "how well I could concentrate"],
    ratingAcc: "How well do your 1–5 ratings reflect how well you actually did the task?",
    notAtAll: "not at all", veryAccurately: "very accurately",
    s5: "The fixation dots",
    twoDots: "Did it happen during the experiment that you saw two fixation dots at the same time?",
    twoOpts: ["no, never", "yes, but only when I saw a mixture", "yes, also when I saw only one of the images"],
    howOften: "If yes, how often did that happen?",
    twoWhat: "What did you do when you saw two fixation dots at the same time?",
    twoWhatOpts: ["I fixated the cross in the centre", "I fixated one of the two dots", "I am not sure"],
    s6: "Influence of the tasks on the rivalry",
    inflIntro: "For each task: did it influence which image you then saw in the rivalry?",
    inflItems: ["I: imagining the image of the colour", "A: attending to the image of the colour in the overlaid images",
      "P: perceiving the faint image"],
    inflL: "rather the image of the colour", inflR: "rather the other image", noInfl: "no influence", dontKnow: "I don’t know",
    s7: "At the end",
    tired: "How tired were you at the end of the experiment?", veryTired: "very tired",
    frames: "During a run, did you ever see two frames instead of one?",
    frameOpts: ["never", "sometimes", "often"],
    noRivalry: "Keys part: were there trials in which you were convinced that there was no rivalry at all, i.e. both eyes really saw the same image?",
    noRivalryOpts: ["no, never", "yes, only the face", "yes, only the house",
      "yes, a static pattern of house and face (parts of both that did not change)"],
    comments: "Further comments:",
  },
  de: {
    file: "Questionnaire_BR_deutsch_2026-11-12.docx",
    title: "Fragebogen: Binokulare Rivalität",
    id: "VP-Nr.: ________   Datum: ____________",
    intro: "Bitte beantworten Sie alle Fragen. Es gibt keine richtigen oder falschen Antworten.",
    s1: "Zur Studie",
    aim: "Was war Ihrer Meinung nach das Ziel der Studie?",
    assume: "Haben Ihre Vermutungen oder Annahmen über das Studienziel beeinflusst, was Sie erwartet haben wahrzunehmen oder wie Sie während des Experiments geantwortet haben?",
    no: "Nein", yesHow: "Ja. Bitte beschreiben Sie, wie:",
    s2: "Was Sie in der Rivalität gesehen haben",
    dom: "Haben Sie ein Bild (Haus oder Gesicht) öfter gesehen als das andere oder beide gleich oft?",
    domL: "meist das Haus", domR: "meist das Gesicht", equal: "gleich",
    mix: "Wie oft haben Sie eine Mischung (Teile beider Bilder) gesehen?",
    never: "nie", almostAlways: "fast immer", always: "immer", almostNever: "fast nie", veryOften: "sehr oft",
    // [changed 2026-11-12] siehe englische Version
    unsure: "Wenn Sie unsicher waren, ob ein Bild deutlich genug war (z. B. ein Bild überwog nur leicht, oder die Mischung wurde nicht ganz klar): Welche Taste haben Sie dann meistens gedrückt?", unsureNote: "(Tasten-Teil und Tasten + Punkt; bitte eines ankreuzen)",
    unsureOpts: ["die untere Taste (Mischung)", "die Taste des Bildes, das etwas stärker war", "die Taste des Bildes der Farbe", "unterschiedlich"],
    covert: "Im Punkt-Teil (keine Taste für die Bilder): Haben Sie trotzdem entschieden, welches Bild Sie sehen?",
    s3: "Schwierigkeit",
    diff: "Wie schwierig fanden Sie …", easy: "sehr leicht", hard: "sehr schwierig",
    diffItems: [
      ["… das Experiment insgesamt?"],
      ["Aufgabe vor der Rivalität", "I: sich das Bild der Farbe vorstellen"],
      [null, "A: auf das Bild der Farbe in den übereinanderliegenden Bildern achten"],
      [null, "P: das blasse Bild wahrnehmen"],
      ["In der Rivalität", "den Fixationspunkt fixieren"],
      [null, "die Taste für das erste deutliche Bild drücken"],
      [null, "zwischen deutlichem Bild und Mischung entscheiden"],
      [null, "beides gleichzeitig (Tasten + Punkt)"],
      ["Nach der Rivalität", "die Bewertung 1–5"],
    ],
    diffComment: "Was ist Ihnen schwergefallen? Bitte kommentieren Sie:",
    s4: "Wie Sie die Aufgaben gemacht haben",
    imgContent: "Aufgabe I: Was haben Sie sich vorgestellt, wenn Sie sich das Haus oder Gesicht vorgestellt haben?", oneAnswer: "(bitte eines ankreuzen)",
    imgOpts: ["genau das Haus / Gesicht aus dem Experiment", "ein Haus oder Gesicht, das ich kenne (eine vertraute Person oder ein vertrauter Ort)",
      "ein allgemeines Haus oder Gesicht, kein bestimmtes", "das war von Durchgang zu Durchgang verschieden",
      "kein Bild: ich habe in Worten daran gedacht oder nur gewusst, welches es ist"],
    other: "Anderes:",
    imgChange: "Hat sich das im Lauf des Experiments verändert? Falls ja, wann?",
    imgWhere: "Aufgabe I: Wo haben Sie es sich vorgestellt?",
    whereOpts: ["auf dem grauen Quadrat, etwa gleich groß", "auf dem grauen Quadrat, aber in einer anderen Größe",
      "woanders („im Kopf“)", "an keinem bestimmten Ort"],
    vivid: "Aufgabe I: Wie lebhaft waren Ihre Vorstellungsbilder in diesem Experiment?", noImage: "gar kein Bild", asSeeing: "so lebhaft wie Sehen",
    attend: "Aufgabe A: Wie haben Sie auf das Bild der Farbe geachtet?", tickAll: "(alles Zutreffende ankreuzen)",
    attendOpts: ["auf seine Teile geschaut (z. B. Fenster, Augen)", "versucht, das andere Bild nicht zu beachten",
      "es mir stärker vorgestellt", "die Augen darüber bewegt"],
    faint: "Aufgabe P: Wie genau haben Sie das blasse Bild während der Aufgabe betrachtet?", faintL: "gar nicht genau", faintR: "sehr genau",
    ratingBasis: "Was haben Ihre Bewertungen 1–5 vor allem ausgedrückt?",
    ratingOpts: ["wie deutlich oder lebhaft es war", "wie viel Anstrengung es gekostet hat", "wie gut ich mich konzentrieren konnte"],
    ratingAcc: "Wie gut spiegeln Ihre Bewertungen 1–5 wider, wie gut Sie die Aufgabe tatsächlich gemacht haben?",
    notAtAll: "überhaupt nicht", veryAccurately: "sehr genau",
    s5: "Die Fixationspunkte",
    twoDots: "Ist es während des Experiments passiert, dass Sie zwei Fixationspunkte gleichzeitig gesehen haben?",
    twoOpts: ["nein, nie", "ja, aber nur, wenn ich eine Mischung gesehen habe", "ja, auch wenn ich nur eines der Bilder gesehen habe"],
    howOften: "Falls ja, wie oft ist das passiert?",
    twoWhat: "Was haben Sie gemacht, wenn Sie zwei Fixationspunkte gleichzeitig gesehen haben?",
    twoWhatOpts: ["das Kreuz in der Mitte fixiert", "einen der beiden Punkte fixiert", "ich bin mir nicht sicher"],
    s6: "Einfluss der Aufgaben auf die Rivalität",
    inflIntro: "Für jede Aufgabe: Hat sie beeinflusst, welches Bild Sie danach in der Rivalität gesehen haben?",
    inflItems: ["I: sich das Bild der Farbe vorstellen", "A: auf das Bild der Farbe in den übereinanderliegenden Bildern achten",
      "P: das blasse Bild wahrnehmen"],
    inflL: "eher das Bild der Farbe", inflR: "eher das andere Bild", noInfl: "kein Einfluss", dontKnow: "Ich weiß nicht",
    s7: "Zum Schluss",
    tired: "Wie müde waren Sie am Ende des Experiments?", veryTired: "sehr müde",
    frames: "Haben Sie während eines Durchlaufs einmal zwei Rahmen statt einem gesehen?",
    frameOpts: ["nie", "manchmal", "oft"],
    noRivalry: "Tasten-Teil: Gab es Durchgänge, in denen Sie überzeugt waren, dass gar keine Rivalität stattfand, beide Augen also wirklich dasselbe Bild sahen?",
    noRivalryOpts: ["nein, nie", "ja, nur das Gesicht", "ja, nur das Haus",
      "ja, ein festes Muster aus Haus und Gesicht (Teile von beiden, die sich nicht veränderten)"],
    comments: "Weitere Kommentare:",
  },
};

function build(L) {
  qn = 0;
  const c = [];
  c.push(para([run(L.title, { bold: true, size: 32 })], { align: AlignmentType.CENTER, after: 60 }));
  c.push(para([run(L.id, { bold: true })], { align: AlignmentType.RIGHT, after: 120 }));
  c.push(para([run(L.intro, { italics: true })], { after: 120 }));

  c.push(section(L.s1));
  c.push(question(L.aim)); c.push(...box(1600));
  c.push(question(L.assume));
  c.push(checkbox(L.no)); c.push(checkbox(L.yesHow, true)); c.push(...box(1300));

  c.push(section(L.s2));
  c.push(question(L.dom)); c.push(...scale(L.domL, L.domR, L.equal));
  c.push(question(L.mix)); c.push(...scale(L.never, L.almostAlways));
  c.push(question(L.unsure, L.unsureNote));
  L.unsureOpts.forEach((o, i) => c.push(checkbox(o, i === L.unsureOpts.length - 1)));
  c.push(question(L.covert)); c.push(...scale(L.never, L.always));

  c.push(section(L.s3));
  c.push(question(L.diff));
  L.diffItems.forEach(([head, item]) => {
    if (head && !item) { c.push(sub(head)); }
    else {
      if (head) c.push(sub(head));
      c.push(para([run("– " + item)], { indent: { left: 567 }, after: 20, keepNext: true }));
    }
    c.push(...scale(L.easy, L.hard));
  });
  c.push(para([run(L.diffComment, { bold: true })], { before: 120, keepNext: true })); c.push(...box(1300));

  c.push(section(L.s4));
  c.push(question(L.imgContent, L.tickAll));
  L.imgOpts.forEach((o) => c.push(checkbox(o)));
  c.push(line("☐  " + L.other));
  c.push(para([run(L.imgChange)], { indent: { left: 567 }, after: 20, keepNext: true })); c.push(line(""));
  c.push(question(L.imgWhere, L.tickAll));   // [changed 2026-11-12] was oneAnswer
  L.whereOpts.forEach((o, i) => c.push(checkbox(o, i === L.whereOpts.length - 1)));
  c.push(question(L.vivid)); c.push(...scale(L.noImage, L.asSeeing));
  c.push(question(L.attend, L.tickAll));
  L.attendOpts.forEach((o) => c.push(checkbox(o))); c.push(line("☐  " + L.other));
  c.push(question(L.faint)); c.push(...scale(L.faintL, L.faintR));
  c.push(question(L.ratingBasis, L.tickAll));
  L.ratingOpts.forEach((o) => c.push(checkbox(o))); c.push(line("☐  " + L.other));
  c.push(question(L.ratingAcc)); c.push(...scale(L.notAtAll, L.veryAccurately));

  c.push(section(L.s5));
  c.push(question(L.twoDots));
  L.twoOpts.forEach((o, i) => c.push(checkbox(o, i === L.twoOpts.length - 1)));
  c.push(para([run(L.howOften)], { indent: { left: 567 }, after: 20, keepNext: true }));
  c.push(...scale(L.almostNever, L.veryOften, null, 567));
  c.push(question(L.twoWhat, L.oneAnswer));   // [changed 2026-11-12] was tickAll
  L.twoWhatOpts.forEach((o) => c.push(checkbox(o))); c.push(line("☐  " + L.other));

  c.push(section(L.s6));
  c.push(para([run(L.inflIntro, { bold: true })], { after: 80, keepNext: true }));
  L.inflItems.forEach((item) => {
    c.push(question(item));
    c.push(...scale(L.inflL, L.inflR, L.noInfl));
    c.push(checkbox(L.dontKnow, true));
  });

  c.push(section(L.s7));
  c.push(question(L.tired)); c.push(...scale(L.notAtAll, L.veryTired));
  c.push(question(L.frames));
  L.frameOpts.forEach((o, i) => c.push(checkbox(o, i === L.frameOpts.length - 1)));
  c.push(question(L.noRivalry, L.tickAll));   // [added 2026-11-12] report catch trials noticed?
  L.noRivalryOpts.forEach((o, i) => c.push(checkbox(o, i === L.noRivalryOpts.length - 1)));
  c.push(question(L.comments)); c.push(...box(2400));

  return new Document({
    styles: { default: { document: { run: { font: FONT, size: 20 } } } },
    sections: [{
      properties: { page: { size: { width: 11906, height: 16838 }, margin: { top: 1134, right: 1134, bottom: 1134, left: 1418 } } },
      footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER,
        children: [new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 18 })] })] }) },
      children: c,
    }],
  });
}

(async () => {
  for (const lang of ["en", "de"]) {
    const buf = await Packer.toBuffer(build(T[lang]));
    fs.writeFileSync(path.join(OUT, T[lang].file), buf);
    console.log("wrote", T[lang].file);
  }
})();
