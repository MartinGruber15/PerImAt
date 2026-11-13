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

% Changes made on 2026-11-03 are marked with "[change 2026-11-03]" (search for it);
% each says what was changed and why. Not changed: trial structure, durations,
% number of trials per run (28 + 2 catch trials), number of runs (10).
% Changes made on 2026-11-04 are marked with "[change 2026-11-04]" (catch-trial
% numbers, new-part screen at the first run of a report condition).

%% FYA - Choose modus
% testing vs full
%modus = 'testing';

%% Timing
design.instructionWaitDuration  = 0.5;

design.stimulusPresentationTime = 3 - ptb.ifi/2; % rivalry 3 s [changed 2026-11-06, was 1.5 s]
% [changed 2026-11-06] 3 s as in the offline version (perImAtOffline) and the QUEST+
% calibration/test. A trial now lasts 12 s instead of 10.5 s (cue 1 + task 2 + rivalry 3
% + response 2 + mask 2 + ITI 2; +2 s for the first cue of a miniblock), i.e. no longer a
% multiple of the TR (1.75 s), and a run is ~45 s longer: adapt the number of volumes.
% [changed 2026-11-11] task 6 s as offline (was 2 s), blank ITI 5 s (was 2 s): trial
% cue 1 + task 6 + rivalry 3 + response 2 + mask 2 + ITI 5 = 19 s (21 s for the first
% cue of a miniblock); run 30 x 19 + 4 x 2 = 578 s (TR 1.75 s, preliminary: 330.3 volumes).
design.taskDuration             = 6 - ptb.ifi/2;
design.ITI                      = 5 - ptb.ifi/2;
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
% Catch trials per condition (imagery, perception, attention, baseline) summed
% over ALL runs; createCatchTrialOrder puts exactly 2 into every run, so the
% sum must be 2 x design.maxRunNr.
% [change 2026-11-04] was the fixed value [6; 6; 6; 2] (= 10 runs). Now scaled
% from the number of runs: [3 3 3 1] x maxRunNr/5 -> [6 6 6 2] for the 10 runs
% of this version (main.m), i.e. the same catch trials as before; it only
% avoids an error if maxRunNr is ever set differently (createCatchTrialOrder
% requires sum = 2 x maxRunNr).
design.catchDistr = round([3; 3; 3; 1] * design.maxRunNr / 5);
isReport = log.reportCond == reportCondition.report;
catchFile = fullfile(myPaths.subjectDirectory, catchFilename);
if ~isfile(catchFile)
    createCatchTrialOrder(myPaths.subjectDirectory, design.maxRunNr,design.catchDistr, catchFilename, isReport);
end
catchTable = readtable(catchFile);
conditions = ["imagery", "attention", "perception", "baseline"];
if strcmp(modus,'full')
    trialSequence = buildTrialSequence(design.stimLookupTable, conditions, catchTable, log.runNr, isReport);
else
    trialSequence = buildTestTrialSequence(design.stimLookupTable, conditions);
end

rows=height(trialSequence);
% [change 2026-11-03] removed the debug line "rows = 3; %TODO remove", which ran only the
% first 3 trials of every run. Now the whole sequence is run: 2 x (4 + 4 + 4 + 2)
% trials (stimLookupTable) + 2 catch trials = 30 trials in every run.
% [change 2026-11-03] one line per run for the experimenter (replaces nothing).
fprintf('\nRun %d, %s, %s: %d trials (%d catch)\n', log.runNr, char(string(log.reportCond)), modus, rows, ...
    sum(contains(string(trialSequence.condition), "_catch_")));

%% Empty cell arrays to save trial information
log.data.trial                  = zeros(rows,1);
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
% [change 2026-11-03] new column: time of the scanner volume at which the run started (first
% volume after the dummies, mri.waitForTrigger; same GetSecs clock as all
% onsets, so onset - scanStart = time since the start volume). NaN in training.
log.data.scanStart            = nan(rows,1);

log.data.cueOnset             = zeros(rows,1);
log.data.taskOnset            = zeros(rows,1);
log.data.BROnset              = zeros(rows,1);
log.data.responseOnset        = zeros(rows,1);
log.data.maskOnset            = zeros(rows,1);
log.data.ITIOnset             = zeros(rows,1);


