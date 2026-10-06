function participantInfo = speedRunOnset(log, ptb, design, participantInfo,myPaths)
% speedRunOnset  Onset-rivalry run with ADAPTIVE (Bayesian) contrast optimisation.
%
% Every trial shows a house and a face, one to each eye, and the participant
% reports what they saw first: house, face, or something else ('none' = any
% other key = mixed percept).  While the run goes on, the contrasts of the
% four textures (FaceLeft, FaceRight, HouseLeft, HouseRight) are adapted so
% that
%   - house and face are reported equally often,
%   - the left-eye and right-eye stimulus are reported equally often,
%   - as few mixed ("none") percepts as possible occur.
%
% Contrast of a texture = stimulus contrast (house/face) x eye contrast
% (left/right), exactly as in getVisualDesignSettings.  The optimiser works
% with three numbers: overall level, house/face ratio, left/right ratio
% (see +contrastBO).  The starting point is the latest saved training file.
% At the end the contrast steps of all trials are plotted (and saved as .png
% next to the optimisation record), and the optimum is offered to
% input.adaptStimuli as default, so accepting it saves it as the next training
% file (used by the experiment).
%
% Two models can be used (flag useConfigModel below):
%   false : overall level + house/face ratio + left/right ratio (3 numbers)
%   true  : the two stimulus configurations (house left + face right = pair A,
%           house right + face left = pair B) are modelled separately, so all
%           four textures can get an individual contrast.  Each pair has its
%           own balance curve and mixed-percept curve, and its own level.
%
% Which stimulus goes to which eye is NOT chosen by the model: house left /
% house right is a fixed, randomly shuffled sequence that is balanced within
% every group of 4 trials (exactly 50% each over the run).  The model only
% chooses the contrasts.

%% Settings of the adaptive procedure
useConfigModel = true;   % true : contrast of each of the 4 textures is adapted individually
                         %        (separate model per stimulus configuration)
                         % false: previous model (overall level, house/face ratio, left/right ratio)
levelMode = 'mixed';     % what decides the overall contrast level g (and with the config model the pair levels):
                         % 'mixed'  : level with the fewest expected mixed percepts (previous behaviour)
                         % 'balance': mixed percepts ignored; level where the differences needed for balance are smallest
                         % 'fixed'  : level stays at its start value, only the ratios/differences are adapted
nTrials     = 120;   % total trials (~5.5 s each; more trials = more precise)
reportEvery = 20;    % print dominance proportions / contrasts every N trials
% Search range (cMin/cMax, max. ratio) and priors: contrastBO.defaultSettings

%% Timing
design.instructionWaitDuration  = 0.5;
stimulusPresentationTime = 1.5 - ptb.ifi/2; % 1
ITI                      = 2 - ptb.ifi/2; % 5

%% Starting point = contrasts of the latest training file
stimuliParameters = loadLatestTrainingParameters(myPaths.subjectDirectory);
x0 = contrastBO.contrastsToParams(stimuliParameters.houseContrast, ...
    stimuliParameters.faceContrast, ...
    stimuliParameters.leftEyeContrast, ...
    stimuliParameters.rightEyeContrast, ...
    stimuliParameters.configContrast);
if useConfigModel
    cfg = contrastBO.defaultSettings(x0, 'perConfig', levelMode);
else
    cfg = contrastBO.defaultSettings(x0, 'shared', levelMode);
end

% Raw stimulus images: contrast is re-applied for every trial
[rawHouse,~,maskHouse] = imread(fullfile(myPaths.stimuliLocation, 'house.png'));
[rawFace, ~,maskFace]  = imread(fullfile(myPaths.stimuliLocation, 'face.png'));

%% Empty arrays to save trial information
houseEye     = cell(nTrials,1);   % which eye the house was shown to: 'left'/'right'
faceEye      = cell(nTrials,1);   % which eye the face was shown to: 'left'/'right'
response     = cell(nTrials,1);   % what the participant reported: 'house'/'face'/'none'
perceivedEye = cell(nTrials,1);   % eye implied by the report: 'left'/'right'/'none'

trialParams    = nan(nTrials,cfg.nParams);   % [g s e] ([g s e i] with the config model) of each trial, see contrastBO.paramsToContrasts
shownContrast  = nan(nTrials,2);      % contrast of [house face] as shown in each trial
houseLeftTrial = false(nTrials,1);    % true: house shown to the left eye
respCode       = zeros(nTrials,1);    % 1 = house, 0 = face, -1 = none/mixed

