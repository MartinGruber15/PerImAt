function speedRunOnsetTest(log, ptb, design, participantInfo, myPaths)
% speedRunOnsetTest  Onset-rivalry test run with FIXED contrasts.
%
% Same trial procedure as speedRunOnset, but nothing is adapted: the four
% textures (FaceLeft, FaceRight, HouseLeft, HouseRight) keep the contrasts of
% the latest saved training file, i.e. the values you accepted at the end of
% speedRunOnset.  Use it to check whether those contrasts really give
% balanced house/face and left/right eye reports with few mixed percepts.
%
% Nothing is written to the training files.  A record of the run is saved as
% <sub>_onsetTest_<timestamp>.mat in the subject directory.

%% Settings
nTrials     = 40;    % total trials (~5.5 s each)
reportEvery = 10;    % print running proportions every N trials (0 = never)

%% Timing
design.instructionWaitDuration  = 0.5;
stimulusPresentationTime = 1.5 - ptb.ifi/2; % 1
ITI                      = 2 - ptb.ifi/2; % 5

%% Contrasts: latest training file (printed by loadLatestTrainingParameters)
stimuliParameters = loadLatestTrainingParameters(myPaths.subjectDirectory);
c.houseLeft  = stimuliParameters.houseContrast * stimuliParameters.leftEyeContrast;
c.houseRight = stimuliParameters.houseContrast * stimuliParameters.rightEyeContrast;
c.faceLeft   = stimuliParameters.faceContrast  * stimuliParameters.leftEyeContrast;
c.faceRight  = stimuliParameters.faceContrast  * stimuliParameters.rightEyeContrast;
fprintf('\nTest run with FIXED contrasts: FaceLeft %.3f | FaceRight %.3f | HouseLeft %.3f | HouseRight %.3f\n', ...
    c.faceLeft, c.faceRight, c.houseLeft, c.houseRight);

% Fixed adapted images, the pink-noise background is new in every trial
[rawHouse,~,maskHouse] = imread(fullfile(myPaths.stimuliLocation, 'house.png'));
[rawFace, ~,maskFace]  = imread(fullfile(myPaths.stimuliLocation, 'face.png'));
imgHouseL = generate.adaptImage(rawHouse, stimuliParameters.houseLuminance, c.houseLeft);
imgHouseR = generate.adaptImage(rawHouse, stimuliParameters.houseLuminance, c.houseRight);
imgFaceL  = generate.adaptImage(rawFace,  stimuliParameters.faceLuminance,  c.faceLeft);
imgFaceR  = generate.adaptImage(rawFace,  stimuliParameters.faceLuminance,  c.faceRight);

%% Empty arrays to save trial information
houseEye     = cell(nTrials,1);   % which eye the house was shown to: 'left'/'right'
faceEye      = cell(nTrials,1);   % which eye the face was shown to: 'left'/'right'
response     = cell(nTrials,1);   % what the participant reported: 'house'/'face'/'none'
perceivedEye = cell(nTrials,1);   % eye implied by the report: 'left'/'right'/'none'

% House left / house right are balanced within every group of 4 trials
houseLeftTrial = false(nTrials,1);
for k = 1:4:nTrials
    grp = [true true false false];
    grp = grp(randperm(4));
    nGrp = min(4, nTrials-k+1);
    houseLeftTrial(k:k+nGrp-1) = grp(1:nGrp);
end

display.stereo.alignFusion(ptb, participantInfo);

% Set up keyboard queue for collecting house/face responses.
KbQueueCreate;

grey = design.stimuli.grey_square;
trialStart = GetSecs();
for trial = 1:nTrials
    if houseLeftTrial(trial)
        houseTex = generate.makePinkNoiseTex(ptb.window, imgHouseL, maskHouse, design);
        faceTex  = generate.makePinkNoiseTex(ptb.window, imgFaceR,  maskFace,  design);
        stimuli = [houseTex, faceTex];
        houseEye{trial} = 'left';
        faceEye{trial}  = 'right';
    else
        faceTex  = generate.makePinkNoiseTex(ptb.window, imgFaceL,  maskFace,  design);
        houseTex = generate.makePinkNoiseTex(ptb.window, imgHouseR, maskHouse, design);
        stimuli = [faceTex, houseTex];
        houseEye{trial} = 'right';
        faceEye{trial}  = 'left';
    end
    draw.stereo.images(ptb,design,stimuli(1),stimuli(2));
    fliptime = Screen('Flip',ptb.window,trialStart+2);

    % Start listening for a response as soon as the stimulus is on screen.
    KbQueueFlush;
    KbQueueStart;

    [leftNoise, rightNoise] =generate.createStereoGaussianNoiseTextures(ptb, design);
    draw.stereo.textures(ptb, design, leftNoise, rightNoise);
    ITIOnset = Screen('Flip', ptb.window, fliptime+stimulusPresentationTime);

    % Response = whichever key was pressed first
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
        case 'face'
            perceivedEye{trial} = faceEye{trial};
        otherwise
            perceivedEye{trial} = 'none';
    end

    lastFlip = display.stereo.gaussianNoise(ptb,design,ITIOnset,ITI, leftNoise, rightNoise);
    draw.stereo.images(ptb,design, grey,grey);
    trialStart =Screen('Flip',ptb.window,lastFlip);
    Screen('Close', [houseTex, faceTex]);   % free the textures of this trial

    % running proportions (during the grey ITI)
    if reportEvery > 0 && mod(trial, reportEvery) == 0 && trial < nTrials
        s = summarize(response(1:trial), perceivedEye(1:trial));
        fprintf('Trial %3d/%d: house %3.0f%% | face %3.0f%% | left eye %3.0f%% | right eye %3.0f%% | mixed %3.0f%%\n', ...
            trial, nTrials, 100*s.pHouse, 100*(1-s.pHouse), 100*s.pLeft, 100*(1-s.pLeft), 100*s.pMixed);
    end
