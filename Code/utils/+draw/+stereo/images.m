function images(ptb, design, leftImage, rightImage)
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
    image_tex_left = Screen('MakeTexture', ptb.window, leftImage);
    Screen('DrawTexture', ptb.window, image_tex_left, [], ...          % Draw the image
            design.destinationRect);
    % Grey frame + circular aperture + ring + corner Xs
    Screen('DrawTexture',ptb.window,design.frameTexture,[],design.frameRect);
    Screen('DrawLines',ptb.window,design.fixCrossCoords, ...
    design.fixCrossLineWidth,design.fixCrossColor,[design.centerX design.centerY]);
    % Select right-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, ptb.rightBuffer);
    Screen('DrawTexture', ptb.window, design.backGroundTexture);        % Image background
    image_tex_right = Screen('MakeTexture', ptb.window, rightImage);
    Screen('DrawTexture', ptb.window, image_tex_right, [], ...        % Draw the image
            design.destinationRect);
    % Grey frame + circular aperture + ring + corner Xs
    Screen('DrawTexture',ptb.window,design.frameTexture,[],design.frameRect);
    Screen('DrawLines',ptb.window,design.fixCrossCoords, ...
    design.fixCrossLineWidth,design.fixCrossColor,[design.centerX design.centerY]);
    % Tell PTB drawing is finished for this frame:       
    Screen('DrawingFinished', ptb.window);
end