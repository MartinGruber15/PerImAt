function drawStereoImagesWithFilter(ptb, log, design, leftImage, rightImage)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draws background textures and images onto both buffers of a 
% stereo display and applies a shapeMask on the image as well as a gaussian
% mask.
% 
% Input:
%   ptb: the struct containing window settings + the window that drawn on
%   log: struct that contains constants about buffer assignment
%   design: struct that contains the destinanation rectangle and the 
%           background texture
%   leftImage: image drawn onto the left buffer
%   rightImage: image drawn onto the right buffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Select left-eye image buffer for drawing
    Screen('SelectStereoDrawBuffer', ptb.window, log.leftBuffer);
    Screen('DrawTexture', ptb.window, design.backGroundTexture);        % Image background
    imageTextureCon = createImageShapeMask(ptb.window, leftImage, 'hex');
    %imageTextureCon = Screen('MakeTexture', ptb.window, leftImage);     % Create texture for stimulus
    Screen('DrawTexture', ptb.window, imageTextureCon, [], ...          % Draw the image
            ptb.destinationRect);
    Screen('DrawLines',ptb.window,ptb.fixCrossCoords, ...               % Draw the fixation cross
    ptb.lineWidthInPix,ptb.white,[ptb.xCenter ptb.yCenter]);
    Screen('DrawTexture', ptb.window, design.gaussianMask, [], ptb.destinationRect);
    % Select right-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, log.rightBuffer);
    Screen('DrawTexture', ptb.window, design.backGroundTexture);        % Image background
    imageTextureIncon = createImageShapeMask(ptb.window, rightImage, 'hex');
    %imageTextureIncon = Screen('MakeTexture', ptb.window, rightImage);  % Create texture for stimulus
    Screen('DrawTexture', ptb.window, imageTextureIncon, [], ...        % Draw the image
            ptb.destinationRect);
    Screen('DrawLines',ptb.window,ptb.fixCrossCoords, ...
    ptb.lineWidthInPix,ptb.white,[ptb.xCenter ptb.yCenter]);            % Draw the fixation cross
    Screen('DrawTexture', ptb.window, design.gaussianMask, [], ptb.destinationRect);


    % Tell PTB drawing is finished for this frame:       
    Screen('DrawingFinished', ptb.window);
    Screen('Close', imageTextureCon);
    Screen('Close', imageTextureIncon);
end