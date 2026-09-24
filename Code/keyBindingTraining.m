function keyBindingTraining(ptb,design)
house = design.stimuli.house;
face = design.stimuli.face;
images = [house,face];
conditions = ["house","face"];
repetitions= 30;
randomOrder = repmat([1 2], 1, repetitions);
randomOrder = randomOrder(randperm(numel(randomOrder)));

nCorrect = 0;
for i=1:numel(randomOrder)
    image = images(randomOrder(i));
    cond = conditions(randomOrder(i));
    draw.stereo.images(ptb,design,image,image)
    Screen('Flip', ptb.window);
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
       draw.stereo.fixCrossPlusText(ptb,design,'correct',ptb.black)
       Screen('Flip', ptb.window);
    else
       draw.stereo.fixCrossPlusText(ptb,design,'incorrect',ptb.black)
       Screen('Flip', ptb.window);
    end
    WaitSecs(1);
end
Screen('CloseAll')
percentCorrect = 100 * nCorrect / numel(randomOrder);
disp(percentCorrect)
fprintf('Percent correct: %.2f%%\n', percentCorrect);
end
