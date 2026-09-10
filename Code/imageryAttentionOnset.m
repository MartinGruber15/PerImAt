function [log, ptb, design, participantInfo] = imageryAttentionOnset(log, ptb, design, myPaths, participantInfo)

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
modus = 'testing';

%% Timing
design.instructionWaitDuration  = 0.5;

design.stimulusPresentationTime = 3 - ptb.ifi/2; % 1
design.taskDuration             = 3 - ptb.ifi/2; % 6
design.maxVividTime             = 2 - ptb.ifi/2; % 2
design.ITI                      = 2 - ptb.ifi/2; % 5
design.maxReportTime            = 2 - ptb.ifi/2; % 2
design.cueDuration              = 1 - ptb.ifi/2; % 1 (3 for every first in miniblock)


%% Create a random sequence for the trials
% we have 4 conditions with baseline only having half the trials
% the order of these blocks has to be randomized and each block contains a
% randomized sequence of the 8 (4) possible trials
% first, we make sure we have catchtrials table
catchFile = fullfile(myPaths.subjectDirectory, "catchTrialOrder.csv");
if ~isfile(catchFile)
    createCatchTrialOrder(myPaths.subjectDirectory, design.maxRunNr, "catchTrialOrder.csv");
end
catchTable = readtable(catchFile);
conditions = ["imagery", "attention", "perception", "baseline"]; 
trialSequence = buildTrialSequence(design.stimLookupTable, conditions, catchTable, log.runNr);

%%%%%%%%%% MODUS %%%%%%%%%%
if strcmp(modus, 'testing')
    rows = 5;
elseif strcmp(modus, 'full')
    rows=height(trialSequence);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Empty cell arrays to save trial information
log.data.condition              = cell(rows,1);
log.data.leftEye                = cell(rows,1);
log.data.rightEye               = cell(rows,1);
log.data.cue                    = cell(rows,1);
log.data.stimOnset              = zeros(rows,1);
log.data.stimOffset             = zeros(rows,1);
log.data.vividResponse          = zeros(rows,1);
log.data.vividRT                = zeros(rows,1);
log.data.rating                 = cell(rows,1);
if log.report
    log.data.response               = zeros(rows,1);
    log.data.rt                     = zeros(rows,1);
    log.data.perceived              = cell(rows,1);
else
    log.data.fixDotPosHouse   = nan(rows,1);
    log.data.fixDotPosFace    = nan(rows,1);
    log.data.fixDotCoordHouse = cell(rows,1);
    log.data.fixDotCoordFace  = cell(rows,1);
end
log.data.isCatchTrial           = false(rows,1);


%% Fusion alignment
% Before every run
participantInfo = display.stereo.alignFusion(ptb, participantInfo); 

%% Trial Procedure

% Onset Introduction 1
display.stereo.instruction(ptb, design.OnsetInstructionBrascamp1, design.instructionWaitDuration, false);
% Onset Introduction 2
%displayStereoInstruction(ptb, design.OnsetInstructionBrascamp2, design.instructionWaitDuration, false);
% Onset Introduction 3
%displayStereoInstruction(ptb, design.OnsetInstructionsBrascamp3, design.instructionWaitDuration, false);
% Fix on Fixcross
%displayStereoInstruction(ptb, design.fixOnFixCross, design.instructionWaitDuration, false);


%% Test trials
% Test trial information
%displayStereoInstruction(ptb, design.OnsetInstructionsOnsetTraining, design.instructionWaitDuration, false);
% Onset introduction 4 - Reminder key assignment
%displayStereoInstruction(ptb, design.OnsetInstructionsBrascamp4, design.instructionWaitDuration, false);
%  Wait till start
%displayStereoInstruction(ptb, design.waitTillStart, design.waitTillStartDuration, true);

%   Test trials are over
%displayStereoInstruction(ptb, design.OnsetInstructionsOnsetTrainingEnd, design.instructionWaitDuration, false);

%% Instructions main experiment
% Onset introduction 4 - Reminder key assignment
%displayStereoInstruction(ptb, design.OnsetInstructionsBrascamp4, design.instructionWaitDuration, false);
% Wait till start
%displayStereoInstruction(ptb, design.waitTillStart, design.waitTillStartDuration, true);

%% Main Experiment<
if strcmp(ptb.SetUp,'MPI')
    mri.waitForTrigger(ptb, log,design);
end
log = trialProcedureImageryAttention(log, design, ptb, myPaths, design.stimLookupTable, trialSequence, rows);

%% Run is over
display.stereo.instruction(ptb, design.RunIsOver, design.instructionWaitDuration, false);
disp(log.data)

%% End of experiment
%% Save data
if log.report
    fileName = ['sub-' log.sub '_task-' sprintf('_run-%02d',log.runNr)];
else
    fileName = ['sub-' log.sub '_task-' sprintf('_run-%02d',log.runNr) 'nr'];
end
% Convert button presses from key ids to the perceived (rect,circle,house,face,mixed)
if log.report
    log.data.perceived(find(log.data.response==(ptb.Keys.house))) = {'house'};
    log.data.perceived(find(log.data.response==ptb.Keys.face)) = {'face'};
    log.data.perceived(find(log.data.response==0 | log.data.response==ptb.Keys.accept)) = {'mixed'};
end
log.data.rating(find(log.data.vividResponse==(ptb.Keys.left))) = {'1'};
log.data.rating(find(log.data.vividResponse==(ptb.Keys.up))) = {'2'};
log.data.rating(find(log.data.vividResponse==(ptb.Keys.right))) = {'3'};
log.data.rating(find(log.data.vividResponse==(ptb.Keys.down))) = {'4'};
log.data.rating(find(log.data.vividResponse==(ptb.Keys.accept))) = {'5'};


% save the data to csv file
responseTable = struct2table(log.data);
writetable(responseTable, fullfile(myPaths.subjectDirectory, [fileName '.csv']));

%% close open connections and screen
eyetracking.closeEyetracker(ptb, myPaths.subjectDirectory);
if ptb.usedatapixx
    Datapixx('Close');
end
Screen('CloseAll')
%ListenChar(1); % enable input to matlab windows
% Experiment ended without errors
log.end = 'Success';
end

function trialSequence = buildTrialSequence(stimLookupTable, conditions, catchTable, runId, repeats, seed)
% trialSequence: Nx2 numeric array [trialID, conditionIdx]
% stimLookupTable : table (used only to check available stimulus IDs)
% conditions : string/cellstr array, e.g. ["imagery","attention","perception","baseline"]
% repeats : repetitions per trial set (scalar, default 1)
% seed : numeric RNG seed (optional)

if nargin<5 || isempty(repeats), repeats = 1; end
if nargin<6, seed = []; end
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
            stimulus = string(thisCatch.stimulus(k));
            catchTrials.condition(k) = conditions(c) + "_catch_" + cue + "_" + stimulus;
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


