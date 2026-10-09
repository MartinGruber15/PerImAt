function speedRunOnset(log, ptb, design, participantInfo,myPaths)
% speedRunOnset  Onset-rivalry run with ADAPTIVE (Bayesian) contrast optimisation.
%
% Every trial shows a house and a face, one to each eye, and the participant
% reports what they saw first: house, face, or something else ('none' = any
% other key = mixed percept).  While the run goes on, the contrasts of the
% four textures (FaceLeft, FaceRight, HouseLeft, HouseRight) are adapted so
% that
%   - house and face are reported equally often,
%   - the left-eye and right-eye stimulus are reported equally often.
%
% Contrast of a texture = stimulus contrast (house/face) x eye contrast
% (left/right), exactly as in getVisualDesignSettings.  The overall level
% (logLevel) stays at its start value (the latest saved training file); the
% optimiser adapts two numbers: the house/face ratio (logHouseFace) and the
% left/right ratio (logLeftRight), see +contrastBO/README.md.  The stored
% house, face, left-eye and right-eye contrasts are rounded to multiples of
% cfg.contrastStep (0.01, see defaultSettings): finer steps do not change the
% 8-bit image.  Mixed ("none") trials are counted and reported but carry no
% information about which stimulus is stronger, so they are left out of the
% balance model.
%
% The run ends after nTrials trials, or earlier when the stopping rule is met
% (flag useStopRule below).  At the end the contrast steps of all trials are
% plotted (and saved as .png next to the optimisation record), and the optimum
% is offered to input.adaptStimuli as default, so accepting it saves it as the
% next training file (used by the experiment).
%
% Which stimulus goes to which eye is NOT chosen by the model: house left /
% house right is a fixed, randomly shuffled sequence that is balanced within
% every group of 4 trials.  The model only chooses the contrasts.

%% Settings of the adaptive procedure
nTrials     = 240;   % MAXIMUM number of trials (~5.5 s each); the run is shorter if the stopping rule is met
reportEvery = 20;    % print dominance proportions / contrasts every N trials

% Stopping rule (sliding window).  After every trial the run checks the last
% `stopWindow` trials: it stops when, over that whole window,
%   - the 95% interval of the balance points (balanceHouseFace, balanceLeftRight)
%     was never wider than +-stopCI95 (ln units; half-width, about 1.96 x the
%     posterior SD), AND
%   - the best estimate of both balance points moved by no more than stopDrift.
% Never before stopMinTrials trials, and only after complete groups of 4
% trials (keeps house left / house right balanced).
useStopRule  = true;    % false: always run all nTrials trials
stopCI95     = 0.15;    % max. half-width of the 95% interval of both balance points  (0.15 ~ SD 0.077)
stopWindow   = 20;      % number of trials the criteria must hold for
stopDrift    = 0.10;    % max. change of the best estimate of the balance points inside the window
stopMinTrials = 60;     % never stop earlier than this
% Search range (cMin/cMax, max. ratio), contrast resolution and priors: contrastBO.defaultSettings

%% Timing
design.instructionWaitDuration  = 0.5;
stimulusPresentationTime = 1.5 - ptb.ifi/2;   % seconds the stimulus is shown
ITI                      = 2 - ptb.ifi/2;   % seconds of noise mask after the stimulus

%% Starting point = contrasts of the latest training file
stimuliParameters = loadLatestTrainingParameters(myPaths.subjectDirectory);
startLog = contrastBO.contrastsToParams(stimuliParameters.houseContrast, ...
    stimuliParameters.faceContrast, ...
    stimuliParameters.leftEyeContrast, ...
    stimuliParameters.rightEyeContrast);
cfg = contrastBO.defaultSettings(startLog);
rule = struct('minTrials', stopMinTrials, 'window', stopWindow, 'ci95', stopCI95, ...
    'drift', stopDrift, 'groupSize', 4);
stopHist = [];            % [trial, balanceHouseFace, balanceLeftRight, half-width of each 95% interval] after every trial
stoppedEarly = false;

% Raw stimulus images: contrast is re-applied for every trial
[rawHouse,~,maskHouse] = imread(fullfile(myPaths.stimuliLocation, 'house.png'));
[rawFace, ~,maskFace]  = imread(fullfile(myPaths.stimuliLocation, 'face.png'));

