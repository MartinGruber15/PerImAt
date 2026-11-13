function [log, ptb, design, participantInfo] = perImAtOffline(log, ptb, design, myPaths, participantInfo,modus)

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

%% Modus
%   'full'     : one main-experiment run (log.runNr, log.reportCond)
%   'training' : practice before the first run of a report condition: all
%                instructions + 14 trials (each trial type once), no catch trials
%   'practice' : [added 2026-11-04] the short dual-task practice after the
%                fixation-dot demonstration (presentFixDotLocations): 7 trials
%                (2 imagery, 2 attention, 2 perception - one per cue - and
%                1 baseline), in blocks like the real runs, with the real trial
%                durations; instructions as in 'training' (without the welcome
%                screen), no new fusion alignment (just done), no eye tracker.

%% Timing
design.instructionWaitDuration  = 0.5;

design.stimulusPresentationTime = 3 - ptb.ifi/2; % rivalry 3 s (as in the QUEST+ calibration) [changed 2026-11-06, was 2 s]
design.taskDuration             = 6 - ptb.ifi/2; % 6
design.maxVividTime             = 2 - ptb.ifi/2; % 2
design.ITI                      = 2 - ptb.ifi/2; % 5
design.maxReportTime            = 2 - ptb.ifi/2; % 2
design.cueDuration              = 1 - ptb.ifi/2; % 1 (3 for every first in miniblock)


%% Create a random sequence for the trials
% we have 4 conditions with baseline only having half the trials
% the order of these blocks has to be randomized and each block contains a
% randomized sequence of the 8 (4) possible trials
% first, we make sure we have catchtrials table
switch log.reportCond
    case reportCondition.report
        catchFilename = "catchTrialOrderR.csv";
    case reportCondition.dual
        catchFilename = "catchTrialOrderDual.csv";
    case reportCondition.noReport
        catchFilename = "catchTrialOrderNR.csv";
end
% Catch trials per condition (imagery, perception, attention, baseline) summed
% over ALL runs; createCatchTrialOrder puts exactly 2 into every run, so the
% sum must be 2 x design.maxRunNr.
% [change 2026-11-04] was the fixed value [3; 3; 3; 1] (= 5 runs). Now scaled
% from the number of runs: [3 3 3 1] x maxRunNr/5 -> [3 3 3 1] for 5 runs
% (unchanged), [6 6 6 2] if this version is run with 10 runs (MPI set-up in
% main.m), where the fixed value would have stopped createCatchTrialOrder with
% an error.
design.catchDistr = round([3; 3; 3; 1] * design.maxRunNr / 5);
isReport = log.reportCond == reportCondition.report; % no-report catch trials for no-report and dual
catchFile = fullfile(myPaths.subjectDirectory, catchFilename);
if ~isfile(catchFile)
    createCatchTrialOrder(myPaths.subjectDirectory, design.maxRunNr, design.catchDistr,catchFilename, isReport);
end
catchTable = readtable(catchFile);
conditions = ["imagery", "attention", "perception", "baseline"];
if strcmp(modus,'full')
    trialSequence = buildTrialSequence(design.stimLookupTable, conditions, catchTable, log.runNr, isReport);
elseif strcmp(modus,'practice')
    trialSequence = buildPracticeSequence(design.stimLookupTable, conditions);   % [added 2026-11-04] 7 trials
else
    trialSequence = buildTestTrialSequence(design.stimLookupTable, conditions);
end

rows=height(trialSequence);
fprintf('\nRun %d, %s, %s: %d trials (%d catch)\n', log.runNr, char(string(log.reportCond)), modus, rows, ...
    sum(contains(string(trialSequence.condition), "_catch_")));
