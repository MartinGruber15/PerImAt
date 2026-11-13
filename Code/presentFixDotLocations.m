function participantInfo = presentFixDotLocations(log, ptb, design, myPaths, participantInfo)
% presentFixDotLocations  Fixation-dot positions, then a 7-trial practice of the whole task (dual).
%
% 1. Fusion alignment.
% 2. Instruction (design.fixDotDemoInstruction).
% 3. The house, the same image in both eyes (no rivalry), with the
%    fixation dot at position 1, 2, ... one after another, then with all
%    positions at once; then the same for the face. The images are the ones
%    of the experiment (design.images.<house|face><L|R>_dot_<pos>, i.e. the
%    subject's contrasts and the current dot style) on pink noise.
%    Any key: next image; ESC: skip the rest of the demonstration.
% 4. [changed 2026-11-04] Practice of the whole task in the dual condition
%    (report the first percept + follow the dots): perImAtOffline in
%    'practice' mode = 7 trials (2 imagery, 2 attention, 2 perception - one
%    per cue - and 1 baseline) in blocks like the real runs, with the real
%    trial durations (cue, task, rivalry, report, rating, ITI), the task
%    instructions and the rating screen before; no new fusion alignment.
%    Saved as sub-XX_practice_du_<time>.csv. Before: questPlusTest 'dual'
%    with 20 rivalry-only trials (no cue/task).

participantInfo = display.stereo.alignFusion(ptb, participantInfo);
questplus.saveFusionOffsets(participantInfo, myPaths);
% [changed 2026-11-10] the explanation is split over three short screens:
% fixDotDemo1 (a dot appears), fixDotDemo2 (the positions follow) before the
% demonstration, fixDotDemo3 (now the practice) after it
display.stereo.instruction(ptb, design, design.fixDotDemo1, 0.5, false);
display.stereo.instruction(ptb, design, design.fixDotDemo2, 0.5, false);

nPos = size(design.fixDotPositions, 1);
stimuli = {'house', 'face'};
KbReleaseWait(-1);
stop = false;
for s = 1:numel(stimuli)
    for pos = 1:nPos + 1
        if pos <= nPos
            imgL = design.images.(sprintf('%sL_dot_%d', stimuli{s}, pos));
            imgR = design.images.(sprintf('%sR_dot_%d', stimuli{s}, pos));
            what = sprintf('position %d', pos);
        else
            imgL = allDots(design, [stimuli{s} 'L'], nPos);
            imgR = allDots(design, [stimuli{s} 'R'], nPos);
            what = 'all positions';
        end
        texL = generate.makePinkNoiseTex(ptb.window, imgL, [], design);
        texR = generate.makePinkNoiseTex(ptb.window, imgR, [], design);
        draw.stereo.images(ptb, design, texL, texR);
        Screen('Flip', ptb.window);
        fprintf('%s, %s (any key: next, ESC: skip the demonstration)\n', stimuli{s}, what);
        [~, keyCode] = KbStrokeWait(-1);
        Screen('Close', [texL, texR]);
        if keyCode(ptb.Keys.escape); stop = true; break; end
    end
    if stop; break; end
end

% [changed 2026-11-04] practice of the whole task, dual condition, 7 trials
log.reportCond = reportCondition.dual;
log.suffix = 'du';
display.stereo.instruction(ptb, design, design.fixDotDemo3, 0.5, false);
[~, ~, ~, participantInfo] = perImAtOffline(log, ptb, design, myPaths, participantInfo, 'practice');
end


function img = allDots(design, baseName, nPos)
% all dot positions in one image: start from the image without dots and
% copy the pixels that each single-dot image changes (the dots do not overlap)
base = design.images.(baseName);
img = base;
for pos = 1:nPos
    d = design.images.(sprintf('%s_dot_%d', baseName, pos));
    changed = any(d ~= base, 3);
    for ch = 1:size(img, 3)
        plane = img(:, :, ch); dp = d(:, :, ch);
        plane(changed) = dp(changed);
        img(:, :, ch) = plane;
    end
end
end