%% Empty arrays to save trial information
houseEye     = cell(nTrials,1);   % which eye the house was shown to: 'left'/'right'
faceEye      = cell(nTrials,1);   % which eye the face was shown to: 'left'/'right'
response     = cell(nTrials,1);   % what the participant reported: 'house'/'face'/'none'
perceivedEye = cell(nTrials,1);   % eye implied by the report: 'left'/'right'/'none'

trialLog       = nan(nTrials,3);      % [logLevel logHouseFace logLeftRight] of each trial (as really shown), see contrastBO.paramsToContrasts
shownContrast  = nan(nTrials,2);      % contrast of [house face] as shown in each trial
houseLeftTrial = false(nTrials,1);    % true: house shown to the left eye
report         = zeros(nTrials,1);    % 1 = house, 0 = face, -1 = none/mixed (saved as boResult.respCode)

% Eye assignment (house left / house right) is drawn here, BEFORE the run, and
% does not depend on the model or on the responses: every group of 4 trials
% contains 2x house-left and 2x house-right in random order.  This keeps stimulus bias and eye bias separable.
for k = 1:4:nTrials
    grp = [true true false false];
    grp = grp(randperm(4));
    nGrp = min(4, nTrials-k+1);
    houseLeftTrial(k:k+nGrp-1) = grp(1:nGrp);
end

display.stereo.alignFusion(ptb, participantInfo);
%display.stereo.instruction(ptb,design, design.Introduction, design.instructionWaitDuration, false);

% Set up keyboard queue for collecting house/face responses.
% Adjust the device index here (e.g. KbQueueCreate(ptb.keyboardIndex))
% if your setup targets a specific keyboard device.
KbQueueCreate;

grey = design.stimuli.grey_square;
fprintf('\nStarting adaptive contrast run: %d trials, report every %d.\n', nTrials, reportEvery);
cStart = contrastBO.quantiseContrasts(cfg.startLog, cfg);
fprintf('Level (logLevel) fixed at its start value; contrasts rounded to steps of %.2f, range %.2f-%.2f.\n', cfg.contrastStep, cfg.cMin, cfg.cMax);
if useStopRule
    fprintf('Stopping rule: 95%% interval of both balance points within +-%.2f and best estimate moving <= %.2f over %d trials (not before trial %d, max. %d trials).\n', ...
        stopCI95, stopDrift, stopWindow, stopMinTrials, nTrials);
else
    fprintf('No stopping rule: all %d trials are run.\n', nTrials);
end
fprintf('Start contrasts: FaceLeft %.2f | FaceRight %.2f | HouseLeft %.2f | HouseRight %.2f\n', ...
    cStart.faceLeft, cStart.faceRight, cStart.houseLeft, cStart.houseRight);

%% Timing record
fprintf('Pause: noise mask %.1f s, plus 2 s grey before every stimulus.\n', ITI + ptb.ifi/2);
stimOnsetTime  = nan(nTrials,1);   % time at which the stimulus appeared in each trial
stimOffsetTime = nan(nTrials,1);   % time at which it was replaced by the noise mask

