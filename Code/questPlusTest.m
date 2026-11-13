function [participantInfo, results] = questPlusTest(log, ptb, design, myPaths, participantInfo, taskMode, opts)
% opts (optional): .skipFusion (true when the fusion was just aligned). [2026-11-04]
% The 'dual' mode is no longer used by presentFixDotLocations (that now runs
% perImAtOffline 'practice'); it stays available. Number of trials: report mode qpSet.test.nValidTrials
% house/face trials (max qpSet.test.maxTotalTrials incl. mixed); dual mode
% qpSet.test.dualTrials trials in total (incl. mixed).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% questPlusTest: test the contrasts of the latest training file
% (loadLatestTrainingParameters, e.g. the QUEST+ result) with fixed
% stimuli and the same trial structure as questPlusCalibration:
% 2 s dynamic noise mask, 1 s blank, 3 s onset rivalry, grey screen until
% response (house / face / mixed).
%
% The rivalry images are design.images.houseL/faceR/faceL/houseR, i.e. the
% very textures that getVisualDesignSettings built at start-up from the
% latest training file and that the main experiment uses.
%
% qpSet.test.nValidTrials house/face responses are collected, balanced
% between HouseL+FaceR and FaceL+HouseR (shuffled blocks, mixed trials are
% re-queued, at most qpSet.test.maxTotalTrials trials).
%
% taskMode (optional):
%   'report' (default): rivalry images without fixation dots (as in the
%            QUEST+ calibration)
%   'dual'  : dual task as in the main experiment (reportCondition.dual):
%            report the first percept AND follow the no-report fixation
%            dots. Each eye's image carries one fixation dot; the pair of
%            positions (left eye, right eye) is drawn at random from
%            design.fixDotValidPairs on every trial and the images are
%            design.images.<house|face><L|R>_dot_<pos>, exactly as in
%            trialProcedurePerImAtOffline. No catch trials, no eye tracker.
%
% Output (console + sub-XX_questplus-test[-dual]_<time>.mat/.csv):
%   P(house) overall and per eye configuration, P(left-eye stimulus first),
%   proportion mixed; Wilson 95% CIs and exact binomial tests against 0.5;
%   if available, the P(house) predicted by QUEST+.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 6 || isempty(taskMode); taskMode = 'report'; end
if nargin < 7 || isempty(opts); opts = struct(); end
taskMode = lower(char(taskMode));
assert(ismember(taskMode, {'report', 'dual'}), 'taskMode must be ''report'' or ''dual''.');
isDual = strcmp(taskMode, 'dual');
qpSet = getQuestPlusSettings();
timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HHmmss'));
if isDual
    baseName = ['sub-' log.sub '_questplus-test-dual_' timeStamp];
else
    baseName = ['sub-' log.sub '_questplus-test_' timeStamp];
end

% [changed 2026-11-06] the contrasts the textures were built with at start-up
% (getVisualDesignSettings: training file, or values entered by hand when there
% was none); the latest training file only if design does not have them
hasSP = false;
try
    if isstruct(design); hasSP = isfield(design, 'stimuliParameters'); else; hasSP = design.hasField('stimuliParameters'); end
catch
end
if hasSP
    stimuliParameters = design.stimuliParameters;
    fprintf('Contrasts of the textures: %s\n', questplus.contrastText(stimuliParameters));
else
    stimuliParameters = loadLatestTrainingParameters(myPaths.subjectDirectory);   % prints the values
end

%% Keyboard, fusion, mask, instructions ----------------------------------------
KbQueueStop(ptb.Keyboard2); KbEventFlush(ptb.Keyboard2);
KbQueueStop(ptb.Keyboard1); KbEventFlush(ptb.Keyboard1);
KbQueueStart(ptb.Keyboard2); KbQueueStart(ptb.Keyboard1);
if ~(isfield(opts, 'skipFusion') && opts.skipFusion)
    participantInfo = display.stereo.alignFusion(ptb, participantInfo);
end
fusionOffsets = questplus.saveFusionOffsets(participantInfo, myPaths);   % keep + log the offsets
% [changed 2026-11-10] report mode: the calibration figure; text if it is missing (and in dual mode)
calFig = '';
if strcmpi(taskMode, 'report') && isobject(myPaths) && myPaths.hasField('instructionFigurePath') && design.hasField('instructionFigure')
    calFig = fullfile(myPaths.instructionFigurePath, design.instructionFigure.calibration);
end
if ~display.stereo.figureInstruction(ptb, design, calFig, design.figureContinue, qpSet.instructionWaitDuration)
    display.stereo.instruction(ptb, design, questplus.instructionText(ptb, participantInfo, taskMode, design), qpSet.instructionWaitDuration, false);
end
if strcmpi(taskMode, 'report')   % [added 2026-11-11] key reminder (any key), then the start countdown
    display.stereo.instruction(ptb, design, design.calibrationReminder, qpSet.instructionWaitDuration, false);
    KbReleaseWait(-1);
end
display.stereo.instruction(ptb, design, design.waitTillStart, design.waitTillStartDuration, true);