% Eye assignment (house left / house right) is drawn here, BEFORE the run, and
% does not depend on the model or on the responses: every group of 4 trials
% contains 2x house-left and 2x house-right in random order (nTrials = 120 ->
% exactly 60 / 60).  This keeps stimulus bias and eye bias separable.
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
cStart = contrastBO.paramsToContrasts(cfg.center, cfg.i0);
fprintf('Model: %s | level rule: %s\n', cfg.mode, cfg.levelMode);
fprintf('Start contrasts: FaceLeft %.2f | FaceRight %.2f | HouseLeft %.2f | HouseRight %.2f\n', ...
    cStart.faceLeft, cStart.faceRight, cStart.houseLeft, cStart.houseRight);

% Loop trough all trials
trialStart = GetSecs();
for trial = 1:nTrials
    %% 1. Choose the contrasts for this trial (Bayesian optimisation step)
    if trial == 1
        x = cfg.center;                          % first trial: start values
    else
        model = contrastBO.fitModels(trialParams(1:trial-1,:), ...
            houseLeftTrial(1:trial-1), respCode(1:trial-1), cfg);
        x = contrastBO.chooseParams(model, cfg, 'sample');   % Thompson sampling
    end
    c = contrastBO.paramsToContrasts(x, cfg.i0);
    trialParams(trial,:) = x;

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
            respCode(trial) = 1;
        case 'face'
            perceivedEye{trial} = faceEye{trial};
            respCode(trial) = 0;
        otherwise
            perceivedEye{trial} = 'none';
            respCode(trial) = -1;
    end

    lastFlip = display.stereo.gaussianNoise(ptb,design,ITIOnset,ITI, leftNoise, rightNoise);
    draw.stereo.images(ptb,design, grey,grey);
    trialStart =Screen('Flip',ptb.window,lastFlip);
    Screen('Close', [houseTex, faceTex]);   % free the textures of this trial

    %% 3. Progress report every reportEvery trials (during the grey ITI)
    if mod(trial, reportEvery) == 0 && trial < nTrials
        reportProgress(trial, reportEvery, cfg, trialParams, houseLeftTrial, respCode);
    end

end

KbQueueRelease;

display.stereo.instruction(ptb, design,design.RunIsOver, design.instructionWaitDuration, false);

%% Final optimum: most probable parameters given all trials
model  = contrastBO.fitModels(trialParams, houseLeftTrial, respCode, cfg);
xFinal = contrastBO.chooseParams(model, cfg, 'map');
cFinal = contrastBO.paramsToContrasts(xFinal, cfg.i0);
pred   = contrastBO.predictAt(model, xFinal, cfg);

fprintf('\n=================================================\n');
fprintf('        ADAPTIVE CONTRAST RUN - RESULT\n');
fprintf('=================================================\n');
reportProgress(nTrials, reportEvery, cfg, trialParams, houseLeftTrial, respCode);
fprintf('\nFinal contrasts (one per texture):\n');
fprintf('  FaceLeft:   %.4f\n', cFinal.faceLeft);
fprintf('  FaceRight:  %.4f\n', cFinal.faceRight);
fprintf('  HouseLeft:  %.4f\n', cFinal.houseLeft);
fprintf('  HouseRight: %.4f\n', cFinal.houseRight);
fprintf('  (= stimulus contrast: house %.4f, face %.4f  x  eye contrast: left %.4f, right %.4f  x configuration contrast %.4f for pair HouseLeft/FaceRight, / for pair HouseRight/FaceLeft)\n', ...
    cFinal.houseContrast, cFinal.faceContrast, cFinal.leftEyeContrast, cFinal.rightEyeContrast, cFinal.configContrast);
fprintf('  Model expects at these contrasts: house %.0f%% | left eye %.0f%% | mixed %.0f%%\n', ...
    100*pred.pHouse, 100*pred.pLeft, 100*pred.pMixed);
if strcmp(cfg.mode, 'perConfig')
    fprintf('  Pair HouseLeft/FaceRight : house %.0f%% of answered, mixed %.0f%%\n', 100*pred.pA, 100*pred.mixA);
    fprintf('  Pair HouseRight/FaceLeft : house %.0f%% of answered, mixed %.0f%%\n', 100*pred.pB, 100*pred.mixB);
end
atLimit = strcmp(cfg.mode, 'shared') && (abs(xFinal(2)) > cfg.maxLogRatio - 0.02 || abs(xFinal(3)) > cfg.maxLogRatio - 0.02);
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
boResult = struct('mode', cfg.mode, 'cfg', cfg, 'trialParams', trialParams, 'shownContrast', shownContrast, ...
    'houseLeft', houseLeftTrial, 'response', {response}, 'respCode', respCode, ...
    'model', model, 'finalParams', xFinal, 'finalContrasts', cFinal, 'prediction', pred);
boFile = fullfile(myPaths.subjectDirectory, ...
    sprintf('%s_onsetBO_%s.mat', subLabel, datestr(now,'yyyymmdd_HHMMSS')));
