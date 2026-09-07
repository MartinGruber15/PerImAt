function gaussianNoiseBST(ptb, duration)
% ShowStereoGaussianNoise shows stereo Gaussian noise with fixation cross,
% pacing frames to a target interval by compensating for generation time.

if nargin < 2
    duration = 5; % default to 5 seconds
end

% --- Frame timing ---
noiseInterval = 0.10;                  % seconds per frame (10 Hz)
numFrames     = ceil(duration/noiseInterval);
% Get screen size
[screenX, screenY] = Screen('WindowSize', ptb.window);
noiseSize = [screenY, screenX]./2;        % full screen
for f = 1:numFrames
    frameStart = GetSecs;              % <-- start timing this frame

    % --- Generate noise for both eyes ---
    noiseLeft  = uint8(127 + 30 * randn(noiseSize));
    noiseRight = uint8(127 + 30 * randn(noiseSize));
    % clip to [0,255]
    noiseLeft  = max(min(noiseLeft,  255), 0);
    noiseRight = max(min(noiseRight, 255), 0);
    noiseLeft = imresize(noiseLeft,2);
    noiseRight = imresize(noiseRight,2);

    texLeft  = Screen('MakeTexture', ptb.window, noiseLeft);
    texRight = Screen('MakeTexture', ptb.window, noiseRight);

    % --- Draw to LEFT eye buffer ---
    Screen('SelectStereoDrawBuffer', ptb.window, 0);
    Screen('DrawTexture', ptb.window, texLeft);
    Screen('DrawLines', ptb.window, ptb.fixCrossCoords, ...
        ptb.lineWidthInPix, ptb.white, [ptb.xCenter ptb.yCenter]);

    % --- Draw to RIGHT eye buffer ---
    Screen('SelectStereoDrawBuffer', ptb.window, 1);
    Screen('DrawTexture', ptb.window, texRight);
    Screen('DrawLines', ptb.window, ptb.fixCrossCoords, ...
        ptb.lineWidthInPix, ptb.white, [ptb.xCenter ptb.yCenter]);

    % --- Finish drawing & flip both eyes simultaneously ---
    Screen('DrawingFinished', ptb.window);
    Screen('Flip', ptb.window);

    % --- Clean up textures ---
    Screen('Close', texLeft);
    Screen('Close', texRight);

    % --- Compensate wait: only sleep the remaining time in this frame ---
    elapsed   = GetSecs - frameStart;
    remaining = noiseInterval - elapsed;
    if remaining > 0
        WaitSecs(remaining);
    end
    % If remaining <= 0, we overran this frame; skip waiting and continue.
end
end