%% Trials ----------------------------------------------------------------------
sch = questplus.schedule('init', qpSet.blockSize);
trials = struct([]);
nValid = 0; nTotal = 0; aborted = false;
if isDual
    nValidTarget = Inf; nTotalMax = qpSet.test.dualTrials;
else
    nValidTarget = qpSet.test.nValidTrials; nTotalMax = qpSet.test.maxTotalTrials;
end
while nValid < nValidTarget && nTotal < nTotalMax
    [houseEye, sch] = questplus.schedule('next', sch);
    if houseEye == 1
        leftName = 'houseL'; rightName = 'faceR';
    else
        leftName = 'faceL';  rightName = 'houseR';
    end
    if isDual
        % as in trialProcedurePerImAtOffline (setUpStimuliButInGreyShadesThisTime)
        selectedPair = design.fixDotValidPairs(randi(size(design.fixDotValidPairs, 1)), :);
        leftName  = sprintf('%s_dot_%d', leftName,  selectedPair(1));
        rightName = sprintf('%s_dot_%d', rightName, selectedPair(2));
    else
        selectedPair = [NaN NaN];
    end
    leftImg = design.images.(leftName); rightImg = design.images.(rightName);
    [leftTex, rightTex] = questplus.makeRivalryTextures(ptb, design, leftImg, rightImg);
    [res, aborted] = questplus.runTrial(ptb, design, qpSet, leftTex, rightTex);
    Screen('Close', [leftTex, rightTex]);
    if aborted; break; end
    nTotal = nTotal + 1;
    if strcmp(res.response, 'mixed')
        [~, sch] = questplus.schedule('requeue', sch, houseEye);
    else
        nValid = nValid + 1;
    end
    t.trial = nTotal;
    t.houseEye = houseEye;
    if houseEye == 1; t.eyeConfig = 'HouseL_FaceR'; t.leftEye = 'house'; t.rightEye = 'face';
    else;             t.eyeConfig = 'FaceL_HouseR'; t.leftEye = 'face';  t.rightEye = 'house'; end
    t.taskMode = taskMode;
    t.leftImage = leftName; t.rightImage = rightName;
    t.fixDotPosLeft = selectedPair(1); t.fixDotPosRight = selectedPair(2);
    if houseEye == 1
        t.fixDotPosHouse = selectedPair(1); t.fixDotPosFace = selectedPair(2);
    else
        t.fixDotPosHouse = selectedPair(2); t.fixDotPosFace = selectedPair(1);
    end
    if isDual
        t.fixDotCoordHouse = mat2str(design.fixDotPositions(t.fixDotPosHouse, :), 6);
        t.fixDotCoordFace  = mat2str(design.fixDotPositions(t.fixDotPosFace, :), 6);
    else
        t.fixDotCoordHouse = ''; t.fixDotCoordFace = '';
    end
    t.response = res.response;
    t.missed = isfield(res, 'missed') && res.missed;   % [added 2026-11-10]
    t.rt = res.rt;
    t.respondedDuringRivalry = res.respondedDuringRivalry;
    t.ambiguous = res.ambiguous;
    t.keySequence = strjoin(string(res.keySequence), ',');
    t.maskOnset = res.maskOnset; t.blankOnset = res.blankOnset;
    t.rivalryOnset = res.rivalryOnset; t.rivalryOffset = res.rivalryOffset;
    t.responseTime = res.responseTime;
    if isempty(trials); trials = t; else; trials(end+1) = t; end %#ok<AGROW>
    respLabel = res.response; if t.missed; respLabel = 'none (missed)'; end
    fprintf('%3d (%3d valid) %-14s -> %s\n', nTotal, nValid, t.eyeConfig, respLabel);
end

if ~aborted
    display.stereo.instruction(ptb, design, design.RunIsOver, qpSet.instructionWaitDuration, false);
end
Screen('CloseAll');
ListenChar(1);

%% Analysis --------------------------------------------------------------------
results.sub = log.sub;
results.taskMode = taskMode;
results.timeStamp = timeStamp;
results.stimuliParameters = stimuliParameters;
results.trials = trials;
results.aborted = aborted;
results.fusionOffsets = fusionOffsets;
if isempty(trials)
    fprintf('No trials recorded.\n');
    return
end
resp = {trials.response}; he = [trials.houseEye];
isH = strcmp(resp, 'house'); isF = strcmp(resp, 'face'); valid = isH | isF;
results.pHouse        = questplus.binomialSummary(sum(isH), sum(valid));
results.pHouse_HouseL = questplus.binomialSummary(sum(isH & he == 1),  sum(valid & he == 1));
results.pHouse_HouseR = questplus.binomialSummary(sum(isH & he == -1), sum(valid & he == -1));
leftWins = (isH & he == 1) | (isF & he == -1);
results.pLeftEyeWins  = questplus.binomialSummary(sum(leftWins), sum(valid));
results.pMixed        = mean(~valid);
% how often each stimulus x eye texture was perceived first
isM = ~valid; A = he == 1; B = he == -1;
results.counts = struct( ...
    'shownHouseLFaceR', sum(A), 'shownFaceLHouseR', sum(B), ...
    'HouseL', sum(isH & A), 'FaceR', sum(isF & A), 'mixedHouseLFaceR', sum(isM & A), ...
    'FaceL',  sum(isF & B), 'HouseR', sum(isH & B), 'mixedFaceLHouseR', sum(isM & B));

