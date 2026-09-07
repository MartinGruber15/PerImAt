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
modus = 'full';

%% Timing
design.instructionWaitDuration  = 0.5;

design.stimulusPresentationTime = 1 - ptb.ifi/2;
design.taskDuration             = 3 -ptb.ifi/2; % 6
design.maxVividTime             = 2 - ptb.ifi/2;
design.ITI                      = 3 - ptb.ifi/2; % 5
design.maxReportTime            = 2 - ptb.ifi/2;
design.cueDuration              = 1 - ptb.ifi/2;


%% Create a random sequence for the trials
% we have 4 conditions with baseline only having half the trials
% the order of these blocks has to be randomized and each block contains a
% randomized sequence of the 8 (4) possible trials
conditions = ["imagery", "attention", "perception", "baseline"];
trialSequence = buildTrialSequence(design.stimLookupTable, conditions);

%%%%%%%%%% MODUS %%%%%%%%%%
if strcmp(modus, 'testing')
    rows = 2;
elseif strcmp(modus, 'full')
    rows=height(trialSequence);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Empty cell arrays to save trial information
log.data.condition              = cell(rows,1);
log.data.leftEye                = cell(rows,1);
log.data.rightEye               = cell(rows,1);
log.data.cue                    = cell(rows,1);
log.data.response               = zeros(rows,1);
log.data.rt                     = zeros(rows,1);
log.data.stimOnset              = zeros(rows,1);
log.data.stimOffset             = zeros(rows,1);
log.data.vividResponse          = zeros(rows,1);
log.data.vividRT                = zeros(rows,1);
log.data.perceived              = cell(rows, 1);
log.data.rating                 = cell(rows, 1);


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

%% Main Experiment
log = trialProcedureImageryAttention(log, design, ptb, myPaths, design.stimLookupTable, trialSequence, rows);

%% Run is over
display.stereo.instruction(ptb, design.RunIsOver, design.instructionWaitDuration, false);
disp(log.data)

%% End of experiment
Screen('CloseAll')
%ListenChar(1); % enable input to matlab windows
% Experiment ended without errors
log.end = 'Success';

%% Save data
fileName = ['sub-' log.sub '_task-' sprintf('_run-%02d',log.runNr)];
% Convert button presses from key ids to the perceived (rect,circle,house,face,mixed)
log.data.perceived(find(log.data.response==(ptb.Keys.house))) = {'house'};
log.data.perceived(find(log.data.response==ptb.Keys.face)) = {'face'};
log.data.perceived(find(log.data.response==0 | log.data.response==ptb.Keys.accept)) = {'mixed'};
log.data.rating(find(log.data.vividResponse==(ptb.Keys.left))) = {'1'};
log.data.rating(find(log.data.vividResponse==(ptb.Keys.up))) = {'2'};
log.data.rating(find(log.data.vividResponse==(ptb.Keys.right))) = {'3'};
log.data.rating(find(log.data.vividResponse==(ptb.Keys.down))) = {'4'};
log.data.rating(find(log.data.vividResponse==(ptb.Keys.accept))) = {'5'};



% save the data to csv file
responseTable = struct2table(log.data);
writetable(responseTable, fullfile(myPaths.subjectDirectory, [fileName '.csv']));

end

function trialSequence = buildTrialSequence(stimLookupTable, conditions, repeats, seed)
% trialSequence: Nx2 numeric array [trialID, conditionIdx]
% stimLookupTable : table (used only to check available stimulus IDs)
% conditions : string/cellstr array, e.g. ["imagery","attention","perception","baseline"]
% repeats : repetitions per trial set (scalar, default 1)
% seed : numeric RNG seed (optional)

if nargin<3 || isempty(repeats), repeats = 1; end
if nargin<4, seed = []; end
if ~isempty(seed); rng(seed);end

conditions = string(conditions(:));
rows = height(stimLookupTable);    % total rows in table
% Define how many unique trial IDs per condition
nPer = [rows, rows, rows, rows/2];

sets = cell(1,4);
for c = 1:4
    ids = (1:nPer(c));                     % trial IDs for imagery/attention/perception
    ids = repmat(ids, 2, repeats);       % repeat each id
    ids = ids(randperm(numel(ids)));    % randomize order within block
    condNames = repmat(conditions(c), numel(ids), 1);
    sets{c} = table(ids(:), condNames, 'VariableNames', {'trialID','condition'});
end

% Randomize order of the four blocks and concatenate
order = randperm(4);
trialSequence = vertcat(sets{order});
end
