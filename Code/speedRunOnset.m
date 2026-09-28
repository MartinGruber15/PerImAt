function speedRunOnset(log, ptb, design, participantInfo)

%% Timing
design.instructionWaitDuration  = 0.5;
stimulusPresentationTime = 1.5 - ptb.ifi/2; % 1
ITI                      = 2 - ptb.ifi/2; % 5
nTrials=30;

%% Empty cell arrays to save trial information
display.stereo.alignFusion(ptb, participantInfo);
display.stereo.instruction(ptb,design, design.Introduction, design.instructionWaitDuration, false);


grey = design.stimuli.grey_square;
% Loop trough all trials
trialStart = GetSecs();
for trial = 1:nTrials
    house = generate.makePinkNoiseTex(ptb.window, design.images.house, design.masks.house, design); 
    face = generate.makePinkNoiseTex(ptb.window, design.images.face, design.masks.face, design);
    if rand < 0.5
        stimuli = [house, face];
    else
        stimuli = [face, house];
    end
    draw.stereo.images(ptb,design,stimuli(1),stimuli(2));
    fliptime = Screen('Flip',ptb.window,trialStart+2);
    [leftNoise, rightNoise] =generate.createStereoGaussianNoiseTextures(ptb, design);
    draw.stereo.textures(ptb, design, leftNoise, rightNoise);
    ITIOnset = Screen('Flip', ptb.window, fliptime+stimulusPresentationTime);
    lastFlip = display.stereo.gaussianNoise(ptb,design,ITIOnset,ITI, leftNoise, rightNoise);
    draw.stereo.images(ptb,design, grey,grey);
    trialStart =Screen('Flip',ptb.window,lastFlip);

end

display.stereo.instruction(ptb, design,design.RunIsOver, design.instructionWaitDuration, false);
log.end = 'Success';
end
