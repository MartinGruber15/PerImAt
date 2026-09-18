function showStereoGaussianNoiseBSTlow(ptb, design, duration)
% Show coarse stereo Gaussian noise with a central fixation cross.
%
% The noise texture:
%   - consists of coarse square noise elements;
%   - covers the full screen plus an overscan margin;
%   - is generated at low resolution and enlarged by the GPU for efficiency.
%
% Usage:
%   showStereoGaussianNoiseBSTlow(ptb)
%   showStereoGaussianNoiseBSTlow(ptb, 5)
% 


if nargin < 2
    duration = 5;
end

% -------------------------------------------------------------------------
% Settings
% -------------------------------------------------------------------------

noiseInterval = 0.10;  % seconds per noise image: 0.10 = 10 Hz

noiseMean = 128;       % mean grey level
noiseSD   = 30;        % Gaussian noise standard deviation

% Approximate width/height of one noise element in physical screen pixels.
% Increase this value for coarser noise.
noiseElementSizePx = 4;

% Extra noise coverage on every side of the screen.
% This allows the texture to be shifted without revealing empty areas.
overscanPx = 0;

% Optional displacement of the noise texture.
% Keep at [0 0] for centred noise.
noiseOffsetPx = [0 0];

% -------------------------------------------------------------------------
% Screen and texture geometry
% -------------------------------------------------------------------------

[screenX, screenY] = Screen('WindowSize', ptb.window);

% Size of the oversized displayed noise region
displayWidth  = screenX + 2 * overscanPx;
displayHeight = screenY + 2 * overscanPx;

% Generate only as many independent noise values as necessary.
% The GPU will enlarge these values into square noise elements.
noiseColumns = ceil(displayWidth  / noiseElementSizePx);
noiseRows    = ceil(displayHeight / noiseElementSizePx);

% Oversized destination rectangle, centred on the screen
noiseDestinationRect = CenterRectOnPointd( ...
    [0 0 displayWidth displayHeight], ...
    ptb.xCenter + noiseOffsetPx(1), ...
    ptb.yCenter + noiseOffsetPx(2));

numFrames = ceil(duration / noiseInterval);

% -------------------------------------------------------------------------
% Present noise frames
% -------------------------------------------------------------------------

for f = 1:numFrames

    frameStart = GetSecs;

    % Generate independent Gaussian noise for both eyes.
    noiseLeft  = noiseMean + noiseSD * randn(noiseRows, noiseColumns);
    noiseRight = noiseMean + noiseSD * randn(noiseRows, noiseColumns);

    % Clip before conversion to uint8.
    noiseLeft  = uint8(max(0, min(255, noiseLeft)));
    noiseRight = uint8(max(0, min(255, noiseRight)));

    % Small textures are fast to upload to the GPU.
    texLeft  = Screen('MakeTexture', ptb.window, noiseLeft);
    texRight = Screen('MakeTexture', ptb.window, noiseRight);

    % ---------------------------------------------------------------------
    % Left eye
    % ---------------------------------------------------------------------

    Screen('SelectStereoDrawBuffer', ptb.window, 0);

    % filterMode = 1; % gives nearest-neighbour interpolation and therefore
    % preserves clearly defined square noise elements.
    Screen('DrawTexture', ptb.window, texLeft, [], ...
        noiseDestinationRect, 0, 1);


    % ---------------------------------------------------------------------
    % Right eye
    % ---------------------------------------------------------------------

    Screen('SelectStereoDrawBuffer', ptb.window, 1);

    Screen('DrawTexture', ptb.window, texRight, [], ...
        noiseDestinationRect, 0, 1);

    Screen('DrawLines', ptb.window, ptb.fixCrossCoords, ...
        ptb.lineWidthInPix, ptb.white, ...
        [ptb.xCenter ptb.yCenter]);

    % Show both stereo buffers simultaneously.
    Screen('DrawingFinished', ptb.window);
    Screen('Flip', ptb.window);

    % Textures are no longer needed after the flip.
    Screen('Close', texLeft);
    Screen('Close', texRight);

    % Maintain the requested noise-update interval.
    elapsed = GetSecs - frameStart;
    remaining = noiseInterval - elapsed;

    if remaining > 0
        WaitSecs(remaining);
    end
end
end