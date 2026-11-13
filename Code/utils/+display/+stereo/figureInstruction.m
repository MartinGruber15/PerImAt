function shown = figureInstruction(ptb, design, figureFile, text, waitDuration)
% display.stereo.figureInstruction  Instruction figure (PNG) + one text line, in both eyes.
%
%   shown = display.stereo.figureInstruction(ptb, design, figureFile, text, waitDuration)
%
% [added 2026-11-10] Shows the task figure of a report condition
% (instructions/figures/block_<condition>_<lang>_house<L|R>_house<Red|Teal>.png,
% made by stimulusPreparation/makeInstructionFigures.py; file chosen in
% getInstructions) scaled to design.instructionFigureWidth (default 0.76, was 0.95) of
% the eye's buffer width and at most design.instructionFigureHeight (0.68, was 0.85)
% of its height, top-aligned, with TEXT (e.g. "Press any key to continue.")
% below. Waits at least waitDuration s, then for a key on the subject
% keyboard. Returns false (and shows nothing) if the file does not exist,
% so the caller can show the text version instead.
%
% [added 2026-11-10] FIGUREFILE may be a cell array of files (the steps of a
% figure): they are shown one after another, each until a key press. Nothing
% is shown (shown = false) if any of them is missing.
shown = false;
if nargin < 5 || isempty(waitDuration); waitDuration = 0.5; end
if iscell(figureFile)
    files = figureFile;
else
    files = {figureFile};
end
for i = 1:numel(files)
    if isempty(files{i}) || ~isfile(files{i})
        fprintf(2, 'Instruction figure not found: %s (text version shown instead)\n', char(files{i}));
        return
    end
end
for i = 1:numel(files)
    showOne(ptb, design, files{i}, text, waitDuration);
    if i < numel(files); KbReleaseWait(-1); end   % the key for this step must not skip the next
end
shown = true;
end


function showOne(ptb, design, figureFile, text, waitDuration)
img = imread(figureFile);
tex = Screen('MakeTexture', ptb.window, img);
if isfield(design, 'instructionFigureWidth') || (isobject(design) && design.hasField('instructionFigureWidth'))
    wFrac = design.instructionFigureWidth;
else
    wFrac = 0.76;   % [changed 2026-11-11] 20 % smaller (was 0.95); figures re-made with min. font 22 px
end
if isfield(design, 'instructionFigureHeight') || (isobject(design) && design.hasField('instructionFigureHeight'))
    hFrac = design.instructionFigureHeight;
else
    hFrac = 0.68;   % [changed 2026-11-11] was 0.85
end
[bw, bh] = Screen('WindowSize', ptb.window);   % one eye's buffer (side-by-side stereo)
scale = min(wFrac * bw / size(img, 2), hFrac * bh / size(img, 1));
w = round(size(img, 2) * scale); h = round(size(img, 1) * scale);
y0 = round((bh - h) / 2) - round(0.04 * bh);
rect = [round((bw - w) / 2), y0, round((bw - w) / 2) + w, y0 + h];
buffers = [ptb.leftBuffer, ptb.rightBuffer];
for b = 1:2
    Screen('SelectStereoDrawBuffer', ptb.window, buffers(b));
    Screen('DrawTexture', ptb.window, tex, [], rect);
    DrawFormattedText(ptb.window, text, 'center', rect(4) + round(0.04 * bh), ptb.FontColor);
    if ptb.usedatapixx
        if b == 1
            Screen('FillRect', ptb.window, [0, 0, 255], design.blueRectLeftOn);
            Screen('FillRect', ptb.window, [0, 0, 0], design.blueRectLeftOff);
        else
            Screen('FillRect', ptb.window, [0, 0, 255], design.blueRectRightOn);
            Screen('FillRect', ptb.window, [0, 0, 0], design.blueRectRightOff);
        end
    end
end
Screen('DrawingFinished', ptb.window);
Screen('Flip', ptb.window);
WaitSecs(waitDuration);
KbWait(ptb.Keyboard2, 2);
Screen('Close', tex);
end
