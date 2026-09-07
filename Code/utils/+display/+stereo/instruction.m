function instruction(ptb, text, waitDuration, autoContinue)
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
% Select right-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', ptb.window, ptb.rightBuffer);
DrawFormattedText (ptb.window, text, 'center', ...
    'center',ptb.FontColor);
% Tell PTB drawing is finished for this frame:
Screen('DrawingFinished', ptb.window);
Screen ('Flip', ptb.window);
WaitSecs (waitDuration);
if ~autoContinue
    KbWait(ptb.Keyboard2, 2);
end
end