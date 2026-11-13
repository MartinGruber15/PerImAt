function keyBindingTraining(ptb,design,myPaths)
% keyBindingTraining: house or face (same image in both eyes, default contrast,
% on pink noise); the subject presses the matching key, feedback correct/incorrect.
% (design.stimuli.house/face no longer exist; the images are taken from
% house.png/face.png via questplus.captureRawStimuli.)
raw = questplus.captureRawStimuli(ptb, design, myPaths);
houseL = generate.makePinkNoiseTex(ptb.window, raw.houseL, [], design);
houseR = generate.makePinkNoiseTex(ptb.window, raw.houseR, [], design);
faceL  = generate.makePinkNoiseTex(ptb.window, raw.faceL,  [], design);
faceR  = generate.makePinkNoiseTex(ptb.window, raw.faceR,  [], design);
images = [houseL houseR; faceL faceR];   % row 1 house, row 2 face; columns: left, right eye
display.stereo.instruction(ptb, design, design.keyTrainingInstruction, 0.5, false);
conditions = ["house","face"];
repetitions= 30;
randomOrder = repmat([1 2], 1, repetitions);
randomOrder = randomOrder(randperm(numel(randomOrder)));

nCorrect = 0;
for i=1:numel(randomOrder)
    cond = conditions(randomOrder(i));
    draw.stereo.images(ptb,design,images(randomOrder(i),1),images(randomOrder(i),2))
    Screen('Flip', ptb.window);
    KbReleaseWait(-1);   % a key still held from the previous trial must not count as the response
    while true
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            break;
        end
    end
    pressedKey = find(keyCode, 1);
    if strcmp(cond,"house");correctKey=ptb.Keys.house;elseif strcmp(cond,"face");correctKey=ptb.Keys.face;end

    if pressedKey==correctKey
       nCorrect = nCorrect + 1;
       draw.stereo.fixCrossPlusText(ptb,design,design.feedbackCorrect,ptb.black)
       Screen('Flip', ptb.window);
    else
       draw.stereo.fixCrossPlusText(ptb,design,design.feedbackIncorrect,ptb.black)
       Screen('Flip', ptb.window);
    end
    WaitSecs(1);
end
Screen('CloseAll')
percentCorrect = 100 * nCorrect / numel(randomOrder);
fprintf('Percent correct: %.2f%%\n', percentCorrect);
end
