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
originalGamma = repmat(linspace(0,1,256)', 1, 3);
% Load gamma file
gammaFile = load(myPaths.monCalDirPath);
gammaTable = gammaFile.cal.iGammaTable;
% Clean tiny noise
gammaTable(gammaTable < 1e-6) = 0;
%Screen('LoadNormalizedGammaTable', ptb.window, gammaTable);
% Clean up and return to the original gamma file if something happens
%cleanupObj = onCleanup(@() safeRestoreGamma(ptb.window, originalGamma));

%% Design related
design.useET = false;
design.stimSizeInDegrees        = 2.5;      % stimulus size in visual deg.
design.grayBackgroundInDegrees  = 2;        % grey frame side length in visual deg  
design.fusionMaskInDegrees   = 4;        % surrounding fusion-aid frame (it is NOT a checkerboard)
design.fixCrossInDegrees        = 0.1;      % Fixtion cross in degrees
design.maxRunNr                 = 10; %TODO?

% compute the corresponding pixel values given the specific technical setup
design.stimSizeInPixelsX        = round(ptb.PixPerDegWidth*design.stimSizeInDegrees); 
design.stimSizeInPixelsY        = round(ptb.PixPerDegHeight*design.stimSizeInDegrees);
design.fixCrossInPixelsX        = round(ptb.PixPerDegWidth*design.fixCrossInDegrees);
design.fixCrossInPixelsY        = round(ptb.PixPerDegHeight*design.fixCrossInDegrees);
design.fusionMaskInPixelsX       = int16(round(ptb.PixPerDegWidth*design.fusionMaskInDegrees));
design.fusionMaskInPixelsY       = int16(round(ptb.PixPerDegHeight*design.fusionMaskInDegrees)); 

% prepare fusion mask texture
fusionMask = imread(fullfile(myPaths.conditionPath, 'background.jpg'));
fusionMaskResized = imresize(fusionMask, [design.fusionMaskInPixelsX, design.fusionMaskInPixelsY]);
design.backGroundTexture = Screen('MakeTexture', ptb.window, fusionMaskResized);

%% Fixation cross 
% Fixation cross position
design.fixCrossCoords = [
    -design.fixCrossInPixelsX/2 design.fixCrossInPixelsX/2 0 0; ...
    0 0 -design.fixCrossInPixelsY/2 design.fixCrossInPixelsY/2];

%% destination rectangle
% Define a rectangle where the stimulus is drawn
design.destinationRect = [...
    ptb.screenXpixels/2 - design.stimSizeInPixelsX/2, ...
    ptb.screenYpixels/2 - design.stimSizeInPixelsY/2, ...
    ptb.screenXpixels/2 + design.stimSizeInPixelsX/2, ...
    ptb.screenYpixels/2 + design.stimSizeInPixelsY/2];

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
    participantInfo = inputParticipantInformation(ptb, participantInfo);

    % participantInfo.mat speichern
    save(fullfile(myPaths.subjectDirectory, 'participantInfo'),'participantInfo');
else
    fprintf('-> participantInfo.mat for subject %s exists.\n', log.sub);
    load(fullfile(myPaths.subjectDirectory, 'participantInfo.mat'));
end

%% Set key bindings
% key assignment
if  mod(str2double(log.sub), 2) == 0
    ptb.Keys.house = ptb.Keys.right;
    ptb.Keys.face = ptb.Keys.left;
else
    ptb.Keys.house = ptb.Keys.left;
    ptb.Keys.face = ptb.Keys.right;
end

%% Get instructions
design = getInstructions(log,design,ptb,participantInfo);

% Decide what to do
% experiment or consent form
condition = chooseOption(["main experiment", "imagery training","consent form"]);
log.task = condition;
%% Switch case for different tasks
%try
    switch condition
        case "main experiment"
            % Run main experiment
            log.runNr = inputRun(design.maxRunNr);
            [log, ptb, design, participantInfo] = imageryAttentionOnset(log, ptb, design, myPaths, participantInfo);
            %saveEnvironment(log,ptb,design,myPaths, participantInfo)

        case "imagery training"
            % Input run number and part of the run

            % Run experiment
            onsetRivalryPearson(log, ptb, design, myPaths, participantInfo);
            %saveEnvironment(log,ptb,design,myPaths, participantInfo);

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

%% Functions
function choice = chooseOption(options)
% chooseOption  Prompt user to choose from a list of options
%   options : cellstr or string array of labels
%   returns choice (string)
options = string(options(:)); % column vector

% Print numbered menu (0-based)
fprintf('%s\n', 'Choose an option.');
for k = 0:numel(options)-1; fprintf('  %s  - %d\n', char(options(k+1)), k);end

% Read and validate
validInput = false;
while ~validInput
    s = input('Enter number: ', 's');
    [v, choice] = str2num(s);
    if choice && isscalar(v) && v==floor(v) && v>=0 && v<=numel(options)-1
        choice = options(v+1);
        validInput = true;
    else
        fprintf('Please input an integer between 0 and %d.\n', numel(options)-1);
    end
end
end

function runNr = inputRun(maxRun)
% Function to enter run number
    if nargin < 1
        maxRun = 2;
    end
    
    correctRunInput = false;
    % check run input
    while ~correctRunInput
        runNr = input(['Enter run  Nr [1-' num2str(maxRun) ']:'], 's');
        [runNr,isNumber] = str2num(runNr);
        if isNumber && runNr>0 && runNr<=maxRun
            correctRunInput = true;
        end
    end
end

function saveEnvironment(log,ptb,design,myPaths, participantInfo)
timestamp = char(datetime('now','Format','yyyy-MM-dd_HHmmss'));
save(fullfile(myPaths.subjectDirectory, ['ptb_' timestamp '.mat']),'ptb');
save(fullfile(myPaths.subjectDirectory, ['log_' timestamp '.mat']),'log');
save(fullfile(myPaths.subjectDirectory, ['design_' timestamp '.mat']),'design');
save(fullfile(myPaths.subjectDirectory, 'participantInfo.mat'), 'participantInfo');

end

function safeRestoreGamma(win, originalGamma)
try
    if Screen('WindowKind', win) ~= 0
        Screen('LoadNormalizedGammaTable', win, originalGamma);
    end
catch
    % fallback: restore to desktop screen
    Screen('LoadNormalizedGammaTable', 0, originalGamma);
end
end