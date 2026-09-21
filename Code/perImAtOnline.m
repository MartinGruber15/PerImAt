function [log, ptb, design, participantInfo] = perImAtOnline(log, ptb, design, myPaths, participantInfo,modus)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This experiment ...
%
% input:
%       log - struct tracking the data gathered in a trial
%       ptb - struct containing information about Psychtoolbox parameters
%       design - struct containing information about experimental design
%       myPaths - struct containing the paths (e.g. to the stimuli)
%       participantInfo - struct containing data about the participant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% FYA - Choose modus
% testing vs full
%modus = 'testing';

%% Timing
design.instructionWaitDuration  = 0.5;

design.stimulusPresentationTime = 1.5 - ptb.ifi/2; % 1
design.taskDuration             = 2 - ptb.ifi/2; % 6
design.ITI                      = 2 - ptb.ifi/2; % 5
design.maxReportTime            = 2 - ptb.ifi/2; % 2
design.cueDuration              = 1 - ptb.ifi/2; % 1 (3 for every first in miniblock)
design.maskDuration             = 2 - ptb.ifi/2;

%% Create a random sequence for the trials
% we have 4 conditions with baseline only having half the trials
% the order of these blocks has to be randomized and each block contains a
% randomized sequence of the 8 (4) possible trials
% first, we make sure we have catchtrials table
switch log.reportCond
    case reportCondition.report
        catchFilename = "catchTrialOrderR.csv";
    case reportCondition.noReport
        catchFilename = "catchTrialOrderNR.csv";
end
isReport = log.reportCond == reportCondition.report;
catchFile = fullfile(myPaths.subjectDirectory, catchFilename);
if ~isfile(catchFile)
    createCatchTrialOrder(myPaths.subjectDirectory, design.maxRunNr, catchFilename, isReport);
end
catchTable = readtable(catchFile);
conditions = ["imagery", "attention", "perception", "baseline"];
if strcmp(modus,'full')
    trialSequence = buildTrialSequence(design.stimLookupTable, conditions, catchTable, log.runNr, isReport);
else
    trialSequence = buildTestTrialSequence(design.stimLookupTable, conditions);
end

rows=height(trialSequence);
rows = 3; %TODO remove

%% Empty cell arrays to save trial information
log.data.condition              = cell(rows,1);
log.data.leftEye                = cell(rows,1);
log.data.rightEye               = cell(rows,1);
log.data.cue                    = cell(rows,1);
if log.reportCond == reportCondition.report
    log.data.response               = cell(rows,1);
    log.data.rt                     = zeros(rows,1);
    log.data.perceived              = cell(rows,1);
    log.data.isAmbiguos          = false(rows,1);
else
    log.data.fixDotPosHouse   = cell(rows,1);
    log.data.fixDotPosFace    = cell(rows,1);
    log.data.fixDotCoordHouse = cell(rows,1);
    log.data.fixDotCoordFace  = cell(rows,1);
end
log.data.isCatchTrial         = false(rows,1);
log.data.triggerTimes         = cell(rows,1);

log.data.cueOnset             = zeros(rows,1);
log.data.taskOnset            = zeros(rows,1);
log.data.BROnset              = zeros(rows,1);
log.data.responseOnset        = zeros(rows,1);
log.data.maskOnset            = zeros(rows,1);
log.data.ITIOnset             = zeros(rows,1);


%% Trial Procedure
if log.runNr == 1
    display.stereo.instruction(ptb,design, design.Introduction, design.instructionWaitDuration, false);
    display.stereo.legendInstruction(ptb,design, design.cueInstruction, design.instructionWaitDuration, false);
    display.stereo.instruction(ptb,design, design.taskInstruction, design.instructionWaitDuration, false);
    switch log.reportCond
        case reportCondition.report
            display.stereo.instruction(ptb,design, design.reportInstructionReport,design.instructionWaitDuration, false);
        case reportCondition.noReport
            display.stereo.instruction(ptb,design, design.reportInstructionNoReport,design.instructionWaitDuration, false);
    end
    display.stereo.instruction(ptb,design, design.questionInstruction, design.instructionWaitDuration, false);
end
if log.reportCond == reportCondition.noReport
    display.stereo.legendInstruction(ptb,design, design.legendReminderInstructionNoReport,design.instructionWaitDuration, false);
else
    display.stereo.legendInstruction(ptb,design, design.legendReminderInstructionReport,design.instructionWaitDuration, false);
end
display.stereo.instruction(ptb, design,design.fixOnFixCross, design.instructionWaitDuration, false);

%% Main Experiment<
%only for debug
design.nDummies                 = 5;
ptb.Keys.trg    = KbName ('w');     ptb.KeyList2(ptb.Keys.trg)   = double(1); % The scanner sends 'w' as USB keyboard input (from keyboard 2)

%log = mri.waitForTrigger(ptb, log,design);
display.stereo.instruction(ptb,design, design.waitTillStart, design.waitTillStartDuration, true);

log = trialProcedurePerImAtOnline(log, design, ptb, myPaths, design.stimLookupTable, trialSequence, rows);

%% Run is over
display.stereo.instruction(ptb, design, design.RunIsOver, design.instructionWaitDuration, false);

