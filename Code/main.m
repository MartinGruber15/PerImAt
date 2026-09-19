function main(setUp)
sca;
Screen('Preference', 'SkipSyncTests', 1); %TODO
Screen('Preference', 'Verbosity', 1);  % Only Errors + warnings
opacity = 0.8;
PsychDebugWindowConfiguration([], opacity)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main script for an experiment...
% Author: Martin Gruber
% Date: 09/12/2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Choose the experiment setup
% CIN-personal, CIN-experimentroom, MPI
if nargin < 1 || isempty(setUp); setUp = 'CIN-personal';end
addpath('utils'); addpath('settings');
fprintf('Running BR experiment with set-up "%s"\n', setUp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log.reportCond = reportCondition.noReport;
offline = false;
useEyetracker = false;
dummymode = false; % eye tracker dummy mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if offline
    stereomodeSequential = false; % true for shutter glasses at MPI
    design.maxRunNr                 = 5;
else
    stereomodeSequential            = true; % true for shutter glasses at MPI
    design.TR                       = 1.75;  % Control and change
    design.nDummies                 = 5;  % Nr of dummies
    design.maxRunNr                 = 10;
end

%% Settings
ptb = getPTBSettings(setUp, useEyetracker, stereomodeSequential); % Variables read out by the system and specific to the hardware
myPaths = getPaths(); % Paths
design = getVisualDesignSettings(ptb, myPaths, design); % Define design of all visually presented elements

if offline
    cleanupObj = gamma_correct.apply(ptb.window, myPaths.monCalDirPath);  %#ok<UNRCH> % Gamma correction 
end
%% Additional design elements
design.waitTillStartDuration    = 3;

%% Condition Table
% Condition table
design.stimLookupTable = readtable(fullfile(myPaths.conditionPath,'stimLookupTable.csv'));         % possible stimulus combinations

%% Experimenter input
% Input subject number -> ID
log.sub = input('Enter subject ID: ', 's');
myPaths.subjectDirectory = fullfile(myPaths.rawdataPath,['sub-', log.sub]);
participantInfo = getParticipantInfo(ptb.Keys, myPaths.subjectDirectory, log.sub);

%% Set key bindings
[design,ptb] = getKeyAssignment(design, ptb, log.sub);

%% Get instructions
design = getInstructions(ptb.Keys,design,participantInfo);

% Decide what to do
% experiment or consent form
condition = input.chooseOption(["offline experiment", "online experiment","offline training","online training","present fixDot locations","consent form"]);
log.task = condition;
if log.reportCond == reportCondition.report
    log.suffix = 'r';
elseif log.reportCond == reportCondition.noReport
    log.suffix = 'nr';
else 
    log.suffix = 'du';
end

%% Switch case for different tasks
try
    switch condition
        case "offline experiment"
            % Run main experiment
            log.runNr = input.autoChooseNextRun(design.maxRunNr, myPaths.subjectDirectory, log.suffix);
            if ptb.useEyetracker
                eyeRun.subjectNr = int32(str2double(log.sub));eyeRun.runNr=log.runNr;eyeRun.suffix=log.suffix;
                ptb = eyetracking.startEyetracker(ptb, eyeRun, dummymode);
            end
            [log, ptb, design, participantInfo] = perImAtOffline(log, ptb, design, myPaths, participantInfo, 'full');
            %save_utils.saveEnvironment(log,ptb,design,myPaths, participantInfo)
        
        case "online experiment"
            % Run main experiment
            log.runNr = input.autoChooseNextRun(design.maxRunNr, myPaths.subjectDirectory, log.suffix);
            if ptb.useEyetracker
                eyeRun.subjectNr = int32(str2double(log.sub));eyeRun.runNr=log.runNr;eyeRun.suffix=log.suffix;
                ptb = eyetracking.startEyetracker(ptb, eyeRun, dummymode);
            end
            [log, ptb, design, participantInfo] = perImAtOnline(log, ptb, design, myPaths, participantInfo, 'full');
            %save_utils.saveEnvironment(log,ptb,design,myPaths, participantInfo)

        case "offline training" 
            % Input run number and part of the run
            log.runNr=1;
            ptb.useEyetracker = false;
            [~, ~, ~, participantInfo] = perImAtOffline(log, ptb, design, myPaths, participantInfo,'testing'); %#ok<ASGLU>

        case "online training" 
            % Input run number and part of the run
            log.runNr=1;
            ptb.useEyetracker = false;
            [~, ~, ~, participantInfo] = perImAtOnline(log, ptb, design, myPaths, participantInfo,'testing'); %#ok<ASGLU>
        case "present fixDot locations"
            presentFixDotLocations(ptb, design, myPaths.stimuliLocation);
        case "consent form"
             % Display consent form
            log = consentForm(log, ptb, design);
            save(fullfile(myPaths.subjectDirectory, ['consent_log_' char(datetime('now','Format','yyyy-MM-dd_HHmmss'))]),'log');
    end
catch ME
    if ptb.useEyetracker
        eyetracking.closeEyetracker(ptb, myPaths.subjectDirectory);
    end
    if ptb.usedatapixx
        Datapixx('Close');
    end
    Screen('CloseAll');
    save(fullfile(myPaths.subjectDirectory, ['log_' char(datetime)]),'log');
    rethrow(ME)
end
end