% Loop trough all trials
trialStart = GetSecs();
nMaxTrials = nTrials;
nDone = nTrials;
for trial = 1:nTrials
    %% 1. Choose the contrasts for this trial (Bayesian optimisation step)
    if trial == 1
        logContrast = cfg.startLog;              % first trial: start values
    else
        model = contrastBO.fitModels(trialLog(1:trial-1,:), ...
            houseLeftTrial(1:trial-1), report(1:trial-1), cfg);
        if useStopRule
            [stopNow, stopInfo, stopHist] = contrastBO.stopCheck(model, cfg, rule, stopHist, trial-1);
            if stopNow
                nDone = trial - 1;  stoppedEarly = true;
                fprintf('\n*** Stopping rule met after %d trials: balanceHouseFace = %.3f (95%% +-%.3f), balanceLeftRight = %.3f (95%% +-%.3f); drift over the last %d trials: %.3f / %.3f. ***\n', ...
                    nDone, stopInfo.balanceHouseFace, stopInfo.houseFaceHalf, stopInfo.balanceLeftRight, stopInfo.leftRightHalf, ...
                    stopWindow, stopInfo.driftHouseFace, stopInfo.driftLeftRight);
                break
            end
        end
        logContrast = contrastBO.chooseParams(model, cfg, 'sample');   % Thompson sampling
    end
    [c, logContrast] = contrastBO.quantiseContrasts(logContrast, cfg);   % contrasts as shown (steps of cfg.contrastStep); logContrast = their log values
    trialLog(trial,:) = logContrast;

    %% 2. Eye-specific textures with these contrasts
    if houseLeftTrial(trial)
        houseImg = generate.adaptImage(rawHouse, stimuliParameters.houseLuminance, c.houseLeft);
        faceImg  = generate.adaptImage(rawFace,  stimuliParameters.faceLuminance,  c.faceRight);
        houseTex = generate.makePinkNoiseTex(ptb.window, houseImg, maskHouse, design);
        faceTex  = generate.makePinkNoiseTex(ptb.window, faceImg,  maskFace,  design);
        stimuli = [houseTex, faceTex];
        houseEye{trial} = 'left';
        faceEye{trial}  = 'right';
        shownContrast(trial,:) = [c.houseLeft, c.faceRight];
    else
        faceImg  = generate.adaptImage(rawFace,  stimuliParameters.faceLuminance,  c.faceLeft);
        houseImg = generate.adaptImage(rawHouse, stimuliParameters.houseLuminance, c.houseRight);
        faceTex  = generate.makePinkNoiseTex(ptb.window, faceImg,  maskFace,  design);
        houseTex = generate.makePinkNoiseTex(ptb.window, houseImg, maskHouse, design);
        stimuli = [faceTex, houseTex];
        houseEye{trial} = 'right';
        faceEye{trial}  = 'left';
        shownContrast(trial,:) = [c.houseRight, c.faceLeft];
    end
    pairIndex = randi(size(design.fixDotValidPairs, 1));
    selectedPair = design.fixDotValidPairs(pairIndex, :);
    draw.stereo.images(ptb,design,stimuli(1),stimuli(2));
    fliptime = Screen('Flip',ptb.window,trialStart+2);

    % Start listening for a response as soon as the stimulus is on screen.
    KbQueueFlush;
    KbQueueStart;

    [leftNoise, rightNoise] =generate.createStereoGaussianNoiseTextures(ptb, design);
    draw.stereo.textures(ptb, design, leftNoise, rightNoise);
    ITIOnset = Screen('Flip', ptb.window, fliptime+stimulusPresentationTime);
    stimOnsetTime(trial)  = fliptime;
    stimOffsetTime(trial) = ITIOnset;

    % Stop listening once the stimulus presentation window has ended and
    % find the participant's response (whichever key was pressed first).
    while true
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            break;
        end
    end
    pressedKey = find(keyCode, 1);
    if pressedKey==ptb.Keys.house;response{trial}='house';elseif pressedKey==ptb.Keys.face;response{trial}='face';else;response{trial}='none'; end

    switch response{trial}
        case 'house'
            perceivedEye{trial} = houseEye{trial};
            report(trial) = 1;
        case 'face'
            perceivedEye{trial} = faceEye{trial};
            report(trial) = 0;
        otherwise
            perceivedEye{trial} = 'none';
            report(trial) = -1;
    end

    lastFlip = display.stereo.gaussianNoise(ptb,design,ITIOnset,ITI, leftNoise, rightNoise);
    draw.stereo.images(ptb,design, grey,grey);
    trialStart =Screen('Flip',ptb.window,lastFlip);
    Screen('Close', [houseTex, faceTex]);   % free the textures of this trial

    %% 3. Progress report every reportEvery trials (during the grey ITI)
    if mod(trial, reportEvery) == 0 && trial < nTrials
        reportProgress(trial, reportEvery, cfg, trialLog, houseLeftTrial, report, stopCI95);
    end

end

KbQueueRelease;

