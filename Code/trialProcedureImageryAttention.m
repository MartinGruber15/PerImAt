function log = trialProcedureImageryAttention(log, design, ptb, myPaths, stimLookupTable, trialSequence, rows)
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
    if ~log.report
        % Determine whether this trial uses cardinal or diagonal positions
        % Here we alternate between the two.
        if mod(trial, 2) == 1
            availablePairs = design.fixDotCardinalPairs;
        else
            availablePairs = design.fixDotDiagonalPairs;
        end
        % Randomly select one valid pair
        pairIndex = randi(size(availablePairs, 1));
        selectedPair = availablePairs(pairIndex, :);
    end

    %trialStim = setUpStimuli(trialID, stimLookupTable, myPaths, design, condition);
    trialStim = setUpStimuliButInGreyShadesThisTime(trialID, stimLookupTable, myPaths, design, condition, catchType);
    if prevCondition ~= condition
        remindAssociation = true;
        prevCondition = condition; % Update previous condition for the next trial
    end    

    %% Trial Procedure
    % Draw the cue
    if remindAssociation
        draw.stereo.fixCrossPlusLegend(ptb, design, trialStim.cueTxt, trialStim.fixCrossColor);
        remindAssociation = false;
        cueDuration = design.cueDuration + 1;
    else
        draw.stereo.fixCrossPlusText(ptb, design,trialStim.cueTxt, trialStim.fixCrossColor);
        cueDuration = design.cueDuration;
    end
    cueOnset = Screen('Flip', ptb.window, trialStartTime);
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
    if log.report
        KbQueueFlush(ptb.Keyboard2);
        draw.stereo.images(ptb, design, trialStim.leftImage, trialStim.rightImage);
        stimOnset = Screen('Flip', ptb.window, taskEnd);
        stimOffset = stimOnset + design.stimulusPresentationTime;
        if ptb.useEyetracker
            Eyelink('Message', sprintf('RIVALRY_ONSET trial=%d condition=%s report=1 left=%s right=%s',trial, condition,trialStim.leftEyeStim, trialStim.rightEyeStim));
        end
    else
        % No-report condition: fixation dots fade in
        draw.stereo.imagesNoReport(ptb, design,trialStim.leftImage, trialStim.rightImage,selectedPair, 0);
        stimOnset = Screen('Flip', ptb.window, taskEnd);
        stimOffset = stimOnset + design.stimulusPresentationTime;
        if ptb.useEyetracker
            Eyelink('Message', sprintf('RIVALRY_ONSET trial=%d condition=%s report=0 left=%s right=%s',trial, condition,trialStim.leftEyeStim, trialStim.rightEyeStim));
        end
        % Fade-in
        vbl = stimOnset;
        for f = 1:design.fixDotFadeFrames
            alpha = design.fixDotTransparency * f / design.fixDotFadeFrames;
            draw.stereo.imagesNoReport(ptb, design,trialStim.leftImage, trialStim.rightImage,selectedPair, alpha);
            vbl = Screen('Flip', ptb.window,vbl + (ptb.waitframes - 0.5) * ptb.ifi);
        end
        % From here on the dots are fully visible and there is time left
        % for drawing the next blanks
    end
    % draw response phase (only fixation cross)
    draw.stereo.blanks(ptb,design);
    responseOnset = Screen('Flip',ptb.window, stimOffset);
    responseEnd = responseOnset + design.maxReportTime;
    if ptb.useEyetracker
        Eyelink('Message', sprintf('RIVALRY_OFFSET trial=%d', trial));
    end
    % draw vividness question (already during response phase)
    draw.stereo.instructionLikert(ptb,design, trialStim.finalQText, 5);
    %collect the response
    if log.report
        [response, rt] = input.getFirstResponse(ptb, stimOnset, responseEnd);
    else
        WaitSecs('UntilTime',responseEnd);
    end
    vividOnset = Screen('Flip', ptb.window);
    vividEnd = vividOnset + design.maxVividTime; % allow response during ITI
    if ptb.useEyetracker
        Eyelink('Message', sprintf('VIVIDNESS_ONSET trial=%d', trial));
    end
    % draw ITI (blank)
    draw.stereo.blanks(ptb, design)
    ITIOnset = Screen('Flip', ptb.window, vividEnd);
    if ptb.useEyetracker
        Eyelink('Message', sprintf('ITI_ONSET trial=%d', trial));
    end
    %collect vividness response
    [vividResponse, vividRT] = input.getFirstResponse(ptb, vividOnset, vividEnd + design.ITI);

    trialStartTime = ITIOnset + design.ITI;


    %% Save stimuli and timing
    log.data.condition{trial}       = condition;
    log.data.rightEye{trial}        = trialStim.rightEyeStim;
    log.data.leftEye{trial}         = trialStim.leftEyeStim;
    log.data.cue{trial}             = trialStim.cue;
    if log.report
        log.data.response(trial)        = response;
        log.data.rt(trial)              = rt;
    else
        leftBufferDotPos  = selectedPair(1);
        rightBufferDotPos = selectedPair(2);
        if strcmpi(trialStim.leftEyeStim, 'house')
            houseDotPos = leftBufferDotPos;
            faceDotPos  = rightBufferDotPos;
        else
            faceDotPos  = leftBufferDotPos;
            houseDotPos = rightBufferDotPos;
        end
        log.data.fixDotPosHouse(trial) = houseDotPos;
        log.data.fixDotPosFace(trial)  = faceDotPos;
        log.data.fixDotCoordHouse{trial} = design.fixDotPositions(houseDotPos, :);
        log.data.fixDotCoordFace{trial}  = design.fixDotPositions(faceDotPos, :);
    end
    log.data.stimOnset(trial)       = stimOnset;
    log.data.stimOffset(trial)      = stimOffset;
    log.data.vividResponse(trial)   = vividResponse;
    log.data.vividRT(trial)         = vividRT;
    log.data.isCatchTrial(trial)    = isCatch;


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

function trialStim = setUpStimuliButInGreyShadesThisTime(trialID, stimLookupTable, myPaths, design, condition, catchType)
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
    leftImgName  = leftEyeStim  + "_gray";
    rightImgName = rightEyeStim + "_gray";
else
    catchParts = split(catchType, "_");
    cue = catchParts(1);
    rightEyeStim = "catch_" + catchParts(2);
    leftEyeStim = "catch_" + catchParts(2);
    leftImgName = leftEyeStim;
    rightImgName = rightEyeStim;
end

finalQuestion = design.finalQuestion;
fixCrossColor = design.fontColor;

switch condition
    case "imagery"
        taskStimulus = "grey_square";
        cueTxt = design.cueTextImagery;
        if cue == "house"; fixCrossColor = design.houseColor; else; fixCrossColor = design.faceColor;end
    case "perception"
        taskStimulus = cue + "_30" + "_gray";
        cueTxt = design.cueTextPerception;
        if cue == "house"; fixCrossColor = design.houseColor; else; fixCrossColor = design.faceColor;end
    case "attention"
        taskStimulus = "superimposed_gray";
        cueTxt = design.cueTextAttention;
        if cue == "house"; fixCrossColor = design.houseColor; else; fixCrossColor = design.faceColor;end
    case "baseline"
        cueTxt = design.cueTextBaseline; % no text at all?
        taskStimulus = ""; %TODO what to show?
    otherwise
        error("Unknown condition")

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
    "finalQText", finalQuestion,...
    "fixCrossColor", fixCrossColor);
end