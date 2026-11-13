function design = getVisualDesignSettings(ptb, myPaths, design)
if nargin < 3
    design = struct(); % Initialize the design structure
end
% Screen center
design.centerX = ptb.centerX;
design.centerY = ptb.centerY;

%% Displayed elements in visual degrees
design.stimSizeInDegrees        = 3;      % stimulus size in visual deg.
design.frameSizeFactor          = 1.3;%1.1  % frame around stimulus
design.frameApertureFactor      = 2/3;      % circular aperture (=stimulus window)
design.crossesSizeInDegrees     = 0.5;      % Crosses in the edge of the frame
design.crossesWidthInDegrees    = 0.08;     % width of crosses in frame edges
design.crossesInsetInDegrees    = 0.15;     % distance of frame crosses from edges
design.fusionMaskInDegrees      = 8;        % surrounding fusion-aid frame
design.fixCrossInDegrees        = 0.2;      % Fixation cross in degrees
design.fixDotSizeInDegrees      = 0.1;      % Fixation dots for no-report in degrees
design.fixDotFrameSizeInDegrees = 0.2;%35? % Frame around fixation dot
% Style of the no-report fixation dots:
%   'gaussian': soft dot with Gaussian falloff, no frame, blended into the
%               stimulus (generate.createGaussianFixDotTexture)
%   'frame'   : previous version, grey square frame with two-tone dot
%               (generate.createFixDotTexture)
design.fixDotStyle              = 'gaussian';
design.fixDotSigmaInDegrees     = 0.035;    % SD of the Gaussian dot ('gaussian' only)
% [added 2026-11-06] Big dot: a larger dot with a smaller luminance step, so it is
% about as easy to detect but stands out less in brightness (less variation of the
% dot's contrast against the texture). With 'local' dots (below) the step is
% fixDotBigWeber instead of fixDotLocalWeber. The Weber value is scaled with
% 1/sigma (partial spatial summation, Piper's law): Weber_big = 0.39 * 0.035 / sigma_big
% (0.27 for sigma 0.05). [2026-11-11] 0.33 is used: chosen by eye with the 0.05 dot
% (about 20 % above the rule), kept on purpose. Check with the detection test of
% fixDotPilot (opts.bigDot = true).
% A caller can set design.fixDotBig before calling this function
% (rivalryDurationPilot / fixDotPilot: opts.bigDot); otherwise fixDotBigDefault.
fixDotBigDefault               = true;
design.fixDotBigSigmaInDegrees = 0.05;     % SD of the big dot (small dot: 0.035)
design.fixDotBigWeber          = 0.33;     % 'local' step of the big dot (small dot: fixDotLocalWeber = 0.39); chosen 2026-11-11, see above
if ~fieldSet(design, 'fixDotBig'); design.fixDotBig = fixDotBigDefault; end
if isequal(design.fixDotBig, true)
    design.fixDotSigmaInDegrees = design.fixDotBigSigmaInDegrees;
end
if strcmp(design.fixDotStyle, 'gaussian')
    % texture rect = +-3 SD, so the dot fades out completely inside it
    design.fixDotFrameSizeInDegrees = 6 * design.fixDotSigmaInDegrees;
end
design.legendPictogramInDegrees = 0.8;      % key assignment legend pictograms

%% Convert visual degrees to pixels
% Stimulus size
design.stimSizeInPixelsX        = round(ptb.PixPerDegWidth * design.stimSizeInDegrees);
design.stimSizeInPixelsY        = round(ptb.PixPerDegHeight * design.stimSizeInDegrees);
% Stimulus Frame and its circular aperture
design.frameSizeInDegrees       = design.stimSizeInDegrees * design.frameSizeFactor;
design.frameSizeInPixelsX       = round(ptb.PixPerDegWidth * design.frameSizeInDegrees);
design.frameSizeInPixelsY       = round(ptb.PixPerDegHeight * design.frameSizeInDegrees);
design.frameApertureInDegrees   = design.frameSizeInDegrees * design.frameApertureFactor;
design.apertureDiameterInPixels = round(ptb.PixPerDegWidth * design.frameApertureInDegrees);
design.crossesSizeInPixels      = round(ptb.PixPerDegWidth * design.crossesSizeInDegrees);
design.crossesWidthInPixels     = round(ptb.PixPerDegWidth * design.crossesWidthInDegrees);
design.crossesInsetInPixels     = round(ptb.PixPerDegWidth * design.crossesInsetInDegrees);
% Fusion mask
design.fusionMaskInPixelsX      = round(ptb.PixPerDegWidth * design.fusionMaskInDegrees);
design.fusionMaskInPixelsY      = round(ptb.PixPerDegHeight * design.fusionMaskInDegrees);
% Fixation cross size
design.fixCrossInPixelsX        = round(ptb.PixPerDegWidth * design.fixCrossInDegrees);
design.fixCrossInPixelsY        = round(ptb.PixPerDegHeight * design.fixCrossInDegrees);
% Fixation dot(s) size and frame size
design.fixDotSizeInPixels       = round(ptb.PixPerDegWidth * design.fixDotSizeInDegrees);
design.fixDotFrameSizeInPixels  = round(ptb.PixPerDegWidth * design.fixDotFrameSizeInDegrees);
design.fixDotSigmaInPixels      = ptb.PixPerDegWidth * design.fixDotSigmaInDegrees;
% legend pictograms
design.legendPictogramSize      = round(design.legendPictogramInDegrees * ptb.PixPerDegHeight);

%% Screen positions
% Rectangle in which the stimulus is drawn
design.destinationRect = [ ...
    design.centerX - design.stimSizeInPixelsX/2, ...
    design.centerY - design.stimSizeInPixelsY/2, ...
    design.centerX + design.stimSizeInPixelsX/2, ...
    design.centerY + design.stimSizeInPixelsY/2];

% Rectangle for the frame around the stimulus
design.frameRect = [ ...
    design.centerX - design.frameSizeInPixelsX/2, ...
    design.centerY - design.frameSizeInPixelsY/2, ...
    design.centerX + design.frameSizeInPixelsX/2, ...
    design.centerY + design.frameSizeInPixelsY/2];

% Position of the fusion mask

% Fixation cross coordinates relative to its center
design.fixCrossCoords = [
    -design.fixCrossInPixelsX/2 design.fixCrossInPixelsX/2 0 0; ...
    0 0 -design.fixCrossInPixelsY/2 design.fixCrossInPixelsY/2];

% Fixation dot positions and coordinates for no-report BR
% Distance of fixation dots from the center
design.fixDotDistanceInPixelsX = (design.stimSizeInPixelsX / 2.3) / 2.4; % 3 3 2
design.fixDotDistanceInPixelsY = (design.stimSizeInPixelsY / 2.3) / 1.6; % 3 3 2

dx = design.fixDotDistanceInPixelsX;
dy = design.fixDotDistanceInPixelsY;
% screen coordinates of the 6 possible positions
% 1 . 2
% 6 + 3
% 5 . 4
design.fixDotPositions = [
    design.centerX - dx, design.centerY - dy;  % 1 = top-left
    design.centerX + dx, design.centerY - dy;  % 2 = top-right
    design.centerX + dx, design.centerY;      % 3 = right
    design.centerX + dx, design.centerY + dy   % 4 = bottom-right
    design.centerX - dx, design.centerY + dy;  % 5 = bottom-left
    design.centerX - dx, design.centerY;      % 6 = left
    ];
design.fixDotValidPairs = [
    1 2
    1 3
    1 4
    6 2
    6 3
    6 4
    5 2
    5 3
    5 4
    2 1
    2 6
    2 5
    3 1
    3 6
    3 5
    4 1
    4 6
    4 5
    ];

% frame rectangles around fix dots
nPositions = size(design.fixDotPositions, 1);
frameSize = design.fixDotFrameSizeInPixels;
design.fixDotTextureRects = zeros(4,nPositions);
for i = 1:nPositions
    x = design.fixDotPositions(i, 1);
    y = design.fixDotPositions(i, 2);
    design.fixDotTextureRects(:, i) = [
        x - frameSize/2
        y - frameSize/2
        x + frameSize/2
        y + frameSize/2
        ];
end

% Cue text position
design.cueY                 = design.centerY - round(0.45 * ptb.PixPerDegHeight); % cue position on screen
% Cue legend layout
design.legendYSpacing       = round(0.8 * ptb.PixPerDegHeight);
design.legendCrossSize      = round(0.4 * ptb.PixPerDegWidth);
design.legendArrowLength    = round(0.3 * ptb.PixPerDegWidth);
design.legendGap            = round(0.08 * ptb.PixPerDegWidth);
legendWidth                 = design.legendCrossSize + design.legendGap + ... % Total width: cross + gap + arrow + gap + pictogram
    design.legendArrowLength + design.legendGap + design.legendPictogramSize;
% Cue legend x position
design.legendX              = ptb.xCenter - legendWidth/2;
% Cue legend elements x positions
design.legendCrossCenterX   = design.legendX + design.legendCrossSize/2;
design.legendArrowX         = design.legendX + design.legendCrossSize + design.legendGap;
design.legendPictogramX     = design.legendArrowX + design.legendArrowLength + design.legendGap;
% Cue legend y position(s)
design.legendY1             = design.centerY + round(0.2 * ptb.PixPerDegHeight);
design.legendY2             = design.legendY1 + design.legendYSpacing;
% Pictogram rectangles on screen
design.housePictogramRect = [ ...
    design.legendPictogramX, ...
    design.legendY1, ...
    design.legendPictogramX + design.legendPictogramSize, ...
    design.legendY1 + design.legendPictogramSize];
design.facePictogramRect = [ ...
    design.legendPictogramX, ...
    design.legendY2, ...
    design.legendPictogramX + design.legendPictogramSize, ...
    design.legendY2 + design.legendPictogramSize];

% blue lines (only relevant for shutterglass synchronization)
design.blueRectLeftOn   = [0,                 ptb.windowRect(4)-1, ptb.windowRect(3)/4,   ptb.windowRect(4)];
design.blueRectLeftOff  = [ptb.windowRect(3)/4,   ptb.windowRect(4)-1, ptb.windowRect(3),     ptb.windowRect(4)];
design.blueRectRightOn  = [0,                 ptb.windowRect(4)-1, ptb.windowRect(3)*3/4, ptb.windowRect(4)];
design.blueRectRightOff = [ptb.windowRect(3)*3/4, ptb.windowRect(4)-1, ptb.windowRect(3),     ptb.windowRect(4)];

%% Appearance of elements
% stimulus frame
design.frameThickness = 0.02;
% [added 2026-11-10] centre of the contrast scaling of the textures
% (generate.contrastReferenceMask): 'visible' = mean of the stimulus content
% visible through the aperture (visible part of every texture has mean 128
% at every contrast); 'image' = whole captured square (before 2026-11-10,
% sub-01 to sub-99). Calibration and experiment of a subject must use the same.
design.contrastReference = 'visible';
design.frameColor = ptb.black;
design.crossesColor = ptb.black;
design.frameBaseColor = ptb.grey;
%pink noise
design.pinkNoiseBackground = true;  % false -> plain grey background as before
design.pinkNoiseMeanLum    = 0.5;   % mean luminance of the visible noise (0-1)
design.pinkNoiseRMS        = 0.10;  % SD of the visible noise (0-1; same definition as targetRMS in createFMRIStimuli)
design.pinkNoiseExponent   = 1;     % amplitude spectrum ~ 1/f^exponent (1 = pink)


% fixation cross
design.fixCrossLineWidth = 2;
design.fixCrossColor = ptb.black;
design.conditionColors = [[0.85 0.05 0.05]; [0.00 0.45 0.55]]; % colors of fix cross used to indicate condition

% fixation dot(s)
design.fixDotTransparency       = 1; % 0.5
design.fixDotColor              = [0.6, 0.6, 0.6];
design.fixDotColorInner              = [0.8, 0.8, 0.8];

% Gaussian fixation dot ('gaussian' style): colour it is blended towards and
% opacity at its centre. Light dot on the grey-level stimuli; use e.g.
% [0.15 0.15 0.15] for a dark dot. Lower fixDotGaussPeakAlpha = less salient.
design.fixDotGaussColor     = [0.85, 0.85, 0.85];
design.fixDotGaussPeakAlpha = 0.6;
% Contrast of the fixation dots in the four textures (generate.getContrastAdjustedImages):
%   'weakest': all dots get the contrast of the weakest texture (min of
%              house/face x left/right contrast from the training file)
%   'texture': each dot scales with its own texture (previous behaviour)
%   'fixed'  : all dots get design.fixDotContrast
%   'local'  : [added 2026-11-05] as 'texture' between textures, but each dot's
%              step over the mean grey under it is the same fraction of that
%              mean at every position (generate.localDotTargets)
design.fixDotContrastMode   = 'local';   % [changed 2026-11-06] was 'texture' (sub-01, sub-03)
design.fixDotContrast       = 1;
% 'local' only:
%   fixDotLocalWeber: step of the dot over the mean grey under it, as a fraction
%     of that mean (Weber contrast), the same for all four textures (equal
%     visibility in both eyes, house and face). [] = scale with the texture
%     contrast as in 'texture' (0.6*89*c/128). 0.39 = the value of a texture at
%     the calibration's mean contrast (0.938), i.e. the geometric mean of the
%     texture-scaled values.
%   fixDotLocalRadiusInDegrees / fixDotLocalMaskGain: disc for the local clutter
%     (RMS contrast) around a dot, and its weight (0 = luminance only; > 0 = dots
%     on busy texture stronger, on smooth texture weaker, mean level unchanged)
design.fixDotLocalWeber           = 0.39;   % [added 2026-11-05]
if isequal(design.fixDotBig, true)
    design.fixDotLocalWeber = design.fixDotBigWeber;   % [added 2026-11-06] big dot, see above
end
%   fixDotLocalLumExponent: how the step follows the brightness under the dot
%     (generate.localDotTargets): 1 = same step / local mean everywhere (Weber;
%     bright cheek -> large step), 0 = same step in grey levels everywhere
%     (fixDotLocalWeber * 128), in between = partly. 0 matched the sub-test
%     detection pilot on the face (2026-11-05) and the impression that the
%     cheek dots were too visible with 1.
design.fixDotLocalLumExponent     = 0;      % [added 2026-11-05]
design.fixDotLocalRadiusInDegrees = 0.15;
design.fixDotLocalMaskGain        = 0;

% fixation dot frame(s) ('frame' style)
design.fixDotFrameLineWidth = 1;
design.fixDotFrameColor = [0.5, 0.5, 0.5];

%% Additional visual parameters
% fixation dot(s)/frame(s)
design.fixDotFadeDuration = 0.2;
design.fixDotFadeFrames = round(design.fixDotFadeDuration / ptb.ifi);

%% Create Textures
% Create the fixation-dot texture
if strcmp(design.fixDotStyle, 'gaussian')
    design.fixDotTexture = generate.createGaussianFixDotTexture( ...
        ptb, ...
        design.fixDotFrameSizeInPixels, ...
        design.fixDotSigmaInPixels, ...
        design.fixDotGaussColor, ...
        design.fixDotGaussPeakAlpha);
else
    % combined fixation-dot/frame texture (previous version)
    design.fixDotTexture = generate.createFixDotTexture( ...
        ptb, ...
        design.fixDotFrameSizeInPixels, ...
        design.fixDotSizeInPixels, ...
        design.fixDotFrameColor, ...
        design.fixDotFrameLineWidth, ...
        design.fixDotColor, ...
        design.fixDotColorInner);
end

% stimuli
design.defaultLuminance = 128;
% [changed 2026-11-11] no prompt at start-up any more: without a training file the
% textures use the defaults (all 1). main.m asks only when a part that shows the
% textures is chosen (main experiment, training, fixDot practice, QUEST+ test) and
% then calls this function again with design.stimuliParametersOverride (typed contrasts).
if fieldSet(design, 'stimuliParametersOverride')
    stimuliParameters = design.stimuliParametersOverride;
    trainingFile = '';
    if isfield(stimuliParameters, 'savedFile'); trainingFile = stimuliParameters.savedFile; end
    fprintf('Contrasts entered by hand: house %.4f, face %.4f | left eye %.4f, right eye %.4f\n', ...
        stimuliParameters.houseContrast, stimuliParameters.faceContrast, ...
        stimuliParameters.leftEyeContrast, stimuliParameters.rightEyeContrast);
else
    [stimuliParameters, trainingFile] = loadLatestTrainingParameters(myPaths.subjectDirectory, false);
end
% record of the contrasts used for the textures (saved with design.mat)
design.stimuliParameters = stimuliParameters;
design.trainingFile      = trainingFile;     % '' = default contrasts (no training file)
design.textureContrasts  = struct( ...
    'HouseL', stimuliParameters.houseContrast * stimuliParameters.leftEyeContrast, ...
    'FaceL',  stimuliParameters.faceContrast  * stimuliParameters.leftEyeContrast, ...
    'HouseR', stimuliParameters.houseContrast * stimuliParameters.rightEyeContrast, ...
    'FaceR',  stimuliParameters.faceContrast  * stimuliParameters.rightEyeContrast);
design = generate.getContrastAdjustedImages(ptb, design, stimuliParameters, myPaths, ...
    design.fixDotTexture, design.fixDotTransparency);
% [added 2026-11-10] the contrasts must be used with the contrast reference they
% were calibrated with (calibrations before 2026-11-10: 'image')
if isfield(stimuliParameters, 'questPlus')
    calRef = 'image';
    if isfield(stimuliParameters.questPlus, 'contrastReference'); calRef = stimuliParameters.questPlus.contrastReference; end
    usedRef = design.contrastReferenceInfo(1).mode;
    if ~strcmp(calRef, usedRef)
        warning('getVisualDesignSettings:contrastReference', ['The contrasts in %s were calibrated with ' ...
            'contrastReference ''%s'', but the textures now use ''%s''. Set design.contrastReference = ''%s'' ' ...
            'in getVisualDesignSettings.m for this subject, or calibrate again.'], trainingFile, calRef, usedRef, calRef);
    end
end
% low-level statistics (area in the aperture, RMS contrast, ...) of the house
% and face texture shown together, for this subject's contrasts (saved with design.mat)
try
    design.textureStats = image_stats.textureStats(design, ptb, true);
catch ME
    warning('getVisualDesignSettings:textureStats', 'Texture statistics not computed: %s', ME.message);
end
save_utils.saveDesignImages(design,fullfile(myPaths.stimuliLocation,'debugImages'))
design.stimuli.house_low = Screen('MakeTexture', ptb.window, ...
    imread(fullfile(myPaths.stimuliLocation, 'house_low.png')));
design.stimuli.face_low = Screen('MakeTexture', ptb.window, ...
    imread(fullfile(myPaths.stimuliLocation, 'face_low.png')));
design.stimuli.grey_square = Screen('MakeTexture', ptb.window, ...
    imread(fullfile(myPaths.stimuliLocation, 'grey_square.png')));
design.stimuli.superimposed = Screen('MakeTexture', ptb.window, ...
    imread(fullfile(myPaths.stimuliLocation, 'superimposed.png')));


% stimulus frame texture
design.frameTexture = generate.createOApertureXFrame(...
    design.frameSizeInPixelsX, ...
    design.frameSizeInPixelsY, ...
    design.apertureDiameterInPixels,...
    design.frameThickness, ...
    design.frameColor, ...
    design.crossesSizeInPixels, ...
    design.crossesWidthInPixels, ...
    design.crossesColor, ...
    design.crossesInsetInPixels, ...
    design.frameBaseColor, ...
    ptb.window);

% create background fusion mask texture 
fusionMask = imread(fullfile(myPaths.conditionPath, 'bw_frame.jpg'));
fusionMaskResized = imresize(fusionMask, [design.fusionMaskInPixelsY, design.fusionMaskInPixelsX]);   % [rows cols]
design.backGroundTexture = Screen('MakeTexture', ptb.window, fusionMaskResized);

% Create textures for legend pictograms
[housePictogram,~,houseAlpha] = imread(fullfile(myPaths.conditionPath,'house_pictogram.png'));
[facePictogram,~,faceAlpha] = imread(fullfile(myPaths.conditionPath,'face_pictogram.png'));
housePictogram = cat(3,housePictogram,houseAlpha);
facePictogram = cat(3,facePictogram,faceAlpha);
design.housePictogramTexture = Screen('MakeTexture',ptb.window,housePictogram);
design.facePictogramTexture = Screen('MakeTexture',ptb.window,facePictogram);
end


function tf = fieldSet(s, name)
% [added 2026-11-06] true if the struct / DataContainer s already has a non-empty field name
if isstruct(s)
    tf = isfield(s, name) && ~isempty(s.(name));
else
    tf = s.hasField(name) && ~isempty(s.(name));
end
end
