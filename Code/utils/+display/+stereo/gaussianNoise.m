function lastNoiseFlip = gaussianNoise(ptb, design, ITIOnset, ITIDuration, currentLeft, currentRight)

% Continue a stereo Gaussian-noise ITI.
%
% The first noise frame has already been drawn and flipped by the caller.
% This function generates each subsequent noise frame while the previous
% one is visible.
%
% Inputs:
% ITIOnset - actual Flip timestamp of the first noise frame
% ITIDuration - total duration of the ITI
% currentLeft - texture currently being displayed to the left eye
% currentRight - texture currently being displayed to the right eye
%
% Outputs:
% lastNoiseFlip - timestamp of the final noise Flip
% finalLeft - final texture currently visible in the left eye
% finalRight - final texture currently visible in the right eye

% ---------------------------------------------------------------------
% Timing
% ---------------------------------------------------------------------

noiseInterval = 0.10;  % desired noise update interval

% Number of display refreshes per noise image.
framesPerNoise = round(noiseInterval / ptb.ifi);

% Actual interval imposed by the display refresh.
actualNoiseInterval = framesPerNoise * ptb.ifi;

% Number of noise images presented during the ITI.
numFrames = floor(ITIDuration / actualNoiseInterval);

% ---------------------------------------------------------------------
% The first noise frame was already flipped by the caller.
% ---------------------------------------------------------------------

vbl = ITIOnset;

% ---------------------------------------------------------------------
% Present remaining noise frames
% ---------------------------------------------------------------------

for f = 2:numFrames

    % -------------------------------------------------------------
    % Generate the NEXT noise frame while the CURRENT frame is
    % visible.
    % -------------------------------------------------------------

    [nextLeft, nextRight] = ...
        generate.createStereoGaussianNoiseTextures(ptb, design);

    % -------------------------------------------------------------
    % Draw next complete stereo frame.
    % -------------------------------------------------------------

    draw.stereo.textures(ptb, design, nextLeft, nextRight);

    % -------------------------------------------------------------
    % Schedule next noise frame.
    % -------------------------------------------------------------

    vbl = Screen('Flip', ptb.window, ...
        vbl + actualNoiseInterval - 0.5 * ptb.ifi);

    % -------------------------------------------------------------
    % The previous textures are no longer needed.
    % -------------------------------------------------------------

    Screen('Close', currentLeft);
    Screen('Close', currentRight);

    % Next becomes current.
    currentLeft  = nextLeft;
    currentRight = nextRight;

end

% ---------------------------------------------------------------------
% Return timestamp and final textures.
% ---------------------------------------------------------------------

lastNoiseFlip = vbl;

Screen('Close', currentLeft);
Screen('Close', currentRight);
end