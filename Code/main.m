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
if nargin < 1 || isempty(setUp); setUp = 'personal';end
addpath('utils'); addpath('settings');
fprintf('Running BR experiment with set-up "%s"\n', setUp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ptb = DataContainer();
log = DataContainer();
design = DataContainer();
myPaths = DataContainer();

log.reportCond = reportCondition.report;
offline = true;
useEyetracker = false;
dummymode = false; % eye tracker dummy mode
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

%% Settings
ptb = getPTBSettings(ptb, setUp, useEyetracker, stereomodeSequential); % Variables read out by the system and specific to the hardware
myPaths = getPaths(myPaths); % Paths
design = getVisualDesignSettings(ptb, myPaths, design); % Define design of all visually presented elements
cleanupObj = onCleanup(@() closeAll(ptb, log, design,myPaths)); % make sure every connection and screen get closed in case of an error
ptb.dummymode = dummymode;
if offline
    gammaCleanup = gamma_correct.apply(ptb.window, myPaths.monCalDirPath);  %#ok<NASGU> % Gamma correction 
end
%% Additional design elements
design.waitTillStartDuration    = 3;
showDotPositions(ptb,design,myPaths.stimuliLocation)

%% Condition Table
% Condition table
design.stimLookupTable = readtable(fullfile(myPaths.conditionPath,'stimLookupTable.csv'));         % possible stimulus combinations

%% Experimenter input
% Input subject number -> ID
log.sub = input('Enter subject ID: ', 's');
myPaths.subjectDirectory = fullfile(myPaths.rawdataPath,['sub-', log.sub]);
participantInfo = getParticipantInfo(ptb.Keys, myPaths.subjectDirectory, log.sub);

%% Set key bindings
[design,ptb,log] = getKeyAssignment(design, ptb, log,offline);

%% Get instructions
design = getInstructions(ptb.Keys,design,participantInfo);

% Decide what to do
% experiment or consent form
condition = input.chooseOption(["main experiment","training","present fixDot locations"]);
log.task = condition;

%% Switch case for different tasks
switch condition
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
            %save_utils.saveEnvironment(log,ptb,design,myPaths, participantInfo)

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
            presentFixDotLocations(ptb, design, myPaths.stimuliLocation);
end    
end

function closeAll(ptb, log, design,myPaths)
disp('Closing open connections and saving data')
% Eye tracker
if isfield(ptb, 'useEyetracker') && ptb.useEyetracker && isfield(myPaths,'subjectDirectory')
    try
        eyetracking.closeEyetracker(ptb, myPaths.subjectDirectory);
    catch ME
        warning('Could not close EyeLink properly: %s', ME.message);
    end
end

% DataPixx
if isfield(ptb, 'usedatapixx') && ptb.usedatapixx
    try
        Datapixx('Close');
    catch ME
        warning('Could not close DataPixx: %s', ME.message);
    end
end

% Psychtoolbox
try
    Screen('CloseAll');
catch ME
    warning('Could not close Psychtoolbox: %s', ME.message);
end

% Save log LAST
if isfield(myPaths,'subjectDirectory')
try
    %save_utils.saveEnvironment(log,ptb,design,myPaths)
    disp('TODO reinclude log (etc) saving')
catch ME
    warning('Could not save ptb data: %s', ME.message);
end
end
end
