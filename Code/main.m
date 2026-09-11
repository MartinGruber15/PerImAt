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
stereomodeSequential = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Settings
ptb = PTBSettings(setUp, useEyetracker, stereomodeSequential); % Variables read out by the system and specific to the hardware
myPaths = pathSettings(); % Paths
design = designSettingsVisuals(ptb, myPaths); % Define design of all visually presented elements
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

% Check if subject folder already exists
if isfolder(myPaths.subjectDirectory)
    disp('-> Subject folder already EXISTS.')
else
    % create subject folder
    mkdir(myPaths.subjectDirectory);
    disp('-> Subject folder CREATED.')
end


% Create participantInfo.mat if not existent
if exist(fullfile(myPaths.subjectDirectory, 'participantInfo.mat'),'file') ~= 2
    participantInfo.id = log.sub;
    participantInfo.date = datetime;
    participantInfo = input.participantInformation(ptb, participantInfo);

    % participantInfo.mat speichern
    save(fullfile(myPaths.subjectDirectory, 'participantInfo'),'participantInfo');
else
    fprintf('-> participantInfo.mat for subject %s exists.\n', log.sub);
    load(fullfile(myPaths.subjectDirectory, 'participantInfo.mat'));
end

%% Set key bindings
% key assignment
sub = str2double(log.sub);
if  mod(sub, 2) == 0
    ptb.Keys.house = ptb.Keys.right;
    ptb.Keys.face = ptb.Keys.left;
else
    ptb.Keys.house = ptb.Keys.left;
    ptb.Keys.face = ptb.Keys.right;
end

% Color: colors(1,:) for subjects 0/1 mod 4,
%        colors(2,:) for subjects 2/3 mod 4
colors = design.conditionColors;
colorIdx = floor(mod(sub, 4) / 2) + 1;
design.houseColor = colors(colorIdx, :);
design.faceColor  = colors(3 - colorIdx, :);
design.fontColor = ptb.FontColor;

%% Get instructions
design = getInstructions(log,design,ptb,participantInfo);

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
                ptb = eyetracking.startEyetracker(ptb, eyeRun);
            end
            [log, ptb, design, participantInfo] = imageryAttentionOnset(log, ptb, design, myPaths, participantInfo);
            save_utils.saveEnvironment(log,ptb,design,myPaths, participantInfo)

        case "imagery training" %TODO
            % Input run number and part of the run

            % Run experiment
            onsetRivalryPearson(log, ptb, design, myPaths, participantInfo);

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