% shorten all records if the stopping rule ended the run early
if nDone < nTrials
    keep = 1:nDone;
    houseEye = houseEye(keep);  faceEye = faceEye(keep);
    response = response(keep);  perceivedEye = perceivedEye(keep);
    trialLog = trialLog(keep,:);  shownContrast = shownContrast(keep,:);
    houseLeftTrial = houseLeftTrial(keep);  report = report(keep);
    stimOnsetTime = stimOnsetTime(keep);  stimOffsetTime = stimOffsetTime(keep);
end
nTrials = nDone;

display.stereo.instruction(ptb, design,design.RunIsOver, design.instructionWaitDuration, false);

%% Final optimum: most probable parameters given all trials
model  = contrastBO.fitModels(trialLog, houseLeftTrial, report, cfg);
[finalLog, shrinkInfo] = contrastBO.chooseParams(model, cfg, 'map');
[cFinal, finalLog] = contrastBO.quantiseContrasts(finalLog, cfg);   % rounded to steps of cfg.contrastStep
pred   = contrastBO.predictAt(model, finalLog, cfg, 2000, 0.95);

fprintf('\n=================================================\n');
fprintf('        ADAPTIVE CONTRAST RUN - RESULT\n');
fprintf('=================================================\n');
reportProgress(nTrials, reportEvery, cfg, trialLog, houseLeftTrial, report, stopCI95);
fprintf('\nFinal contrasts (one per texture; house, face, left-eye and right-eye contrast are rounded to steps of %.2f):\n', cfg.contrastStep);
fprintf('  FaceLeft:   %.4f\n', cFinal.faceLeft);
fprintf('  FaceRight:  %.4f\n', cFinal.faceRight);
fprintf('  HouseLeft:  %.4f\n', cFinal.houseLeft);
fprintf('  HouseRight: %.4f\n', cFinal.houseRight);
fprintf('  (= stimulus contrast: house %.4f, face %.4f  x  eye contrast: left %.4f, right %.4f)\n', ...
    cFinal.houseContrast, cFinal.faceContrast, cFinal.leftEyeContrast, cFinal.rightEyeContrast);
fprintf('  Model expects at these contrasts: house %.0f%% | left eye %.0f%% | mixed %.0f%%\n', ...
    100*pred.pHouse, 100*pred.pLeft, 100*pred.pMixed);
fprintf('  Balance points: balanceHouseFace = %.3f (95%% interval %.3f to %.3f), balanceLeftRight = %.3f (95%% interval %.3f to %.3f)\n', ...
    shrinkInfo.wanted(1), pred.houseFaceCI(1), pred.houseFaceCI(2), shrinkInfo.wanted(2), pred.leftRightCI(1), pred.leftRightCI(2));
if stoppedEarly
    fprintf('  The run was ended by the stopping rule after %d of max. %d trials.\n', nTrials, nMaxTrials);
elseif useStopRule
    fprintf(2, '  The stopping rule was NOT met within %d trials (95%% half-widths now %.3f / %.3f, limit %.2f).\n', ...
        nTrials, pred.houseFaceHalf, pred.leftRightHalf, stopCI95);
end
printShrinkWarning(shrinkInfo, cfg);
atLimit = abs(finalLog(2)) > cfg.maxLogRatio - 0.02 || abs(finalLog(3)) > cfg.maxLogRatio - 0.02;
if atLimit
    fprintf(2, 'WARNING: a balance point reached the limit of the search range (factor %.1f).\n', exp(cfg.maxLogRatio));
end
if pred.pMixed > 0.3
    fprintf(2, 'WARNING: the model still expects many mixed percepts (%.0f%%).\n', 100*pred.pMixed);
end

%% Print summary of what was reported (all trials, contrasts changed during the run!)
nHouse = sum(strcmp(response,'house'));
nFace  = sum(strcmp(response,'face'));
nNone  = sum(strcmp(response,'none'));

fprintf('\n--- Response summary, all %d trials (contrasts varied during the run) ---\n', nTrials);
fprintf('Stimulus seen:  house %.1f%%  |  face %.1f%%  |  no response %.1f%%\n', ...
    100*nHouse/nTrials, 100*nFace/nTrials, 100*nNone/nTrials);

nLeft  = sum(strcmp(perceivedEye,'left'));
nRight = sum(strcmp(perceivedEye,'right'));
nAnswered = nLeft + nRight;
if nAnswered > 0
    fprintf('Eye perceived (of %d trials with a response):  left %.1f%%  |  right %.1f%%\n', ...
        nAnswered, 100*nLeft/nAnswered, 100*nRight/nAnswered);