%% Empty cell arrays to save trial information
log.data.trial                  = zeros(rows,1);
log.data.condition              = cell(rows,1);
log.data.leftEye                = cell(rows,1);
log.data.rightEye               = cell(rows,1);
log.data.cue                    = cell(rows,1);
log.data.rating                 = cell(rows,1);
log.data.vividResponse          = zeros(rows,1);
log.data.vividRT                = zeros(rows,1);
if (log.reportCond == reportCondition.report) || (log.reportCond == reportCondition.dual)
    log.data.response               = cell(rows,1);
    log.data.rt                     = zeros(rows,1);
    log.data.perceived              = cell(rows,1);
    log.data.isAmbiguos          = false(rows,1);
end
if (log.reportCond == reportCondition.noReport) || (log.reportCond == reportCondition.dual)
    log.data.fixDotPosHouse   = cell(rows,1);
    log.data.fixDotPosFace    = cell(rows,1);
    log.data.fixDotCoordHouse = cell(rows,1);
    log.data.fixDotCoordFace  = cell(rows,1);
end
log.data.isCatchTrial         = false(rows,1);

log.data.cueOnset             = zeros(rows,1);
log.data.taskOnset            = zeros(rows,1);
log.data.BROnset              = zeros(rows,1);
log.data.responseOnset        = zeros(rows,1);
log.data.questionOnset        = zeros(rows,1);
log.data.ITIOnset             = zeros(rows,1);


%% Fusion alignment
% Before every run ([changed 2026-11-04] not in 'practice': presentFixDotLocations
% aligned the fusion right before the dot demonstration)
if ~strcmp(modus,'practice')
    participantInfo = display.stereo.alignFusion(ptb, participantInfo);
    questplus.saveFusionOffsets(participantInfo, myPaths);   % default for the next alignment, even if the run is aborted
end
log.horizontalOffset = participantInfo.horizontalOffset;
log.horizontalOffsetInPix = ptb.screenXpixels * log.horizontalOffset;
if ptb.useEyetracker
    eyeRun.subjectNr = int32(str2double(log.sub));eyeRun.runNr=log.runNr;eyeRun.suffix=log.suffix;eyeRun.offline=true;
    ptb = eyetracking.startEyetracker(ptb,eyeRun, ptb.dummymode);
end

%% Trial Procedure
% Instructions [changed 2026-11-10]: everything explicit is on the slides
% shown before the session; the screens remind. Every run ends its
% instructions with the same two screens: the part's task figure, then the
% reminder (keys or "no key", fixation, task letters, colour legend).
%   'training' / 'practice': cue legend, task reminder, rating key check,
%       then the figure in steps (practice: dual), then the reminder
%   'full', run 1 of a part: the figure in steps (screens, + eyes, + keys,
%       + colours and P/A/I/x), then the reminder
%   'full', runs 2-5: the complete figure on one screen, then the reminder
% If a figure file is missing, the old text screens are shown instead.
% Old version: _removed/Code/perImAtOffline_before_steps.m
switch log.reportCond
    case reportCondition.report
        condField = 'report';   newPartText = design.newPartReport;   reminder = design.legendReminderInstructionReport;
    case reportCondition.dual
        condField = 'dual';     newPartText = design.newPartDual;     reminder = design.legendReminderInstructionDual;
    case reportCondition.noReport
        condField = 'noReport'; newPartText = design.newPartNoReport; reminder = design.legendReminderInstructionNoReport;
end
figureFile = ''; figureSteps = {''};
if isfield(myPaths, 'instructionFigurePath') || (isobject(myPaths) && myPaths.hasField('instructionFigurePath'))
    figureFile  = fullfile(myPaths.instructionFigurePath, design.instructionFigure.(condField));
    figureSteps = cellfun(@(f) fullfile(myPaths.instructionFigurePath, f), ...
        design.instructionFigureSteps.(condField), 'UniformOutput', false);
