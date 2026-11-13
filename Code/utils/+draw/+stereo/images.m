function images(ptb, design, leftImageTex, rightImageTex)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draws background textures and images onto both buffers of a 
% stereo display.
% 
% Input:
%   ptb: the struct containing window settings + the window that drawn on
%   design: struct that contains the destinanation rectangle and the 
%           background texture
%   leftImage: image drawn onto the left buffer
%   rightImage: image drawn onto the right buffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Select left-eye image buffer for drawing
    Screen('SelectStereoDrawBuffer', ptb.window, ptb.leftBuffer);
    Screen('DrawTexture', ptb.window, design.backGroundTexture);        % Image background
    Screen('DrawTexture', ptb.window, leftImageTex, [], ...          % Draw the image
            design.destinationRect);
    % Grey frame + circular aperture + ring + corner Xs
    Screen('DrawTexture',ptb.window,design.frameTexture,[],design.frameRect);
    Screen('DrawLines',ptb.window,design.fixCrossCoords, ...
    design.fixCrossLineWidth,design.fixCrossColor,[design.centerX design.centerY]);
    if ptb.usedatapixx
        Screen('FillRect', ptb.window, [0, 0, 255], design.blueRectLeftOn);
        Screen('FillRect', ptb.window, [0, 0, 0], design.blueRectLeftOff);
    end
    
    % Select right-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, ptb.rightBuffer);
    Screen('DrawTexture', ptb.window, design.backGroundTexture);        % Image background
    Screen('DrawTexture', ptb.window, rightImageTex, [], ...        % Draw the image
            design.destinationRect);
    % Grey frame + circular aperture + ring + corner Xs
    Screen('DrawTexture',ptb.window,design.frameTexture,[],design.frameRect);
    Screen('DrawLines',ptb.window,design.fixCrossCoords, ...
    design.fixCrossLineWidth,design.fixCrossColor,[design.centerX design.centerY]);
    if ptb.usedatapixx
        Screen('FillRect', ptb.window, [0, 0, 255], design.blueRectRightOn);
        Screen('FillRect', ptb.window, [0, 0, 0], design.blueRectRightOff);
    end
    % Tell PTB drawing is finished for this frame:       
    Screen('DrawingFinished', ptb.window);
end