function success = main(setUp)
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

log.report = false;
log.useEyetracker = false;

%% Variables
% Variables read out by the system and specific to the hardware
try
    ptb = PTBSettings(setUp);
catch PTBError
    error('Something went wrong setting up PTB: %s', PTBError.message);
end

%% Paths
myPaths.conditionPath = fullfile('..','condition');
myPaths.stimuliLocation = fullfile('..','stimuli');
myPaths.rawdataPath = fullfile('..','rawdata');
myPaths.monCalDirPath = fullfile('..','monitor_calibration','EIZO_CIN5th_Brightness50_SpectraScan670_derived.mat');

%% Gamma correction
cleanupObj = gamma_correct.apply(ptb.window, myPaths.monCalDirPath);

%% Design related
design.stimSizeInDegrees        = 2.5;      % stimulus size in visual deg.
design.fusionMaskInDegrees      = 4;        % surrounding fusion-aid frame (it is NOT a checkerboard)
design.fixCrossInDegrees        = 0.1;      % Fixtion cross in degrees
design.fixDotSizeInDegrees      = 0.1;      % Fixation dot for no-report

design.maxRunNr                 = 10;
design.waitTillStartDuration    = 3;

% Fixation dot(s) appearance (no-report only)
design.fixDotTransparency       = 0.5;
design.fixDotColor              = [0.25, 0.25, 0.25];

% Compute all screen-related design parameters
design = computeDesignScreenPositions(ptb, design);

% prepare fusion mask texture
fusionMask = imread(fullfile(myPaths.conditionPath, 'background.png'));
fusionMaskResized = imresize(fusionMask, [design.fusionMaskInPixelsX, design.fusionMaskInPixelsY]);
design.backGroundTexture = Screen('MakeTexture', ptb.window, fusionMaskResized);



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
colors = [[102, 255, 0]; [0, 0, 135]];
% Color: colors(1,:) for subjects 0/1 mod 4,
%        colors(2,:) for subjects 2/3 mod 4
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
            eyeRun.subjectNr = log.sub;
            eyeRun.runNr     = log.runNr;
            eyeRun.report    = log.report;
            if ptb.useEyetracker; ptb = eyetracking.startEyetracker(ptb, eyeRun);
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
