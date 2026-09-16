function main(setUp)
Screen('Preference', 'SkipSyncTests', 1); %TODO
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
log.report = false;
useEyetracker = false; 
stereomodeSequential = false; % true for shutter glasses at MPI
dummymode = true; % eye tracker dummy mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Settings
ptb = getPTBSettings(setUp, useEyetracker, stereomodeSequential); % Variables read out by the system and specific to the hardware
myPaths = getPaths(); % Paths
design = getVisualDesignSettings(ptb, myPaths); % Define design of all visually presented elements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TODO reinclude (but with correct file)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%cleanupObj = gamma_correct.apply(ptb.window, myPaths.monCalDirPath); % Gamma correction %#ok<NASGU> 

%% Additional design elements
design.TR                       = 1.75;  % Control and change
design.nDummies                 = 5;  % Nr of dummies
design.maxRunNr                 = 10;
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
design = getInstructions(design,participantInfo);

% Decide what to do
% experiment or consent form
condition = input.chooseOption(["main experiment", "imagery training","consent form"]);
log.task = condition;
%% Switch case for different tasks
%try
    switch condition
        case "main experiment"
            % Run main experiment
            log.runNr = input.autoChooseNextRun(design.maxRunNr, myPaths.subjectDirectory);
            if ptb.useEyetracker
                eyeRun.subjectNr = log.sub;eyeRun.runNr=log.runNr;eyeRun.report= log.report;
                ptb = eyetracking.startEyetracker(ptb, eyeRun, dummymode);
            end
            [log, ptb, design, participantInfo] = imageryAttentionOnset(log, ptb, design, myPaths, participantInfo, 'full');
            save_utils.saveEnvironment(log,ptb,design,myPaths, participantInfo)

        case "imagery training" 
            % Input run number and part of the run
            ptb.useEyetracker = false;
            [~, ~, ~, participantInfo] = imageryAttentionOnset(log, ptb, design, myPaths, participantInfo,'testing'); %#ok<ASGLU>

        case "consent form"
             % Display consent form
            log = consentForm(log, ptb, design);
            save(fullfile(myPaths.subjectDirectory, ['consent_log_' char(datetime('now','Format','yyyy-MM-dd_HHmmss'))]),'log');
    end
%catch ME
%    save(fullfile(myPaths.subjectDirectory, ['log_' char(datetime)]),'log');
%    rethrow(ME)
%end
end

% catch file no report: run, condition, cue, stimL, stimR, dots