else
    fprintf('Eye perceived: no responses recorded.\n');
end

faceLeftEye   = sum(strcmp(response,'face')  & strcmp(perceivedEye,'left'));
faceRightEye  = sum(strcmp(response,'face')  & strcmp(perceivedEye,'right'));
houseLeftEye  = sum(strcmp(response,'house') & strcmp(perceivedEye,'left'));
houseRightEye = sum(strcmp(response,'house') & strcmp(perceivedEye,'right'));
fprintf('FaceLeftEye: %d | FaceRightEye: %d | HouseLeftEye: %d | HouseRightEye: %d\n', ...
    faceLeftEye, faceRightEye, houseLeftEye, houseRightEye);

%% Save the full optimisation record and offer the optimum for the experiment
subLabel = log.sub;
if isnumeric(subLabel); subLabel = num2str(subLabel); end
subLabel = char(subLabel);
% pause between the end of the previous stimulus and the start of this one (s)
pauseBefore = [NaN; stimOnsetTime(2:end) - stimOffsetTime(1:end-1)];
% (field names are kept for the analysis scripts: trialParams = trialLog, respCode = report, finalParams = finalLog)
boResult = struct('cfg', cfg, 'trialParams', trialLog, 'shownContrast', shownContrast, ...
    'houseLeft', houseLeftTrial, 'response', {response}, 'respCode', report, ...
    'model', model, 'finalParams', finalLog, 'finalContrasts', cFinal, 'prediction', pred, ...
    'finalShrink', shrinkInfo, 'pauseBefore', pauseBefore, 'stopRule', rule, 'useStopRule', useStopRule, ...
    'stoppedEarly', stoppedEarly, 'maxTrials', nMaxTrials, 'stopHistory', stopHist);
boFile = fullfile(myPaths.subjectDirectory, ...
    sprintf('%s_onsetBO_%s.mat', subLabel, datestr(now,'yyyymmdd_HHMMSS')));
save(boFile, 'boResult');
fprintf('\nOptimisation record saved to:\n%s\n', boFile);

% Visualise the contrast steps of the run.  The Psychtoolbox window is closed
% first, otherwise it covers the figure.
Screen('CloseAll');
ListenChar(1);
fig = contrastBO.plotSteps(trialLog, report, houseLeftTrial, cfg, finalLog);
figFile = [boFile(1:end-4) '.png'];
try
    saveas(fig, figFile);
    fprintf('Contrast-step figure saved to:\n%s\n', figFile);
catch
    fprintf('Could not save the contrast-step figure automatically.\n');
end

log.end = 'Success';
log.response     = response;
log.houseEye     = houseEye;
log.faceEye      = faceEye;
log.perceivedEye = perceivedEye;
log.trialParams  = trialLog;
log.shownContrast = shownContrast;

% The optimised values become the defaults of adaptStimuli: press Enter for
% every prompt and confirm with Y to save them as the next training file
% (or type other values to override them).
finalParameters = struct( ...
    'houseContrast',    cFinal.houseContrast, ...
    'faceContrast',     cFinal.faceContrast, ...
    'leftEyeContrast',  cFinal.leftEyeContrast, ...
    'rightEyeContrast', cFinal.rightEyeContrast);
input.adaptStimuli(log,myPaths,finalParameters);

end


%% ============================================================
function reportProgress(trial, reportEvery, cfg, trialLog, houseLeft, report, ci95Limit)
% Observed dominance proportions and current best contrast estimate.

idxAll = 1:trial;
idxRec = max(1, trial-reportEvery+1):trial;
[hA, lA, mA] = observedShares(report(idxAll), houseLeft(idxAll));
[hR, lR, mR] = observedShares(report(idxRec), houseLeft(idxRec));

model = contrastBO.fitModels(trialLog(idxAll,:), houseLeft(idxAll), report(idxAll), cfg);
[best, shr] = contrastBO.chooseParams(model, cfg, 'map');
c  = contrastBO.quantiseContrasts(best, cfg);
pr = contrastBO.predictAt(model, best, cfg, 1500, 0.95);

