function ratingKeyDemo(ptb, design)
% display.stereo.ratingKeyDemo  Let the subject find the five rating keys.
%
%   display.stereo.ratingKeyDemo(ptb, design)
%
% Shows design.questionInstruction (getInstructions: the rating scale and
% the request to press each key). Every press of a
% rating key shows its number in large digits; the numbers not yet found
% are listed below. Ends 1 s after all five keys were pressed (ESCAPE
% skips). Mapping as scored in perImAtOffline / trialProcedurePerImAtOffline:
%   ptb.Keys.accept = 1, left = 2, right = 3, up = 4, down = 5
keys = [ptb.Keys.accept, ptb.Keys.left, ptb.Keys.right, ptb.Keys.up, ptb.Keys.down];
found = false(1, numel(keys));
last = 0;
KbReleaseWait(-1);   % the key that ended the previous screen must not count
while true
    if last > 0; lastStr = num2str(last); else; lastStr = ' '; end
    if all(found)
        rest = design.ratingKeyDone;
    else
        rest = [design.ratingKeyMissing ' ' strjoin(arrayfun(@num2str, find(~found), 'UniformOutput', false), '  ')];
    end
    drawBoth(ptb, design, [design.questionInstruction '\n\n\n' rest], lastStr);
    if all(found)
        WaitSecs(1);
        break
    end
    [~, keyCode] = KbPressWait(-1);
    if keyCode(ptb.Keys.escape); break; end
    i = find(keyCode(keys), 1);
    if ~isempty(i)
        last = i;
        found(i) = true;
    end
    KbReleaseWait(-1);
end
end


function drawBoth(ptb, design, text, number)
for buffer = [ptb.leftBuffer, ptb.rightBuffer]
    Screen('SelectStereoDrawBuffer', ptb.window, buffer);
    DrawFormattedText(ptb.window, text, 'center', ptb.yCenter - 0.25 * ptb.screenYpixels, ptb.FontColor);
    oldSize = Screen('TextSize', ptb.window, 3 * Screen('TextSize', ptb.window));
    DrawFormattedText(ptb.window, number, 'center', ptb.yCenter + 0.1 * ptb.screenYpixels, ptb.FontColor);
    Screen('TextSize', ptb.window, oldSize);
    if ptb.usedatapixx
        if buffer == ptb.leftBuffer
            Screen('FillRect', ptb.window, [0, 0, 255], design.blueRectLeftOn);
            Screen('FillRect', ptb.window, [0, 0, 0], design.blueRectLeftOff);
        else
            Screen('FillRect', ptb.window, [0, 0, 255], design.blueRectRightOn);
            Screen('FillRect', ptb.window, [0, 0, 0], design.blueRectRightOff);
        end
    end
end
Screen('DrawingFinished', ptb.window);
Screen('Flip', ptb.window);
end
