function raw = captureRawStimuli(ptb, design, myPaths)
% questplus.captureRawStimuli  Capture the un-adjusted house/face images per eye.
%
%   raw = questplus.captureRawStimuli(ptb, design, myPaths)
%
% raw.houseL, raw.faceL, raw.houseR, raw.faceR: uint8 images exactly as
% generate.getContrastAdjustedImages captures them for its base images
% (no fixation dots) BEFORE it applies the contrast. QUEST+ needs a new
% contrast on every trial, so the capture is done once and
% questplus.applyContrast is applied per trial (same formula as the local
% applyContrast in generate.getContrastAdjustedImages).
% Keep this function in sync with generate.getContrastAdjustedImages.

eyeNames = {'L', 'R'};
stimulusNames = {'house', 'face'};
dest = design.destinationRect;
captureRect = [floor(dest(1)), floor(dest(2)), ceil(dest(3)), ceil(dest(4))];

textures = zeros(1, numel(stimulusNames));
for s = 1:numel(stimulusNames)
    filename = fullfile(myPaths.stimuliLocation, [stimulusNames{s} '.png']);
    assert(isfile(filename), 'Stimulus file does not exist: %s', filename);
    [img, ~, alpha] = imread(filename);
    if ndims(img) == 2, img = repmat(img, [1 1 3]); end
    if ~isempty(alpha), img = cat(3, img, alpha); end
    textures(s) = Screen('MakeTexture', ptb.window, img);
end

% The capture is drawn into an OFFSCREEN window, never into the on-screen
% stereo buffers: drawing there (plus DrawingFinished) left the last captured
% image (the house) in the left-eye buffer, so it was shown to the left eye
% only at the next Flip (seen at the start of the calibration).
off = Screen('OpenOffscreenWindow', ptb.window, ptb.grey, ptb.windowRect);
try
    Screen('BlendFunction', off, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');   % as the on-screen window
    for s = 1:numel(stimulusNames)
        Screen('FillRect', off, ptb.grey);
        Screen('DrawTexture', off, textures(s), [], dest);
        img = uint8(Screen('GetImage', off, captureRect));
        % both eyes get the same drawing (identical images, as before)
        for e = 1:numel(eyeNames)
            raw.([stimulusNames{s} eyeNames{e}]) = img;
        end
        % [added 2026-11-10] centre of the contrast scaling (questplus.trialImages):
        % the visible stimulus content, as in generate.getContrastAdjustedImages
        [raw.refMask.(stimulusNames{s}), ~, refInfo] = generate.contrastReferenceMask(img, design);
        raw.refMode = refInfo.mode;   % 'visible' | 'image', saved with the contrasts
    end
catch ME
    Screen('Close', [textures off]);
    rethrow(ME);
end
Screen('Close', [textures off]);
end
