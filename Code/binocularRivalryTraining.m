function participantInfo = binocularRivalryTraining(log, ptb, design, myPaths, participantInfo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% binocularRivalryTraining: sustained binocular rivalry so that subjects get
% used to rivalry and to reporting it continuously.
%   Two presentations of design.brTrainingDuration seconds each (default 60 s,
%   set in getInstructions): face left / house right, then house left / face
%   right. The stimuli are shown at their DEFAULT contrast (house.png and
%   face.png as stored, contrast 1 for both stimuli and both eyes), not with
%   the subject's calibrated contrasts, on pink noise as in the experiment.
%   Continuous report: hold the key of the image that is clearly dominant,
%   hold the lower key (ptb.Keys.accept) for mixed percepts, as in the rest
%   of the experiment [changed 2026-11-10, was: release all keys]. No key
%   held = 'none', two keys held = 'mixed' (save_utils.formatResponses).
%   Results: sub-XX_BRtraining_run-1.csv / run-2.csv and dominance summary in
%   the command window. No training (contrast) file is written.
%   input:
%       log, ptb, design, myPaths - as in main
%       participantInfo - struct with language etc. (fusion offsets are added)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 5 || isempty(participantInfo); participantInfo = struct; end

%% Timing
duration = design.brTrainingDuration;            % s per presentation
design.instructionWaitDuration  = 0.5;
design.ITI = 2 - ptb.ifi/2;
design.useET = false;

% ----for compatibility with save_utils.savedata / formatResponses----
log.data.stimOnset = [];
log.data.stimOffset = [];
log.data.trueEye = {''};
log.data.congruentStimulus      = {''};
log.data.incongruentStimulus    = {''};
log.data.trialID                = {1};
log.data.congruentColor         = {''};

%% Fusion
participantInfo = display.stereo.alignFusion(ptb, participantInfo);
questplus.saveFusionOffsets(participantInfo, myPaths);

%% Stimuli at default contrast (as stored in house.png / face.png)
raw = questplus.captureRawStimuli(ptb, design, myPaths);   % per eye, BEFORE any contrast adjustment
faceLTex  = generate.makePinkNoiseTex(ptb.window, raw.faceL,  [], design);
houseRTex = generate.makePinkNoiseTex(ptb.window, raw.houseR, [], design);
houseLTex = generate.makePinkNoiseTex(ptb.window, raw.houseL, [], design);
faceRTex  = generate.makePinkNoiseTex(ptb.window, raw.faceR,  [], design);

%% Instructions
% [changed 2026-11-10] one short screen, then the figure (keys held over time);
% the full text only if the figure file is missing
display.stereo.instruction(ptb, design, design.brTrainingInstructionShort, design.instructionWaitDuration, false);
brFig = '';
if isobject(myPaths) && myPaths.hasField('instructionFigurePath') && design.hasField('instructionFigure')
    brFig = fullfile(myPaths.instructionFigurePath, design.instructionFigure.brtraining);
end
if ~display.stereo.figureInstruction(ptb, design, brFig, design.figureContinue, design.instructionWaitDuration)
    display.stereo.instruction(ptb, design, design.brTrainingInstruction, design.instructionWaitDuration, false);
end
% [added 2026-11-11] key reminder (any key), then the start countdown
display.stereo.instruction(ptb, design, design.brTrainingReminder, design.instructionWaitDuration, false);
KbReleaseWait(-1);   % the key that ends the reminder is not held into the recording

%% Keyboard queues: start recording just before the stimuli
KbQueueStop(ptb.Keyboard2); KbEventFlush(ptb.Keyboard2);
KbQueueStop(ptb.Keyboard1); KbEventFlush(ptb.Keyboard1);
KbQueueStart(ptb.Keyboard2); KbQueueStart(ptb.Keyboard1);
display.stereo.instruction(ptb, design, design.waitTillStart, design.waitTillStartDuration, true);

%% Presentation 1: face left, house right
log.runNr = 1;
draw.stereo.blanks(ptb, design);
fixCrossOnset = Screen('Flip', ptb.window);
draw.stereo.images(ptb, design, faceLTex, houseRTex);
log.data.stimOnset = Screen('Flip', ptb.window, fixCrossOnset + design.ITI);
draw.stereo.blanks(ptb, design);
log.data.stimOffset = Screen('Flip', ptb.window, log.data.stimOnset + duration - ptb.ifi/2);
log.end = 'Success';
log = save_utils.savedata(log, ptb, design, participantInfo, myPaths);
[resultsTable1, success1] = save_utils.formatResponses(log, ptb);

%% Presentation 2: house left, face right
log.runNr = 2;
KbQueueStop(ptb.Keyboard2); KbEventFlush(ptb.Keyboard2);
KbQueueStop(ptb.Keyboard1); KbEventFlush(ptb.Keyboard1);
KbQueueStart(ptb.Keyboard2); KbQueueStart(ptb.Keyboard1);
draw.stereo.images(ptb, design, houseLTex, faceRTex);
log.data.stimOnset = Screen('Flip', ptb.window, log.data.stimOffset + design.ITI);
draw.stereo.blanks(ptb, design);
log.data.stimOffset = Screen('Flip', ptb.window, log.data.stimOnset + duration - ptb.ifi/2);
log.end = 'Success';
log = save_utils.savedata(log, ptb, design, participantInfo, myPaths);
[resultsTable2, success2] = save_utils.formatResponses(log, ptb);
display.stereo.instruction(ptb, design, design.RunIsOver, design.instructionWaitDuration, false);

%% End
Screen('Close', [faceLTex, houseRTex, houseLTex, faceRTex]);
Screen('CloseAll');
ListenChar(1);
if success1 && success2
    t1 = resultsTable1; t2 = resultsTable2;
    d = @(t, p) sum(t.durations(strcmp(t.percepts, p)));
    house = d(t1, 'house') + d(t2, 'house');
    face  = d(t1, 'face')  + d(t2, 'face');
    mixed = d(t1, 'mixed') + d(t2, 'mixed');
    % presentation 1: face left / house right; presentation 2: house left / face right
    leftEye  = d(t1, 'face')  + d(t2, 'house');
    rightEye = d(t1, 'house') + d(t2, 'face');
    fprintf('\nSustained rivalry (default contrasts, 2 x %d s):\n', round(duration));
    fprintf('  house %.1f s, face %.1f s, mixed %.1f s\n', house, face, mixed);
    fprintf('  house / (house + face) = %.2f\n', house / (house + face));
    fprintf('  left eye / (left + right) = %.2f\n', leftEye / (leftEye + rightEye));
    fprintf('  mixed / total = %.2f\n', mixed / (house + face + mixed));
    fprintf('  number of percepts: %d (presentation 1), %d (presentation 2)\n', height(t1), height(t2));
else
    fprintf('Could not get results table\n');
end
end
