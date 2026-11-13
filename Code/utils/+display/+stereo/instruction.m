function instruction(ptb,design, text, waitDuration, autoContinue)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draws and displays text onto both buffers of a stereo display.
% 
% Input:
%   ptb: the struct containing window settings + the window that drawn on
%   log: struct that contains constants about buffer assignment
%   text: the displayed text
%   waitDuration: the minimum display duration
%   autoContinue: if true, the function ends after waitDuration, otherwise
%                   it is waited on keyboard input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Select left-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', ptb.window, ptb.leftBuffer);
DrawFormattedText (ptb.window, text, 'center', ...
    'center',ptb.FontColor);
if ptb.usedatapixx
Screen('FillRect', ptb.window, [0, 0, 255], design.blueRectLeftOn);
Screen('FillRect', ptb.window, [0, 0, 0], design.blueRectLeftOff);
end
% Select right-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', ptb.window, ptb.rightBuffer);
DrawFormattedText (ptb.window, text, 'center', ...
    'center',ptb.FontColor);
if ptb.usedatapixx
    Screen('FillRect', ptb.window, [0, 0, 255], design.blueRectRightOn);
    Screen('FillRect', ptb.window, [0, 0, 0], design.blueRectRightOff);
end
% Tell PTB drawing is finished for this frame:
Screen('DrawingFinished', ptb.window);
Screen ('Flip', ptb.window);
WaitSecs (waitDuration);
if ~autoContinue
    KbWait(ptb.Keyboard2, 2);
end
end