end

KbQueueRelease;

display.stereo.instruction(ptb, design,design.RunIsOver, design.instructionWaitDuration, false);

%% Result
s = summarize(response, perceivedEye);

fprintf('\n=================================================\n');
fprintf('        FIXED-CONTRAST TEST - RESULT (%d trials)\n', nTrials);
fprintf('=================================================\n');
fprintf('Contrasts: FaceLeft %.3f | FaceRight %.3f | HouseLeft %.3f | HouseRight %.3f\n', ...
    c.faceLeft, c.faceRight, c.houseLeft, c.houseRight);
fprintf('\nStimulus seen:  house %.1f%%  |  face %.1f%%  |  no response/mixed %.1f%%\n', ...
    100*s.pHouse*(1-s.pMixed), 100*(1-s.pHouse)*(1-s.pMixed), 100*s.pMixed);
if s.nAnswered > 0
    fprintf('Of %d answered trials (90%% interval in brackets):\n', s.nAnswered);
    [lo, hi] = wilson(s.nHouse, s.nAnswered);
    fprintf('  house %.1f%% [%.0f-%.0f]  |  face %.1f%%   -> %s\n', ...
        100*s.pHouse, 100*lo, 100*hi, 100*(1-s.pHouse), verdict(lo, hi, 'house', 'face'));
    [lo, hi] = wilson(s.nLeft, s.nAnswered);
    fprintf('  left eye %.1f%% [%.0f-%.0f]  |  right eye %.1f%%   -> %s\n', ...
        100*s.pLeft, 100*lo, 100*hi, 100*(1-s.pLeft), verdict(lo, hi, 'left eye', 'right eye'));
else
    fprintf('No responses recorded.\n');
end
fprintf('\nFaceLeftEye: %d | FaceRightEye: %d | HouseLeftEye: %d | HouseRightEye: %d\n', ...
    s.faceLeftEye, s.faceRightEye, s.houseLeftEye, s.houseRightEye);
fprintf('Mixed ("none") responses: %d of %d trials (%.0f%%)\n', s.nNone, nTrials, 100*s.pMixed);

%% Save a record of the run
subLabel = log.sub;
if isnumeric(subLabel); subLabel = num2str(subLabel); end
subLabel = char(subLabel);
testResult = struct('contrasts', c, 'stimuliParameters', stimuliParameters, ...
    'houseEye', {houseEye}, 'faceEye', {faceEye}, 'response', {response}, ...
    'perceivedEye', {perceivedEye}, 'summary', s);
testFile = fullfile(myPaths.subjectDirectory, ...
    sprintf('%s_onsetTest_%s.mat', subLabel, datestr(now,'yyyymmdd_HHMMSS')));
save(testFile, 'testResult');
fprintf('\nTest record saved to:\n%s\n', testFile);

log.end = 'Success'; %#ok<NASGU>

end


%% ============================================================
function s = summarize(response, perceivedEye)
s.nHouse = sum(strcmp(response,'house'));
s.nFace  = sum(strcmp(response,'face'));
s.nNone  = sum(strcmp(response,'none'));
s.nLeft  = sum(strcmp(perceivedEye,'left'));
s.nRight = sum(strcmp(perceivedEye,'right'));
s.nAnswered = s.nHouse + s.nFace;
s.pHouse = s.nHouse / max(s.nAnswered, 1);
s.pLeft  = s.nLeft  / max(s.nAnswered, 1);
s.pMixed = s.nNone / max(s.nAnswered + s.nNone, 1);
s.faceLeftEye   = sum(strcmp(response,'face')  & strcmp(perceivedEye,'left'));
s.faceRightEye  = sum(strcmp(response,'face')  & strcmp(perceivedEye,'right'));
s.houseLeftEye  = sum(strcmp(response,'house') & strcmp(perceivedEye,'left'));
s.houseRightEye = sum(strcmp(response,'house') & strcmp(perceivedEye,'right'));
end

function [lo, hi] = wilson(k, n)
% Wilson score interval for a proportion, 90% (z = 1.645)
z = 1.645;
p = k / n;
den = 1 + z^2 / n;
centre = (p + z^2 / (2*n)) / den;
half = z * sqrt(p*(1-p)/n + z^2/(4*n^2)) / den;
lo = centre - half;  hi = centre + half;
end

function txt = verdict(lo, hi, first, second)
if lo > 0.5
    txt = sprintf('%s dominates (50%% outside interval)', first);
elseif hi < 0.5
    txt = sprintf('%s dominates (50%% outside interval)', second);
else
    txt = 'balanced (50% inside interval)';
end
end
