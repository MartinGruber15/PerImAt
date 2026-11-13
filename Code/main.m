function main(setUp)
sca;
%Screen('Preference', 'SkipSyncTests', 1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main script for an experiment...
% Author: 
% Date: 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Choose the experiment setup
% CIN-personal, CIN-experimentroom, MPI
if nargin < 1 || isempty(setUp); setUp = 'CIN-experimentroom';end
addpath('utils'); addpath('settings');
fprintf('Running BR experiment with set-up "%s"\n', setUp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ptb = DataContainer();
log = DataContainer();
design = DataContainer();
myPaths = DataContainer();
cleanupObj = onCleanup(@() save_utils.closeAll(ptb, log, design,myPaths)); % make sure every connection and screen get closed in case of an error

log.reportCond = reportCondition.report;
offline = true;
useEyetracker = true;
dummymode = false; % eye tracker dummy mode
debugTrigger = false; % [change 2026-11-03] fMRI version without scanner: true = scanner triggers can be typed as 'w' on a keyboard (tests only)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(setUp,'MPI')
    stereomodeSequential            = true; % true for shutter glasses at MPI
    design.TR                       = 1.75;  % Control and change
    design.nDummies                 = 5;  % Nr of dummies
    design.maxRunNr                 = 10;
else
    stereomodeSequential = false; % true for shutter glasses at MPI
    design.maxRunNr                 = 5;
end
% [change 2026-11-03] the fMRI version (perImAtOnline) always has 10 runs, also when it is
% tested on another set-up (debugTrigger); its catch-trial table
% (2 catch trials per run, perImAtOnline) is built for 10 runs.
if ~offline; design.maxRunNr = 10; end
log.sub = input('Enter subject ID: ', 's');

%% Settings
ptb.debugTrigger = debugTrigger;
ptb = getPTBSettings(ptb, setUp, useEyetracker, stereomodeSequential); % Variables read out by the system and specific to the hardware
myPaths = getPaths(myPaths,log.sub); % Paths
design = getVisualDesignSettings(ptb, myPaths, design); % Define design of all visually presented elements
ptb.dummymode = dummymode;
if offline
    gammaCleanup = gamma_correct.apply(ptb.window, myPaths.monCalDirPath);  %#ok<NASGU> % Gamma correction 
end
%% Additional design elements
design.waitTillStartDuration    = 3;

%% Condition Table
% Condition table
design.stimLookupTable = readtable(fullfile(myPaths.conditionPath,'stimLookupTable.csv'));         % possible stimulus combinations

%% Experimenter input
participantInfo = getParticipantInfo(ptb.Keys, myPaths.subjectDirectory, log.sub);

%% Set key bindings
[design,ptb,log] = getKeyAssignment(design, ptb, log,offline);

%% Get instructions
design = getInstructions(ptb.Keys,design,participantInfo);
% Decide what to do
% experiment or consent form
condition = input.chooseOption(["consent form","main experiment","training","present fixDot locations","key binding training", "BR training", "QUEST+ calibration", "QUEST+ test", "QUEST+ recover"]);
log.task = condition;
% [added 2026-11-11] parts that show the subject's textures: if there is no training
% file, the experimenter decides (Enter = contrast 1.0, m = type the contrasts, the
% textures are then rebuilt, a = abort). Consent, BR training (default contrasts) and
% the calibration (own prior) do not use the training file, so no question there.
if any(condition == ["main experiment", "training", "present fixDot locations", "QUEST+ test"]) && isempty(design.trainingFile)
    if ~confirmUncalibratedContrasts(ptb, myPaths, design); return; end
end

%% Switch case for different tasks
switch condition
    case "consent form"
        ptb.useEyetracker = false;   % no EyeLink in this task (closeAll would try to close it)
        participantInfo = consentForm(log, ptb, design, myPaths, participantInfo);
    case "main experiment"
            % Run main experiment
            [log.reportCond,log.suffix] = input.autoChooseNextBlock(design.maxRunNr, myPaths.subjectDirectory, design.reportOrder);
            log.runNr = input.autoChooseNextRun(design.maxRunNr, myPaths.subjectDirectory, log.suffix);
            if isequal(log.runNr,[]);return;end
            if offline
                [log, ptb, design, participantInfo] = perImAtOffline(log, ptb, design, myPaths, participantInfo, 'full'); %#ok<ASGLU>
            else
                [log, ptb, design, participantInfo] = perImAtOnline(log, ptb, design, myPaths, participantInfo, 'full'); %#ok<UNRCH>
            end

    case "training" 
            % Input run number and part of the run
            log.runNr=1;
            ptb.useEyetracker = false;
            [log.reportCond,log.suffix] = input.chooseNextBlock(design.reportOrder,[]);
            if offline
                [~, ~, design, participantInfo] = perImAtOffline(log, ptb, design, myPaths, participantInfo,'training'); %#ok<ASGLU>
            else
                [~, ~, design, participantInfo] = perImAtOnline(log, ptb, design, myPaths, participantInfo,'training'); %#ok<UNRCH>
            end
    case "present fixDot locations"
        % fixation-dot positions (one after another, then all; house, then face),
        % then a 7-trial practice of the whole task in the dual condition
        % (perImAtOffline 'practice', [changed 2026-11-04])
        log.runNr = 1;
        ptb.useEyetracker = false;
        participantInfo = presentFixDotLocations(log, ptb, design, myPaths, participantInfo);
    case "key binding training"
        ptb.useEyetracker = false;
        keyBindingTraining(ptb, design, myPaths);
    case "BR training"
        % sustained rivalry, 2 x design.brTrainingDuration s, default contrasts
        ptb.useEyetracker = false;
        participantInfo = binocularRivalryTraining(log, ptb, design, myPaths, participantInfo);
    case "QUEST+ calibration"
        % adaptive calibration of house/face and left/right-eye contrasts
        % (utils/+questplus/README.md); saves <sub>_training_<n>.mat
        log.runNr = 1;
        ptb.useEyetracker = false;
        participantInfo = questPlusCalibration(log, ptb, design, myPaths, participantInfo);
    case "QUEST+ test"
        % test the contrasts of the latest training file (loaded at start-up)
        log.runNr = 1;
        ptb.useEyetracker = false;
        participantInfo = questPlusTest(log, ptb, design, myPaths, participantInfo);
    case "QUEST+ recover"
        % [added 2026-11-10] contrasts of an interrupted calibration (checkpoint
        % after every trial): choose a set and save it as <sub>_training_<n>.mat
        ptb.useEyetracker = false;
        questplus.recoverCalibration(log, myPaths);
end    
save(fullfile(myPaths.subjectDirectory, 'participantInfo.mat'), "participantInfo")   % was saved as <rawdata>/sub-XX.mat
end


function ok = confirmUncalibratedContrasts(ptb, myPaths, design)
% [added 2026-11-11] no <sub>_training_<n>.mat: continue with contrast 1.0, type the
% contrasts (textures rebuilt by getVisualDesignSettings), or abort
fprintf(2, ['\nNo training file (<sub>_training_<n>.mat) for this subject: the textures use contrast 1.0\n' ...
    '(house, face, left eye, right eye).\n']);
while true
    a = lower(strtrim(input('Enter = continue with 1.0 | m = enter the contrasts by hand | a = abort: ', 's')));
    switch a
        case ''
            ok = true; return
        case 'm'
            [sp, savedFile] = loadLatestTrainingParameters(myPaths.subjectDirectory, true);   % asks, may save <sub>_training_1.mat
            sp.savedFile = savedFile;
            design.stimuliParametersOverride = sp;
            getVisualDesignSettings(ptb, myPaths, design);   % rebuilds the textures (design is a handle object)
            ok = true; return
        case 'a'
            fprintf('Aborted.\n'); ok = false; return
        otherwise
            fprintf('Please press Enter or type m or a.\n');
    end
end
end
