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

rows = height(trialSequence);

%% Presentation of stimuli
log.ExperimentStart = GetSecs();
trialStartTime = log.ExperimentStart;

% Loop trough all trials
for trial = 1:rows
    %% Determine the stimuli for the current trial
    % Extract trialID and load stimuli
    trialID   = trialSequence.trialID(trial);
    condition = trialSequence.condition(trial);
    trialStim = setUpStimuli(trialID, stimLookupTable, myPaths, design, condition);
   
    %% Trial Procedure
    % Draw the cue
    drawStereoInstruction(ptb, trialStim.cueTxt);
    cueOnset = Screen('Flip', ptb.window, trialStartTime);
    cueEnd = cueOnset + design.cueDuration;

    % Draw the task (if something is shown, blank otherwise)
    if ~isempty(trialStim.taskImg)
        drawStereoImages(ptb, design, trialStim.taskImg, trialStim.taskImg)
    else
        drawStereoBlanks(ptb, design);
    end
    taskOnset = Screen('Flip', ptb.window, cueEnd);
    taskEnd = taskOnset + design.taskDuration;

    % Draw the BR stimuli
    KbQueueFlush(ptb.Keyboard2);
    drawStereoImages(ptb, design, trialStim.leftImage, trialStim.rightImage)
    stimOnset = Screen('Flip', ptb.window, taskEnd);
    stimOffset = stimOnset + design.stimulusPresentationTime;
    
    % draw response phase (only fixation cross)
    drawStereoBlanks(ptb,design);
    responseOnset = Screen('Flip',ptb.window, stimOffset);
    responseEnd = responseOnset + design.maxReportTime;
    %collect the response
    [response, rt] = getFirstResponse(ptb, stimOnset, responseEnd);
    
    % draw vividness question
    drawStereoInstruction(ptb, design.vividQuestionText);
    vividOnset = Screen('Flip', ptb.window);
    vividEnd = vividOnset + design.maxVividTime;
    %collect vividness response
    [vividResponse, vividRT] = getFirstResponse(ptb, vividOnset, vividEnd);
    
    % draw ITI (blank)
    drawStereoBlanks(ptb, design)
    ITIOnset = Screen('Flip', ptb.window);
    trialStartTime = ITIOnset + design.ITI;


    %% Save stimuli and timing
    log.data.condition{trial}       = condition;
    log.data.rightEye{trial}        = trialStim.rightEyeStim;
    log.data.leftEye{trial}         = trialStim.leftEyeStim;
    log.data.faceColor{trial}       = trialStim.faceColor;
    log.data.houseColor{trial}      = trialStim.houseColor;
    log.data.cue{trial}             = trialStim.cue;
    log.data.response(trial)        = response;
    log.data.rt(trial)              = rt;
    log.data.stimOnset(trial)       = stimOnset;
    log.data.stimOffset(trial)      = stimOffset;
    log.data.vividResponse(trial)   = vividResponse;
    log.data.vividRT(trial)         = vividRT;


end
end

function trialStim = setUpStimuli(trialID, stimLookupTable, myPaths, design, condition)
    %% Determine the stimuli for the current trial
   
    % Look up trial information
    stimRow = stimLookupTable(stimLookupTable.trialID == trialID, :);
    rightEyeStim = stimRow.rightEye{1};
    leftEyeStim = stimRow.leftEye{1};
    faceColor = stimRow.faceColor{1};
    houseColor = stimRow.houseColor{1};
    cue = stimRow.cue{1};

    if leftEyeStim == "house"
        leftColor  = houseColor;
        rightColor = faceColor;
    else
        leftColor  = faceColor;
        rightColor = houseColor;
    end

    if cue == "house"; cueColor = houseColor; else; cueColor = faceColor; end

    leftImgName  = leftEyeStim  + "_" + leftColor;
    rightImgName = rightEyeStim + "_" + rightColor;

switch condition
    case "imagery"
        taskStimulus = "";
        if cue == "house"
            if cueColor == "green"; cueTxt = design.imageryGreenHouseText; else; cueTxt = design.imageryRedHouseText;end
        else
            if cueColor == "green"; cueTxt = design.imageryGreenFaceText;else;cueTxt = design.imageryRedFaceText;end
        end
    case "perception"
        taskStimulus = cue + "_" + cueColor;
        if cue == "house"
            if cueColor == "green";cueTxt = design.perceptGreenHouseText;else;cueTxt = design.perceptRedHouseText;end
        else
            if cueColor == "green";cueTxt = design.perceptGreenFaceText;else;cueTxt = design.perceptRedFaceText;end
        end
    case "attention"
        taskStimulus = "superimposed";
        if cue == "house";cueTxt = design.attentionHouseText;else;cueTxt = design.attentionFaceText;end
    case "baseline"
        cueTxt = design.baselineText;
        taskStimulus = "";
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
    "faceColor", faceColor, ...
    "houseColor", houseColor, ...
    "leftImage", leftImage, ...
    "rightImage", rightImage, ...
    "taskImg", taskImg, ...
    "cueTxt", cueTxt);
end

function img = loadImage(folder, name)
filename = fullfile(folder, name + ".png");
[img,~,alpha] = imread(filename);
%img(:,:,4) = alpha;
end

function drawStereoInstruction(ptb, text)
% PURE DRAW FUNCTION (NO TIMING LOGIC)

Screen('SelectStereoDrawBuffer', ptb.window, ptb.leftBuffer);
DrawFormattedText(ptb.window, text, 'center', 'center', ptb.FontColor);

Screen('SelectStereoDrawBuffer', ptb.window, ptb.rightBuffer);
DrawFormattedText(ptb.window, text, 'center', 'center', ptb.FontColor);

Screen('DrawingFinished', ptb.window);
end

function [resp, rt] = getFirstResponse(ptb, tStart, tEnd)
resp = NaN;
rt   = 0;

while GetSecs < tEnd
    [pressed, firstPress] = KbQueueCheck(ptb.Keyboard2);
    % Store only the first valid response
    if pressed && isnan(resp)
        valid = firstPress;
        valid(valid < tStart) = 0;
        if any(valid)
            tPress = min(valid(valid > 0));
            resp   = find(firstPress == tPress,1);
            rt     = tPress - tStart;
            %fprintf('RT from stim  = %.3f\n', tPress - tStart);
            %fprintf('Response: %d (RT = %.3f s)\n', resp, rt);
        end
    end
    WaitSecs(0.001);   % reduces CPU load
end
if isnan(resp); resp=0;end
end