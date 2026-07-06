function onset = showStereoHouseFaceBST(ptb, log, design, faceTex, houseTex, duration, startWithFace)
% showStereoHouseFaceBST
% Shows stereo stimuli that alternate between FACE and HOUSE every 100 ms.
% Each frame uses a NEW exemplar (random from the corresponding set).
% Same masking as drawStereoImages: hex aperture + Gaussian mask,
% same background and fixation, and same stereo buffer assignment.

if nargin < 5
    error('Need at least ptb, log, design, faceTex, and houseTex.');
end

if nargin < 6 || isempty(duration)
    duration = 2; % default 2 seconds
end

if nargin < 7 || isempty(startWithFace)
    startWithFace = rand > 0.5; % randomise if not specified
end

stimInterval = 0.10; % 100 ms
numFrames = upper(duration / stimInterval);

% Helper to pick one texture randomly from an array
function tex = pickOneBST(texInput)
    n = numel(texInput);
    if n < 1
        error('pickOneBST: empty texture array.');
    end
    tex = texInput(randi(n));
end

onset = NaN;

for f = 1:numFrames
    frameStart = GetSecs;

    % --- Decide whether this frame is a face or a house ---
    if startWithFace
        showFace = mod(f, 2) == 1; % odd frames: face
    else
        showFace = mod(f, 2) == 0; % even frames: face
    end

    if showFace
        thisTex = pickOneBST(faceTex); % NEW random (hex-masked) face
    else
        thisTex = pickOneBST(houseTex); % NEW random (hex-masked) house
    end

    % ================= LEFT eye =================
    Screen('SelectStereoDrawBuffer', ptb.window, log.leftBuffer);

    % Background
    Screen('DrawTexture', ptb.window, design.backGroundTexture);

    % Hex-masked image (already has alpha from createImageShapeMask)
    Screen('DrawTexture', ptb.window, thisTex, [], ptb.destinationRect);

    % Fixation cross
    Screen('DrawLines', ptb.window, ptb.fixCrossCoords, ...
        ptb.lineWidthInPix, ptb.white, [ptb.xCenter ptb.yCenter]);

    % Gaussian mask on top
    Screen('DrawTexture', ptb.window, design.gaussianMask, [], ptb.destinationRect);

    % ================= RIGHT eye =================
    Screen('SelectStereoDrawBuffer', ptb.window, log.rightBuffer);

    % Background
    Screen('DrawTexture', ptb.window, design.backGroundTexture);

    % Same hex-masked image to the other eye
    Screen('DrawTexture', ptb.window, thisTex, [], ptb.destinationRect);

    % Fixation cross
    Screen('DrawLines', ptb.window, ptb.fixCrossCoords, ...
        ptb.lineWidthInPix, ptb.white, [ptb.xCenter ptb.yCenter]);

    % Gaussian mask
    Screen('DrawTexture', ptb.window, design.gaussianMask, [], ptb.destinationRect);

    % Finish and flip
    Screen('DrawingFinished', ptb.window);
    if f == 1
        onset = Screen('Flip', ptb.window); % time of first frame
    else
        Screen('Flip', ptb.window);
    end

    % --- Frame timing ---
    elapsed = GetSecs - frameStart;
    remaining = stimInterval - elapsed;
    if remaining > 0
        WaitSecs(remaining);
    end
end

% Do NOT close thisTex or gaussianMask/background here:
% they are reused across trials.

end