%% End of experiment
%% Save data
if strcmp(modus,'training'); prefix='_train_';else;prefix='';end
fileName = ['sub-' log.sub '_online' prefix sprintf('_run-%02d',log.runNr) '_' log.suffix '_' char(datetime('now','Format','yyyy-MM-dd_HHmmss'))];
% Convert button presses from key ids to the perceived (house,face,mixed)
if log.reportCond == reportCondition.report
    response = log.data.response;
    for i = 1:numel(response)
        if isempty(response{i})
            log.data.perceived{i} = 'mixed';
        else
            firstResponse = response{i}(1);
            if firstResponse == ptb.Keys.house
                log.data.perceived{i} = 'house';
            elseif firstResponse == ptb.Keys.face
                log.data.perceived{i} = 'face';
            elseif firstResponse == 0 || firstResponse == ptb.Keys.accept
                log.data.perceived{i} = 'mixed';
            end
        end
    end
    % Convert response vectors to comma-separated strings for CSV
    log.data.response = cellfun(@(x) strjoin(string(x), ','),log.data.response,'UniformOutput', false);
else
    log.data.fixDotPosHouse = cellfun(@(x) strjoin(string(x), ','),log.data.fixDotPosHouse,'UniformOutput', false);
    log.data.fixDotPosFace = cellfun(@(x) strjoin(string(x), ','),log.data.fixDotPosFace,'UniformOutput', false);
    log.data.fixDotCoordHouse = cellfun(@(x) strjoin(string(x), ','),log.data.fixDotCoordHouse,'UniformOutput', false);
    log.data.fixDotCoordFace = cellfun(@(x) strjoin(string(x), ','),log.data.fixDotCoordFace,'UniformOutput', false);
end

log.data.triggerTimes = cellfun(@(x) strjoin(string(x), ','),log.data.triggerTimes,'UniformOutput', false);

% save the data to csv file
if strcmp(modus,'full')
    responseTable = struct2table(log.data);
    writetable(responseTable, fullfile(myPaths.subjectDirectory, [fileName '.csv']), 'Delimiter',';');
end

%% close open connections and screen
eyetracking.closeEyetracker(ptb, myPaths.subjectDirectory);
if ptb.usedatapixx
    Datapixx('Close');
end
Screen('CloseAll');
%ListenChar(1); % enable input to matlab windows
% Experiment ended without errors
log.end = 'Success';
end

function trialSequence = buildTrialSequence(stimLookupTable, conditions, catchTable, runId, report, repeats, seed)
% trialSequence: Nx2 numeric array [trialID, conditionIdx]
% stimLookupTable : table
% conditions : string/cellstr array, e.g. ["imagery","attention","perception","baseline"]
% repeats : repetitions per trial set (scalar, default 1)
% seed : numeric RNG seed (optional)

if nargin<6 || isempty(repeats), repeats = 1; end
if nargin<7, seed = []; end
if ~isempty(seed); rng(seed);end

conditions = string(conditions(:));
rows = height(stimLookupTable);    % total rows in table
% Define how many unique trial IDs per condition
nPer = [rows, rows, rows, rows/2];

sets = cell(1,4);
for c = 1:4
    % normal trials
    ids = (1:nPer(c));                     % trial IDs for imagery/attention/perception
    ids = repmat(ids, 2, repeats);       % repeat each id
    ids = ids(randperm(numel(ids)));    % randomize order within block
    condNames = repmat(conditions(c), numel(ids), 1);
    normalTrials = table(ids(:), condNames, 'VariableNames', {'trialID','condition'});
    % catch trials
    if ~isempty(catchTable)
        thisCatch = catchTable(double(catchTable.run) == runId & string(catchTable.condition) == conditions(c), :); %catchtrials in this condition (and run)
        nCatch = height(thisCatch); % number of catch trials in this condition
        catchTrials = table(NaN(nCatch,1),strings(nCatch,1),'VariableNames', {'trialID','condition'}); % imitate normal trials although there is no valid trialID
        for k = 1:nCatch % encode catch trial details in condition name
            cue = string(thisCatch.cue(k));
            if report
                stimulus = string(thisCatch.stimulus(k));
                catchTrials.condition(k) = conditions(c) + "_catch_" + cue + "_" + stimulus;
            else
                leftEye = string(thisCatch.leftEye(k));
                rightEye = string(thisCatch.rightEye(k));
                catchType = string(thisCatch.catchType(k));
                catchTrials.condition(k) = conditions(c) + "_catch_" + cue + "_" + leftEye + "_" + rightEye + "_" + catchType;
            end
        end
    else 
        catchTrials = table(NaN(0,1),strings(0,1),'VariableNames', {'trialID','condition'});
    end
    block = [normalTrials; catchTrials];
    block = block(randperm(height(block)), :);
    sets{c} = block;
end

% Randomize order of the four blocks and concatenate
order = randperm(4);
trialSequence = vertcat(sets{order});
end


function trialSequence = buildTestTrialSequence(stimLookupTable, conditions)
% trialSequence: Nx2 numeric array [trialID, conditionIdx]
% stimLookupTable : table 
repeats = 1;
conditions = string(conditions(:));
rows = height(stimLookupTable);    % total rows in table
% Define how many unique trial IDs per condition
nPer = [rows, rows, rows, rows/2];

sets = cell(1,4);
for c = 1:4
    % normal trials
    ids = (1:nPer(c));                     % trial IDs for imagery/attention/perception
    ids = repmat(ids, 2, repeats);       % repeat each id
    ids = ids(randperm(numel(ids)));    % randomize order within block
    condNames = repmat(conditions(c), numel(ids), 1);
    block = table(ids(:), condNames, 'VariableNames', {'trialID','condition'});
    sets{c} = block;
end

% Randomize order of the four blocks and concatenate
order = randperm(4);
trialSequence = vertcat(sets{order});
end