results.carryover = questplus.carryover(trials);   % winning eye per trial, runs
save(fullfile(myPaths.subjectDirectory, [baseName '.mat']), 'results');
writetable(struct2table(trials, 'AsArray', true), fullfile(myPaths.subjectDirectory, [baseName '.csv']), 'Delimiter', ';');

fprintf('\n=================================================\n');
if isDual
    fprintf('     TEST OF THE CURRENT CONTRASTS - DUAL TASK\n');
else
    fprintf('           TEST OF THE CURRENT CONTRASTS\n');
end
fprintf('=================================================\n');
fprintf('House %.4f  Face %.4f  | Left eye %.4f  Right eye %.4f\n', stimuliParameters.houseContrast, ...
    stimuliParameters.faceContrast, stimuliParameters.leftEyeContrast, stimuliParameters.rightEyeContrast);
note = '';
if aborted; note = ' (run aborted with ESC)'; end
fprintf('%d trials, %d house/face, %.0f%% mixed%s\n\n', nTotal, sum(valid), 100 * results.pMixed, note);
printCounts(results.counts);
printRow('P(house) overall',              results.pHouse);
printRow('P(house) | HouseL+FaceR',       results.pHouse_HouseL);
printRow('P(house) | FaceL+HouseR',       results.pHouse_HouseR);
printRow('P(left-eye stimulus first)',    results.pLeftEyeWins);
questplus.carryover(trials, true);                 % print eye carry-over
if isfield(stimuliParameters, 'questPlus') && isfield(stimuliParameters.questPlus, 'predictedPHouse')
    pp = stimuliParameters.questPlus.predictedPHouse;
    fprintf('QUEST+ prediction: P(house) %.3f (HouseL+FaceR) / %.3f (FaceL+HouseR)\n', pp(1), pp(2));
end
if isDual
    % side by side with the latest report-only test of the same contrasts
    prev = dir(fullfile(myPaths.subjectDirectory, ['sub-' log.sub '_questplus-test_*.mat']));
    if ~isempty(prev)
        [~, iLatest] = max([prev.datenum]);
        P = load(fullfile(prev(iLatest).folder, prev(iLatest).name), 'results');
        P = P.results;
        sameParams = isfield(P, 'stimuliParameters') && ...
            abs(P.stimuliParameters.houseContrast - stimuliParameters.houseContrast) < 1e-9 && ...
            abs(P.stimuliParameters.leftEyeContrast - stimuliParameters.leftEyeContrast) < 1e-9;
        if sameParams && isfield(P, 'pHouse')
            fprintf('Report-only test with the same contrasts (%s):\n', prev(iLatest).name);
            if isfield(P, 'counts'); printCounts(P.counts); end
            printRow('P(house) | HouseL+FaceR',    P.pHouse_HouseL);
            printRow('P(house) | FaceL+HouseR',    P.pHouse_HouseR);
            printRow('P(left-eye stimulus first)', P.pLeftEyeWins);
        end
    end
end
fprintf('(p = exact two-sided binomial test against 0.5; with ~20 trials per\n configuration only clear imbalances are detectable)\n');
fprintf('=================================================\n');
end


function printCounts(c)
pct = @(k, n) 100 * k / max(n, 1);
nA = c.HouseL + c.FaceR; nB = c.FaceL + c.HouseR;
fprintf('Perceived first (count; %% of the house/face responses in that configuration):\n');
fprintf('  HouseL+FaceR shown %3d x:  HouseL %3d (%3.0f%%) | FaceR  %3d (%3.0f%%) | mixed %d\n', ...
    c.shownHouseLFaceR, c.HouseL, pct(c.HouseL, nA), c.FaceR, pct(c.FaceR, nA), c.mixedHouseLFaceR);
fprintf('  FaceL+HouseR shown %3d x:  FaceL  %3d (%3.0f%%) | HouseR %3d (%3.0f%%) | mixed %d\n', ...
    c.shownFaceLHouseR, c.FaceL, pct(c.FaceL, nB), c.HouseR, pct(c.HouseR, nB), c.mixedFaceLHouseR);
fprintf('  per stimulus x eye: HouseL %d, FaceL %d, HouseR %d, FaceR %d\n', c.HouseL, c.FaceL, c.HouseR, c.FaceR);
fprintf('  totals: house %d, face %d | left eye %d, right eye %d | mixed %d\n\n', ...
    c.HouseL + c.HouseR, c.FaceL + c.FaceR, c.HouseL + c.FaceL, c.HouseR + c.FaceR, ...
    c.mixedHouseLFaceR + c.mixedFaceLHouseR);
end


function printRow(label, s)
fprintf('  %-28s %.3f  [%.2f %.2f]  (%d/%d, p = %.3f)\n', label, s.p, s.ci95, s.k, s.n, s.pValue);
end
