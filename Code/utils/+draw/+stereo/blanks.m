function blanks(ptb, design)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draws and displays blank screens with fixation crosses onto both buffers 
% of a stereo display.
% 
% Input:
%   ptb: the struct containing window settings + the window that drawn on
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('SelectStereoDrawBuffer', ptb.window, ptb.leftBuffer);
Screen('DrawTexture', ptb.window, design.backGroundTexture);        % Image background
% Grey frame + circular aperture + ring + corner Xs
Screen('DrawTexture',ptb.window,design.frameTexture,[],design.frameRect);
Screen('DrawLines',ptb.window,design.fixCrossCoords, ...
    design.fixCrossLineWidth,design.fixCrossColor,[design.centerX design.centerY]);
% Select   right-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', ptb.window, ptb.rightBuffer);
Screen('DrawTexture', ptb.window, design.backGroundTexture);        % Image background
% Grey frame + circular aperture + ring + corner Xs
Screen('DrawTexture',ptb.window,design.frameTexture,[],design.frameRect);
Screen('DrawLines',ptb.window,design.fixCrossCoords, ...
    design.fixCrossLineWidth,design.fixCrossColor,[design.centerX design.centerY]);
% Tell PTB drawing is finished for this frame:
Screen('DrawingFinished', ptb.window);
end