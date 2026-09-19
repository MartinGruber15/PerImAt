function log = trialProcedurePerImAtOnline(log, design, ptb, myPaths, stimLookupTable, trialSequence, rows)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Funktion to display and handle the trial sequence determined in
% onsetRivalryBrascamp and collect the corresponding data.
% 
% Procedure of a trial: a image of a face or a house will be flashed with
% reduced contrast on both eyes, then a rivalry of face and house is shown.
% The flashed image can be the same as one of the stimuli used in the 
% rivalry (congruent case) or a different one (incongruent case). 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Disable input to matlab windows
%ListenChar(2);

%% Stop and remove events in queue
KbQueueStop(ptb.Keyboard2);
KbEventFlush(ptb.Keyboard2);
KbQueueStop(ptb.Keyboard1);
KbEventFlush(ptb.Keyboard1);

% restart KbQueues
KbQueueStart(ptb.Keyboard2); % Subjects
KbQueueStart(ptb.Keyboard1); % Experimentors

%rows = height(trialSequence);

%% Presentation of stimuli
log.ExperimentStart = GetSecs();
trialStartTime = log.ExperimentStart;
prevCondition = "";
remindAssociation = true;

% Loop trough all trials
for trial = 1:rows
    KbQueueFlush(ptb.Keyboard2);
    events = struct('Time', {}, 'Keycode', {});
    %% Determine the stimuli for the current trial
    % Extract trialID and load stimuli
    trialID   = trialSequence.trialID(trial);
    condition = trialSequence.condition(trial);

    isCatch = contains(condition, "_catch_");
    %identify catch trials
    if isCatch
        catchCondition = condition;
        condition = extractBefore(catchCondition, "_catch_");
        catchType  = extractAfter(catchCondition, "_catch_");
    else
        catchType = "";
    end

    %trialStim = setUpStimuli(trialID, stimLookupTable, myPaths, design, condition);
    trialStim = setUpStimuliButInGreyShadesThisTime(trialID, stimLookupTable, myPaths, design, condition, catchType, log.reportCond);
    if prevCondition ~= condition
        remindAssociation = true;
        prevCondition = condition; % Update previous condition for the next trial
    end    

    %% Trial Procedure
    % Draw the cue
    if remindAssociation
        draw.stereo.fixCrossPlusLegend(ptb, design, trialStim.cueTxt, trialStim.fixCrossColor);
        remindAssociation = false;
        cueDuration = design.cueDuration + 2; % first cue of miniblock is longer
    else
        draw.stereo.fixCrossPlusText(ptb, design,trialStim.cueTxt, trialStim.fixCrossColor);
        cueDuration = design.cueDuration;
    end
    cueOnset = Screen('Flip', ptb.window, trialStartTime);

    fprintf('Trial %d | cue delay:     %.2f ms\n', trial, (cueOnset-trialStartTime)*1000);

    cueEnd = cueOnset + cueDuration;
    if ptb.useEyetracker
        Eyelink('Message', sprintf('CUE_ONSET trial=%d condition=%s',trial, condition));
    end
    % Draw the task (if something is shown, blank otherwise)
    if ~isempty(trialStim.taskImg)
        draw.stereo.images(ptb, design, trialStim.taskImg, trialStim.taskImg)
    else
        draw.stereo.blanks(ptb, design);
    end
    taskOnset = Screen('Flip', ptb.window, cueEnd);
    taskEnd = taskOnset + design.taskDuration;
    if ptb.useEyetracker
        Eyelink('Message', sprintf('TASK_ONSET trial=%d', trial));
    end
    % Draw the BR stimuli
    if log.reportCond == reportCondition.report
        %KbQueueFlush(ptb.Keyboard2);
        draw.stereo.images(ptb, design, trialStim.leftImage, trialStim.rightImage);
        stimOnset = Screen('Flip', ptb.window, taskEnd);
        stimOffset = stimOnset + design.stimulusPresentationTime;
        if ptb.useEyetracker
            Eyelink('Message', sprintf('RIVALRY_ONSET trial=%d condition=%s reportCondition=report left=%s right=%s',trial, condition,trialStim.leftEyeStim, trialStim.rightEyeStim));
        end
    else
        % No-report condition: fixation dots fade in
        draw.stereo.imagesNoReport(ptb, design,trialStim.leftImage, trialStim.rightImage,trialStim.selectedPair, design.fixDotTransparency);
        stimOnset = Screen('Flip', ptb.window, taskEnd);
        stimOffset = stimOnset + design.stimulusPresentationTime;
        if ptb.useEyetracker
            Eyelink('Message', sprintf('RIVALRY_ONSET trial=%d condition=%s reportCondition=%s left=%s right=%s',trial, condition,log.reportCond,trialStim.leftEyeStim, trialStim.rightEyeStim));
        end
    end
    % draw response phase (only fixation cross)
    draw.stereo.blanks(ptb,design);
    responseOnset = Screen('Flip',ptb.window, stimOffset);
    responseEnd = responseOnset + design.maxReportTime;
    if ptb.useEyetracker
        Eyelink('Message', sprintf('RIVALRY_OFFSET trial=%d', trial));
    end
    % draw first noise mask for ITI (already during response phase)
    [leftNoise, rightNoise] =generate.createStereoGaussianNoiseTextures(ptb, design);
    draw.stereo.textures(ptb, design, leftNoise, rightNoise);
    %collect the response
    if log.reportCond == reportCondition.report
        [response, rt, events, ambiguous] = input.getFirstKeyEventAmbiguous(ptb.Keyboard2,events,stimOnset, responseEnd, ptb.restrictedKeyList);
    else
        WaitSecs('UntilTime',responseEnd);
    end
    maskOnset = Screen('Flip', ptb.window, responseEnd);
    maskOffset = maskOnset + design.maskDuration;
    if ptb.useEyetracker
        Eyelink('Message', sprintf('Mask_ONSET trial=%d', trial));
    end
    display.stereo.gaussianNoise(ptb,design,maskOnset,design.maskDuration, leftNoise, rightNoise);
    draw.stereo.blanks(ptb, design)
    ITIOnset = Screen('Flip', ptb.window, maskOffset);
    if ptb.useEyetracker
        Eyelink('Message', sprintf('ITI_ONSET trial=%d',trial));
    end
    trialStartTime = ITIOnset + design.ITI;
    
    %% Save stimuli and timing
    log.data.condition{trial}       = condition;
    log.data.rightEye{trial}        = trialStim.rightEyeStim;
    log.data.leftEye{trial}         = trialStim.leftEyeStim;
    log.data.cue{trial}             = trialStim.cue;
    if log.reportCond == reportCondition.report
        log.data.response{trial}        = response;
        log.data.rt(trial)              = rt;
        log.data.isAmbiguos(trial)      = ambiguous;
    else
        leftBufferDotPos  = trialStim.selectedPair(:,1);
        rightBufferDotPos = trialStim.selectedPair(:,2);
        if strcmpi(trialStim.leftEyeStim, 'house')
            houseDotPos = leftBufferDotPos;
            faceDotPos  = rightBufferDotPos;
        else
            faceDotPos  = leftBufferDotPos;
            houseDotPos = rightBufferDotPos;
        end
        log.data.fixDotPosHouse{trial} = houseDotPos;
        log.data.fixDotPosFace{trial}  = faceDotPos;
        log.data.fixDotCoordHouse{trial} = design.fixDotPositions(houseDotPos, :);
        log.data.fixDotCoordFace{trial}  = design.fixDotPositions(faceDotPos, :);
    end
    log.data.isCatchTrial(trial)        = isCatch;
    log.data.cueOnset(trial)            = cueOnset;
    log.data.taskOnset(trial)           = taskOnset;
    log.data.BROnset(trial)             = stimOnset;
    log.data.responseOnset(trial)       = responseOnset;
    log.data.maskOnset(trial)           = maskOnset;
    log.data.ITIOnset(trial)            = ITIOnset;
    log.data.triggerTimes{trial} = input.getAllTriggers(ptb.Keyboard2,events, ptb.Keys.trg);
    
    fprintf('Trial %d | cue:     %.2f ms\n', trial, (1 - (taskOnset - cueOnset))*1000);
    fprintf('Trial %d | task:    %.2f ms\n', trial, (2 - (stimOnset - taskOnset))*1000);
    fprintf('Trial %d | br: %.2f ms\n', trial, (1.5-(responseOnset - stimOnset))*1000);
    fprintf('Trial %d | br response:    %.2f ms\n', trial, (2-(maskOnset - stimOffset))*1000);
    fprintf('Trial %d | mask:          %.2f ms\n', trial, (2-(ITIOnset - maskOnset))*1000);
    