fprintf('\n--- Trial %d: progress ---------------------------------\n', trial);
fprintf('Last %2d trials: house %3.0f%% | face %3.0f%% | left eye %3.0f%% | right eye %3.0f%% | mixed %3.0f%%\n', ...
    numel(idxRec), 100*hR, 100*(1-hR), 100*lR, 100*(1-lR), 100*mR);
fprintf('All trials   : house %3.0f%% | face %3.0f%% | left eye %3.0f%% | right eye %3.0f%% | mixed %3.0f%%  (contrasts varied)\n', ...
    100*hA, 100*(1-hA), 100*lA, 100*(1-lA), 100*mA);
% observed responses per eye assignment (all trials so far)
for pairA = [true false]
    sel = houseLeft(idxAll) == pairA;
    r = report(idxAll);  r = r(sel);
    if pairA, nm = 'HouseLeft /FaceRight'; else, nm = 'HouseRight/FaceLeft '; end
    fprintf('Trials %s: %3d | house %3d | face %3d | mixed %3d\n', ...
        nm, numel(r), sum(r == 1), sum(r == 0), sum(r < 0));
end
fprintf('Best estimate: FaceLeft %.2f | FaceRight %.2f | HouseLeft %.2f | HouseRight %.2f\n', ...
    c.faceLeft, c.faceRight, c.houseLeft, c.houseRight);
fprintf('Model expects: house %3.0f%% | left eye %3.0f%% | mixed %3.0f%%\n', ...
    100*pr.pHouse, 100*pr.pLeft, 100*pr.pMixed);
fprintf('Balance points: balanceHouseFace = %.3f +-%.3f, balanceLeftRight = %.3f +-%.3f (95%% half-width; stopping limit +-%.2f)  [contrast ratios house/face %.2f-%.2f, left/right %.2f-%.2f]\n', ...
    best(2), pr.houseFaceHalf, best(3), pr.leftRightHalf, ci95Limit, exp(pr.houseFaceCI(1)), exp(pr.houseFaceCI(2)), exp(pr.leftRightCI(1)), exp(pr.leftRightCI(2)));
printShrinkWarning(shr, cfg);
end

function printShrinkWarning(info, cfg)
% Warn if the balance point does not fit into cMin..cMax at the start level.
if info.clipped
    fprintf(2, 'WARNING: a balance point reached the maximum ratio of %.1f (maxLogRatio); the estimate is cut off there.\n', exp(cfg.maxLogRatio));
end
if ~info.shrunk, return; end
logLevel = cfg.startLog(1);
if strcmp(info.limit, 'cMax')
    lim = sprintf('the strongest texture would exceed cMax = %.2f', cfg.cMax);
else
    lim = sprintf('the weakest texture would fall below cMin = %.2f', cfg.cMin);
end
fprintf(2, ['WARNING: contrast range too small for the balance point. It asks for balanceHouseFace = %.2f, balanceLeftRight = %.2f ' ...
    '(|logHouseFace|+|logLeftRight| = %.2f), but at the fixed start level (geometric mean of the four contrasts %.2f) only %.2f fits: %s.\n' ...
    '         Both were scaled by %.2f to logHouseFace = %.2f, logLeftRight = %.2f, so the percepts will not be fully balanced. ' ...
    'Widen cMin/cMax in defaultSettings, or start from a level near %.2f (geometric mean of cMin and cMax), which leaves the most room.\n'], ...
    info.wanted(1), info.wanted(2), info.needSum, exp(logLevel), info.roomSum, lim, info.factor, ...
    info.used(1), info.used(2), sqrt(cfg.cMin * cfg.cMax));
end

function [pHouse, pLeft, pMixed] = observedShares(report, houseLeft)
% Shares of house / left-eye among answered trials, and of mixed among all
isAns = report >= 0;
nAns = sum(isAns);
pMixed = mean(report < 0);
if nAns == 0
    pHouse = NaN;  pLeft = NaN;  return
end
pHouse = sum(report == 1) / nAns;
leftReported = (report == 1 & houseLeft(:)) | (report == 0 & ~houseLeft(:));
pLeft = sum(leftReported) / nAns;
end
