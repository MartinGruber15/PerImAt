function imagesNoReport(ptb, design, leftImage, rightImage, selectedPair, dotTransparency)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draws background textures, images and each one fixation
% dot onto both buffers of a stereo display.
%
% In the no-report condition:
%   selectedPair(1) = fixation-dot position in the LEFT stereo buffer
%   selectedPair(2) = fixation-dot position in the RIGHT stereo buffer
%
% dotTransparency controls the alpha/transparency of the fixation dots.
% A value of 0 means invisible, while design.fixDotTransparency is the
% fully visible value.
%
% Input:
%   ptb:
%       Struct containing window settings and stereo buffer information.
%
%   design:
%       Struct containing drawing parameters, including:
%           .backGroundTexture
%           .destinationRect
%           .fixCrossCoords
%           .fixDotPositions
%
%   leftImage:
%       Image drawn onto the left stereo buffer.
%
%   rightImage:
%       Image drawn onto the right stereo buffer.
%
%   selectedPair:
%       Two-element vector specifying the fixation-dot positions.
%       First element = left buffer.
%       Second element = right buffer.
%
%   dotTransparency:
%       Alpha value used for the fixation dots.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Get fixation-dot positions
leftDotPos  = selectedPair(1);
rightDotPos = selectedPair(2);
leftDotCoord  = design.fixDotPositions(leftDotPos, :);
rightDotCoord = design.fixDotPositions(rightDotPos, :);

%% Select left-eye image buffer
Screen('SelectStereoDrawBuffer', ptb.window, ptb.leftBuffer);
% Background
Screen('DrawTexture', ptb.window, design.backGroundTexture);
% Image
image_tex_left = Screen('MakeTexture', ptb.window, leftImage);
Screen('DrawTexture', ptb.window, image_tex_left, [],design.destinationRect);
% Fixation dot
Screen('DrawDots', ptb.window, leftDotCoord,design.fixDotSizeInPixels,[design.fixDotColor, dotTransparency], [], 2);


%% Select right-eye image buffer
Screen('SelectStereoDrawBuffer', ptb.window, ptb.rightBuffer);
% Background
Screen('DrawTexture', ptb.window, design.backGroundTexture);
% Image
image_tex_right = Screen('MakeTexture', ptb.window, rightImage);
Screen('DrawTexture', ptb.window, image_tex_right, [],design.destinationRect);
% Fixation dot
Screen('DrawDots', ptb.window, rightDotCoord,design.fixDotSizeInPixels,[design.fixDotColor, dotTransparency], [], 2);

%% Finish drawing
Screen('DrawingFinished', ptb.window);
end