end
firstOfPart = strcmp(modus,"training") || strcmp(modus,"practice") || (strcmp(modus,'full') && log.runNr == 1);
if strcmp(modus,"training") || strcmp(modus,"practice")
    if strcmp(modus,"training")
        display.stereo.instruction(ptb,design, design.Introduction, design.instructionWaitDuration, false);
    end
    display.stereo.legendInstruction(ptb,design, design.cueInstruction, design.instructionWaitDuration, false);
    display.stereo.instruction(ptb,design, design.taskInstruction, design.instructionWaitDuration, false);
    % rating scale + keys on one screen: the subject presses the 5 keys and sees their numbers
    display.stereo.ratingKeyDemo(ptb, design);
end
if firstOfPart
    shown = display.stereo.figureInstruction(ptb, design, figureSteps, design.figureContinue, design.instructionWaitDuration);
else
    shown = display.stereo.figureInstruction(ptb, design, figureFile, design.figureContinue, design.instructionWaitDuration);
end
if ~shown && firstOfPart
    % text fallback (figure files missing)
    if strcmp(modus,'full')
        display.stereo.instruction(ptb,design, newPartText, design.instructionWaitDuration, false);
    else
        switch log.reportCond
            case reportCondition.report
                display.stereo.instruction(ptb,design, design.reportInstructionReport,design.instructionWaitDuration, false);
            case reportCondition.dual
                display.stereo.instruction(ptb,design, design.reportInstructionDual,design.instructionWaitDuration, false);
            case reportCondition.noReport
                display.stereo.instruction(ptb,design, design.reportInstructionNoReport,design.instructionWaitDuration, false);
        end
    end
end
display.stereo.legendInstruction(ptb,design, reminder, design.instructionWaitDuration, false);
display.stereo.instruction(ptb,design, design.waitTillStart, design.waitTillStartDuration, true);

%% Main Experiment<
log = trialProcedurePerImAtOffline(log, design, ptb, myPaths, design.stimLookupTable, trialSequence, rows);

%% Run is over
display.stereo.instruction(ptb, design,design.RunIsOver, design.instructionWaitDuration, false);

%% End of experiment
%% Save data
if strcmp(modus,'training')
    fileName = ['sub-' log.sub '_train_' log.suffix '_' char(datetime('now','Format','yyyy-MM-dd_HHmmss'))];
elseif strcmp(modus,'practice')   % [added 2026-11-04]
    fileName = ['sub-' log.sub '_practice_' log.suffix '_' char(datetime('now','Format','yyyy-MM-dd_HHmmss'))];
else
    fileName = ['sub-' log.sub sprintf('_run-%02d',log.runNr) '_' log.suffix '_' char(datetime('now','Format','yyyy-MM-dd_HHmmss'))];
end

% Convert button presses from key ids to the perceived (house,face,mixed)
if (log.reportCond == reportCondition.report) || (log.reportCond == reportCondition.dual)
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
end
if (log.reportCond == reportCondition.noReport) || (log.reportCond == reportCondition.dual)
    log.data.fixDotPosHouse = cellfun(@(x) strjoin(string(x), ','),log.data.fixDotPosHouse,'UniformOutput', false);
    log.data.fixDotPosFace = cellfun(@(x) strjoin(string(x), ','),log.data.fixDotPosFace,'UniformOutput', false);
    log.data.fixDotCoordHouse = cellfun(@(x) strjoin(string(x), ','),log.data.fixDotCoordHouse,'UniformOutput', false);
    log.data.fixDotCoordFace = cellfun(@(x) strjoin(string(x), ','),log.data.fixDotCoordFace,'UniformOutput', false);
end
log.data.rating(find(log.data.vividResponse==(ptb.Keys.accept))) = {'1'};
log.data.rating(find(log.data.vividResponse==(ptb.Keys.left))) = {'2'};
log.data.rating(find(log.data.vividResponse==(ptb.Keys.right))) = {'3'};
log.data.rating(find(log.data.vividResponse==(ptb.Keys.up))) = {'4'};
log.data.rating(find(log.data.vividResponse==(ptb.Keys.down))) = {'5'};