%% Trial Procedure
if strcmp(modus,"training")
    display.stereo.instruction(ptb,design, design.Introduction, design.instructionWaitDuration, false);
    display.stereo.legendInstruction(ptb,design, design.cueInstruction, design.instructionWaitDuration, false);
    display.stereo.instruction(ptb,design, design.taskInstruction, design.instructionWaitDuration, false);
    switch log.reportCond
        case reportCondition.report
            display.stereo.instruction(ptb,design, design.reportInstructionReport,design.instructionWaitDuration, false);
        case reportCondition.noReport
            display.stereo.instruction(ptb,design, design.reportInstructionNoReport,design.instructionWaitDuration, false);
    end
    % [change 2026-11-03] removed the rating instruction (design.questionInstruction):
    % there is no 1-5 rating in this version.
end
% [change 2026-11-04] First run of a report condition (the runs are blocked:
% 10 runs of one condition, then the other): a screen that says that the task
% with the images changes and what to do now (getInstructions: newPart<Condition>Fmri,
% without the rating, which this version does not have).
if strcmp(modus,'full') && log.runNr == 1
    if log.reportCond == reportCondition.noReport
        display.stereo.instruction(ptb,design, design.newPartNoReportFmri, design.instructionWaitDuration, false);
    else
        display.stereo.instruction(ptb,design, design.newPartReportFmri, design.instructionWaitDuration, false);
    end
end
if log.reportCond == reportCondition.noReport
    display.stereo.legendInstruction(ptb,design, design.legendReminderInstructionNoReport,design.instructionWaitDuration, false);
else
    display.stereo.legendInstruction(ptb,design, design.legendReminderInstructionReport,design.instructionWaitDuration, false);
end
display.stereo.instruction(ptb, design,design.fixOnFixCross, design.instructionWaitDuration, false);

%% Calibrate Eye Tracker
if ptb.useEyetracker
    eyeRun.subjectNr = int32(str2double(log.sub));eyeRun.runNr=log.runNr;eyeRun.suffix=log.suffix;eyeRun.offline=0;
    ptb = eyetracking.startEyetracker(ptb,eyeRun, ptb.dummymode);
end

%% Start: scanner trigger (full run) or countdown (training)
% [change 2026-11-03] Before, the call "log = mri.waitForTrigger(...)" was commented out and
% two debug lines set design.nDummies = 5 and added 'w' to the key list after
% the key queue had already been created (no effect). The run then started
% after the 3 s countdown, not with the scanner. Now:
%   full run: "the run starts in a moment" screen, wait for design.nDummies
%             dummy triggers (main.m: 5 at the MPI), the first trial starts at
%             the next trigger (log.scanStart);
%   training: the 3 s countdown as before (no scanner).
if strcmp(modus, 'full')
    % the trigger key exists at the MPI (scanner) or with debugTrigger in main.m
    % (typed 'w', for tests without scanner; then no dummies unless set in main.m)
    if ~ptb.Keys.hasField('trg')
        error('perImAtOnline:noTrigger', ['No scanner trigger on set-up "%s". To test without a scanner, ' ...
            'set debugTrigger = true in main.m and type ''w''.'], ptb.SetUp);
    end
    if ~design.hasField('nDummies'); design.nDummies = 0; end
    % stays on screen until the first trial is drawn
    display.stereo.instruction(ptb, design, design.waitForScanner, 0, true);
    log = mri.waitForTrigger(ptb, log, design);
    log.scanStart = log.trigger.firstExperimentTR;   % the first trial starts at this volume (trialProcedurePerImAtOnline)
else
    display.stereo.instruction(ptb,design, design.waitTillStart, design.waitTillStartDuration, true);
end

log = trialProcedurePerImAtOnline(log, design, ptb, myPaths, design.stimLookupTable, trialSequence, rows);

%% Run is over
display.stereo.instruction(ptb, design, design.RunIsOver, design.instructionWaitDuration, false);

%% End of experiment
%% Save data
if strcmp(modus,'training')
    fileName = ['sub-' log.sub '_train_' log.suffix '_' char(datetime('now','Format','yyyy-MM-dd_HHmmss'))];
else
    fileName = ['sub-' log.sub sprintf('_run-%02d',log.runNr) '_' log.suffix '_' char(datetime('now','Format','yyyy-MM-dd_HHmmss'))];
end
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
if log.hasField('scanStart'); log.data.scanStart(:) = log.scanStart; end   % [change 2026-11-03] see log.data.scanStart above

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
%if ptb.usedatapixx
%    Datapixx('Close');
%end
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
