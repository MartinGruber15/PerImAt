function binocularRivalryTraining(log, ptb, design, myPaths)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%BinocularRivalryTraining: shows two rivaling stimuli in a BR fashion for
%subjects to get used to BR
%   Since subjects might not experience rivalry, when exposed to rivaling
%   stimuli in the beginning, we have a two minute training session in
%   which two stimuli rival with each other, which are not used in the
%   experiment later
%   input:
%       log - struct tracking the data gathered in a trial
%       ptb - struct containing information about Psychtoolbox parameters
%       design - struct containing information about experimental design
%       myPaths - struct containing the paths (e.g. to the stimuli)
%       participantInfo - struct containing data about the participant 
%                           (e.g. language)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Timing
design.stimulusPresentationTime = 3  - ptb.ifi/2; %TODO change
design.waitTillStartDuration    = 3 - ptb.ifi/2;
design.instructionWaitDuration  = 0.5;
design.ITI = 2 - ptb.ifi/2;
design.useET = false;

% Initialising empty array to save stimulus onset in
log.data.stimOnset = [];
log.data.stimOffset = [];

% % ----for compatibility reasons----
log.data.trueEye = {''};
log.data.congruentStimulus      = {''};
log.data.incongruentStimulus    = {''};
log.data.trialID                = {1};
log.data.congruentColor         = {''};
% %----------------------------------

participantInfo = display.stereo.alignFusion(ptb);

% Paths to stimuli
faceImg = design.stimuli.face;
houseImg = design.stimuli.house;

%% Stop and remove events in queue
KbQueueStop(ptb.Keyboard2);
KbEventFlush(ptb.Keyboard2);
KbQueueStop(ptb.Keyboard1);
KbEventFlush(ptb.Keyboard1);

% restart KbQueues
KbQueueStart(ptb.Keyboard2); % Subjects
KbQueueStart(ptb.Keyboard1); % Experimentors

%% Show instructions
display.stereo.instruction(ptb, log, design.waitTillStart, design.waitTillStartDuration, true);

%% Experiment start
% show a fixcross
log.runNr = 1;

draw.stereo.blanks(ptb, design);
fixCrossOnset = Screen('Flip',ptb.window);

% Draw and show stimuli
draw.stereo.images(ptb,design,faceImg,houseImg);
log.data.stimOnset = Screen('Flip', ptb.window, fixCrossOnset + design.ITI);

% show a fixcross
draw.stereo.blanks(ptb,design);
log.data.stimOffset = Screen('Flip',ptb.window, log.data.stimOnset+ design.stimulusPresentationTime);
log.end = 'Success';
log = save_utils.savedata(log, ptb, design, participantInfo, myPaths);
[resultsTable1, ~] = save_utils.formatResponses(log,ptb);

log.runNr = 2;
KbQueueStop(ptb.Keyboard2);
KbEventFlush(ptb.Keyboard2);
KbQueueStop(ptb.Keyboard1);
KbEventFlush(ptb.Keyboard1);
KbQueueStart(ptb.Keyboard2);
KbQueueStart(ptb.Keyboard1);

% Draw and show stimuli on different sides
draw.stereo.images(ptb,design,houseImg,faceImg);
log.data.stimOnset = Screen('Flip', ptb.window, log.data.stimOffset + design.ITI);

% Run is over
log.data.stimOffset = Screen ('Flip', ptb.window, log.data.stimOnset + design.stimulusPresentationTime);
display.stereo.instruction(ptb,log,design.RunIsOver,design.instructionWaitDuration,false);
log.end = 'Success';
log = save_utils.savedata(log, ptb, design, participantInfo, myPaths);
[resultsTable2, success] = save_utils.formatResponses(log,ptb);

%% End of experiment
Screen('CloseAll')
ListenChar(1); % enable input to matlab windows
inv = ptb.Keys.house == ptb.Keys.right;
% display some overview statistics for the experimenter
if success
    totalDominanceHouse = sum(resultsTable1.durations(strcmp(resultsTable1.percepts, 'house'))) + sum(resultsTable2.durations(strcmp(resultsTable2.percepts, 'house')));
    totalDominanceFace = sum(resultsTable1.durations(strcmp(resultsTable1.percepts, 'face'))) + sum(resultsTable2.durations(strcmp(resultsTable2.percepts, 'face')));
    totalMixed = sum(resultsTable1.durations(strcmp(resultsTable1.percepts, 'mixed'))) + sum(resultsTable2.durations(strcmp(resultsTable2.percepts, 'mixed')));
    if inv
        totalLeftEye = sum(resultsTable1.durations(strcmp(resultsTable1.percepts, 'face'))) + sum(resultsTable2.durations(strcmp(resultsTable2.percepts, 'house')));
        totalRightEye = sum(resultsTable1.durations(strcmp(resultsTable1.percepts, 'house'))) + sum(resultsTable2.durations(strcmp(resultsTable2.percepts, 'face')));
    else    
        totalLeftEye = sum(resultsTable1.durations(strcmp(resultsTable1.percepts, 'house'))) + sum(resultsTable2.durations(strcmp(resultsTable2.percepts, 'face')));
        totalRightEye = sum(resultsTable1.durations(strcmp(resultsTable1.percepts, 'face'))) + sum(resultsTable2.durations(strcmp(resultsTable2.percepts, 'house')));
    end

    fprintf('Relative dominance duration house/face = %f \n',totalDominanceHouse/(totalDominanceFace+totalDominanceHouse));
    fprintf('Relative dominance duration face/house = %f \n',totalDominanceFace/(totalDominanceFace+totalDominanceHouse));
    fprintf('Relative dominance duration mixed = %f \n',(totalMixed /(totalDominanceHouse+totalDominanceFace+totalMixed)));
    fprintf('Relative dominance duration left/right eye = %f \n',totalLeftEye/(totalLeftEye+totalRightEye));
    fprintf('Relative dominance duration right/left eye = %f \n',totalRightEye/(totalLeftEye+totalRightEye));

else
    fprintf('Could not get results table');
end
input.adaptStimuli(log,myPaths);

end