end
end

function img = loadImage(folder, name)
filename = fullfile(folder, name + ".png");
info = imfinfo(filename);
img = imread(filename);
if isfield(info, 'Transparency')
    alpha = info.Transparency;
else
    alpha = [];
end
end

function trialStim = setUpStimuliButInGreyShadesThisTime(trialID, stimLookupTable, myPaths, design, condition, catchType,reportCond)
%% Determine the stimuli for the current trial
%note: as the file has 8 entries but we dont have a color condition each
%exact condition is repeated once. But tbh this does make sense so the runs
%are not too short so either have this or repeat which is both fine I dont
%care
isCatch = (catchType ~= "");
% Look up trial information
if ~isCatch
    stimRow = stimLookupTable(stimLookupTable.trialID == trialID, :);
    rightEyeStim = stimRow.rightEye{1};
    leftEyeStim = stimRow.leftEye{1};
    cue = stimRow.cue{1};
    leftImgName  = leftEyeStim; %  + "_gray";
    rightImgName = rightEyeStim; % + "_gray";
else
    catchParts = split(catchType, "_");
    cue = catchParts(1);
    if reportCond == reportCondition.report % in report condition, there is only mock rivalry
        rightEyeStim = "catch_" + catchParts(2);
        leftEyeStim = "catch_" + catchParts(2);
    else % no report condition has real rivalry in catch trials
        rightEyeStim = "catch_" + catchParts(2);
        leftEyeStim = "catch_" + catchParts(3);
    end
    leftImgName = leftEyeStim;
    rightImgName = rightEyeStim;