save(boFile, 'boResult');
fprintf('\nOptimisation record saved to:\n%s\n', boFile);

% Visualise the contrast steps of the run.  The Psychtoolbox window is closed
% first, otherwise it covers the figure.
Screen('CloseAll');
ListenChar(1);
fig = contrastBO.plotSteps(trialParams, respCode, houseLeftTrial, cfg, xFinal);
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
log.trialParams  = trialParams;
log.shownContrast = shownContrast;

% The optimised values become the defaults of adaptStimuli: press Enter for
% every prompt and confirm with Y to save them as the next training file
% (or type other values to override them).
finalParameters = struct( ...
    'houseContrast',    cFinal.houseContrast, ...
    'faceContrast',     cFinal.faceContrast, ...
    'leftEyeContrast',  cFinal.leftEyeContrast, ...
    'rightEyeContrast', cFinal.rightEyeContrast, ...
    'configContrast',   cFinal.configContrast);
input.adaptStimuli(log,myPaths,finalParameters);

end


%% ============================================================
function reportProgress(trial, reportEvery, cfg, trialParams, houseLeft, respCode)
% Observed dominance proportions and current best contrast estimate.

idxAll = 1:trial;
idxRec = max(1, trial-reportEvery+1):trial;
[hA, lA, mA] = observedShares(respCode(idxAll), houseLeft(idxAll));
[hR, lR, mR] = observedShares(respCode(idxRec), houseLeft(idxRec));

model = contrastBO.fitModels(trialParams(idxAll,:), houseLeft(idxAll), respCode(idxAll), cfg);
xb = contrastBO.chooseParams(model, cfg, 'map');
c  = contrastBO.paramsToContrasts(xb, cfg.i0);
pr = contrastBO.predictAt(model, xb, cfg);

fprintf('\n--- Trial %d: progress ---------------------------------\n', trial);
fprintf('Last %2d trials: house %3.0f%% | face %3.0f%% | left eye %3.0f%% | right eye %3.0f%% | mixed %3.0f%%\n', ...
    numel(idxRec), 100*hR, 100*(1-hR), 100*lR, 100*(1-lR), 100*mR);
fprintf('All trials   : house %3.0f%% | face %3.0f%% | left eye %3.0f%% | right eye %3.0f%% | mixed %3.0f%%  (contrasts varied)\n', ...
    100*hA, 100*(1-hA), 100*lA, 100*(1-lA), 100*mA);
% observed responses per stimulus configuration (all trials so far)
for pairA = [true false]
    sel = houseLeft(idxAll) == pairA;
    r = respCode(idxAll);  r = r(sel);
    if pairA, nm = 'HouseLeft /FaceRight'; else, nm = 'HouseRight/FaceLeft '; end
    fprintf('Pair %s: %3d trials | house %3d | face %3d | mixed %3d\n', ...
        nm, numel(r), sum(r == 1), sum(r == 0), sum(r < 0));
end
fprintf('Best estimate: FaceLeft %.2f | FaceRight %.2f | HouseLeft %.2f | HouseRight %.2f\n', ...
    c.faceLeft, c.faceRight, c.houseLeft, c.houseRight);
if strcmp(cfg.mode, 'perConfig')
    fprintf('Model expects: house %3.0f%% | left eye %3.0f%% | mixed %3.0f%%   (pair A mixed %.0f%%, pair B mixed %.0f%%)\n', ...
        100*pr.pHouse, 100*pr.pLeft, 100*pr.pMixed, 100*pr.mixA, 100*pr.mixB);
    fprintf('               balance point 90%% range, house/face contrast ratio: pair A %.2f-%.2f | pair B %.2f-%.2f\n', ...
        exp(pr.dACI(1)), exp(pr.dACI(2)), exp(pr.dBCI(1)), exp(pr.dBCI(2)));
else
    fprintf('Model expects: house %3.0f%% | left eye %3.0f%% | mixed %3.0f%%   (balance point 90%% range: house/face contrast ratio %.2f-%.2f, left/right %.2f-%.2f)\n', ...
        100*pr.pHouse, 100*pr.pLeft, 100*pr.pMixed, exp(pr.sCI(1)), exp(pr.sCI(2)), exp(pr.eCI(1)), exp(pr.eCI(2)));
end
end

function [pHouse, pLeft, pMixed] = observedShares(respCode, houseLeft)
% Shares of house / left-eye among answered trials, and of mixed among all
isAns = respCode >= 0;
nAns = sum(isAns);
pMixed = mean(respCode < 0);
if nAns == 0
    pHouse = NaN;  pLeft = NaN;  return
end
pHouse = sum(respCode == 1) / nAns;
leftReported = (respCode == 1 & houseLeft(:)) | (respCode == 0 & ~houseLeft(:));
pLeft = sum(leftReported) / nAns;
end