% [added 2026-11-11] contrasts this run's textures were built with (design.mat is
% overwritten at every start): in the log (log_run-*.mat) and as constant CSV columns
log.trainingFile      = design.trainingFile;       % '' = default or entered by hand
log.stimuliParameters = design.stimuliParameters;  % house, face, left eye, right eye factors
log.textureContrasts  = design.textureContrasts;   % HouseL, FaceL, HouseR, FaceR
[~, tfName, tfExt] = fileparts(char(design.trainingFile));
if isempty(tfName); tfName = 'none (default or entered by hand)'; tfExt = ''; end
nRowsLog = numel(log.data.trial);
log.data.trainingFile   = repmat({[tfName tfExt]}, nRowsLog, 1);
log.data.contrastHouseL = repmat(design.textureContrasts.HouseL, nRowsLog, 1);
log.data.contrastFaceL  = repmat(design.textureContrasts.FaceL,  nRowsLog, 1);
log.data.contrastHouseR = repmat(design.textureContrasts.HouseR, nRowsLog, 1);
log.data.contrastFaceR  = repmat(design.textureContrasts.FaceR,  nRowsLog, 1);

% save the data to csv file
responseTable = struct2table(struct(log.data));
writetable(responseTable, fullfile(myPaths.subjectDirectory, [fileName '.csv']), 'Delimiter',';');

%% close open connections and screen
%eyetracking.closeEyetracker(ptb, myPaths.subjectDirectory);

%Screen('CloseAll');
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


function trialSequence = buildPracticeSequence(stimLookupTable, conditions)
% [added 2026-11-04] Short practice run ('practice', presentFixDotLocations):
% 7 trials = imagery, attention and perception once per cue (house, face)
% + 1 baseline trial. As in the real runs, each condition is a block (the
% cue legend appears before every change of task, trialProcedurePerImAtOffline),
% the block order is random and the order inside a block is random. Which eye
% gets the house is random: for each cue one of the two stimLookupTable rows
% with that cue is drawn (rows 1-2: cue face, rows 3-4: cue house). Baseline:
% one of the rows 1..rows/2, as in buildTrialSequence (its cue is logged as "-").
% No catch trials.
conditions = string(conditions(:));
nRows = height(stimLookupTable);
cues  = string(stimLookupTable.cue);
sets  = cell(1, numel(conditions));
for c = 1:numel(conditions)
    if conditions(c) == "baseline"
        ids = randi(nRows / 2);
    else
        ids = zeros(1, 2);
        cueNames = ["house", "face"];
        for k = 1:2
            rowsWithCue = find(cues == cueNames(k));
            ids(k) = rowsWithCue(randi(numel(rowsWithCue)));
        end
        ids = ids(randperm(numel(ids)));
    end
    ids = stimLookupTable.trialID(ids);
    condNames = repmat(conditions(c), numel(ids), 1);
    sets{c} = table(ids(:), condNames, 'VariableNames', {'trialID','condition'});
end
order = randperm(numel(conditions));
trialSequence = vertcat(sets{order});
end


function trialSequence = buildTestTrialSequence(stimLookupTable, conditions)
% trialSequence: Nx2 numeric array [trialID, conditionIdx]
% stimLookupTable : table 

conditions = string(conditions(:));
rows = height(stimLookupTable);    % total rows in table
% Define how many unique trial IDs per condition
nPer = [rows, rows, rows, rows/2];
repeats = 1;
sets = cell(1,4);
for c = 1:4
    % normal trials
    ids = (1:nPer(c));                     % trial IDs for imagery/attention/perception
    ids = repmat(ids, 1, repeats);       % repeat each id
    ids = ids(randperm(numel(ids)));    % randomize order within block
    condNames = repmat(conditions(c), numel(ids), 1);
    block = table(ids(:), condNames, 'VariableNames', {'trialID','condition'});
    sets{c} = block;
end

% Randomize order of the four blocks and concatenate
order = randperm(4);
trialSequence = vertcat(sets{order});
end