end

fixCrossColor = design.fontColor;

switch condition
    case "imagery"
        taskStimulus = "grey_square";
        cueTxt = design.cueTextImagery;
        if cue == "house"; fixCrossColor = design.houseColor; else; fixCrossColor = design.faceColor;end
    case "perception"
        taskStimulus = cue + "_30";
        cueTxt = design.cueTextPerception;
        if cue == "house"; fixCrossColor = design.houseColor; else; fixCrossColor = design.faceColor;end
    case "attention"
        taskStimulus = "superimposed";
        cueTxt = design.cueTextAttention;
        if cue == "house"; fixCrossColor = design.houseColor; else; fixCrossColor = design.faceColor;end
    case "baseline"
        cueTxt = design.cueTextBaseline;
        taskStimulus = "grey_square";
    otherwise
        error("Unknown condition")

end

if reportCond == reportCondition.noReport
    % Randomly select one valid pair
    pairIndex = randi(size(design.fixDotValidPairs, 1));
    selectedPair = design.fixDotValidPairs(pairIndex, :);
    if isCatch
        if strcmp(catchParts(4), 'single')
            % Pick one pair, but use its first position twice
            selectedPair = [selectedPair(1), selectedPair(1)];
        else
            % Pick two different pairs
            selectedPair = [selectedPair(1), selectedPair(1);
                selectedPair(2), selectedPair(2)];
        end
    end
end

%% Load the respective images
leftImage  = loadImage(myPaths.stimuliLocation, leftImgName);
rightImage = loadImage(myPaths.stimuliLocation, rightImgName);
taskImg = [];
if taskStimulus ~= ""
    taskImg = loadImage(myPaths.stimuliLocation, taskStimulus);
end

trialStim = struct( ...
    "rightEyeStim", rightEyeStim, ...
    "leftEyeStim", leftEyeStim, ...
    "cue", cue, ...
    "leftImage", leftImage, ...
    "rightImage", rightImage, ...
    "taskImg", taskImg, ...
    "cueTxt", cueTxt, ...
    "fixCrossColor", fixCrossColor);
if reportCond == reportCondition.noReport; trialStim.selectedPair = selectedPair;end
end







