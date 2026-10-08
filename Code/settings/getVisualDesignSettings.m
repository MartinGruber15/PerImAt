function design = getVisualDesignSettings(ptb, myPaths, design)
if nargin < 3
    design = struct(); % Initialize the design structure
end
% Screen center
design.centerX = ptb.centerX;
design.centerY = ptb.centerY;

%% Displayed elements in visual degrees
design.stimSizeInDegrees        = 2.5;      % stimulus size in visual deg.
design.frameSizeFactor          = 1.3;%1.1  % frame around stimulus
design.frameApertureFactor      = 2/3;      % circular aperture (=stimulus window)
design.crossesSizeInDegrees     = 0.5;      % Crosses in the edge of the frame
design.crossesWidthInDegrees    = 0.08;     % width of crosses in frame edges
design.crossesInsetInDegrees    = 0.15;     % distance of frame crosses from edges
design.fusionMaskInDegrees      = 8;        % surrounding fusion-aid frame
design.fixCrossInDegrees        = 0.2;      % Fixation cross in degrees
design.fixDotSizeInDegrees      = 0.3;      % Fixation dots for no-report in degrees
design.fixDotFrameSizeInDegrees = 0.35;%35? % Frame around fixation dot
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
design.fixDotDistanceInPixels = min(design.stimSizeInPixelsX / 2.3,design.stimSizeInPixelsY / 2.3) / 2; % 3 3 2
d = design.fixDotDistanceInPixels;
% screen coordinates of the 6 possible positions
% 1 . 2
% 6 + 3
% 5 . 4
design.fixDotPositions = [
    design.centerX - d, design.centerY - d;  % 1 = top-left
    design.centerX + d, design.centerY - d;  % 2 = top-right
    design.centerX + d, design.centerY;      % 3 = right
    design.centerX + d, design.centerY + d   % 4 = bottom-right
    design.centerX - d, design.centerY + d;  % 5 = bottom-left
    design.centerX - d, design.centerY;      % 6 = left
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
design.fixDotTransparency       = 0.5; % 0.5
design.fixDotColor              = [0.45, 0.45, 0.45];

% fixation dot frame(s)
design.fixDotFrameLineWidth = 1;
design.fixDotFrameColor = [0.65, 0.65, 0.65];

%% Additional visual parameters
% fixation dot(s)/frame(s)
design.fixDotFadeDuration = 0.2;
design.fixDotFadeFrames = round(design.fixDotFadeDuration / ptb.ifi);

%% Create Textures
% stimuli
design.defaultLuminance = 128;
stimuliParameters = loadLatestTrainingParameters(myPaths.subjectDirectory);
[design.stimuli.house,design.masks.house,design.images.house] = createAdaptiveTexture( ...
    ptb, ...
    fullfile(myPaths.stimuliLocation, 'house.png'), ...
    design.defaultLuminance, ...
    stimuliParameters.houseContrast);
[design.stimuli.face,design.masks.face,design.images.face] = createAdaptiveTexture( ...
    ptb, ...
    fullfile(myPaths.stimuliLocation, 'face.png'), ...
    design.defaultLuminance, ...
    stimuliParameters.faceContrast);
% Eye-specific versions: final contrast = stimulus contrast x eye contrast.
% houseL/faceL are shown to the left eye, houseR/faceR to the right eye.
eyeNames     = {'L', 'R'};
eyeContrasts = [stimuliParameters.leftEyeContrast, stimuliParameters.rightEyeContrast];
cfgC         = stimuliParameters.configContrast;
houseCfg     = [cfgC, 1/cfgC];     % [houseL houseR]
faceCfg      = [1/cfgC, cfgC];     % [faceL  faceR ]
for e = 1:2
    houseName = ['house' eyeNames{e}];
    faceName  = ['face'  eyeNames{e}];
    [design.stimuli.(houseName),design.masks.(houseName),design.images.(houseName)] = createAdaptiveTexture( ...
        ptb, ...
        fullfile(myPaths.stimuliLocation, 'house.png'), ...
        design.defaultLuminance, ...
        stimuliParameters.houseContrast * eyeContrasts(e) * houseCfg(e));
    [design.stimuli.(faceName),design.masks.(faceName),design.images.(faceName)] = createAdaptiveTexture( ...
        ptb, ...
        fullfile(myPaths.stimuliLocation, 'face.png'), ...
        design.defaultLuminance, ...
        stimuliParameters.faceContrast * eyeContrasts(e) * faceCfg(e));
end
design.stimuli.house_low = Screen('MakeTexture', ptb.window, ...
    imread(fullfile(myPaths.stimuliLocation, 'house_low.png')));
design.stimuli.face_low = Screen('MakeTexture', ptb.window, ...
    imread(fullfile(myPaths.stimuliLocation, 'face_low.png')));
[design.stimuli.houseFace,design.masks.houseFace,design.images.houseFace] = createTexture(ptb,fullfile(myPaths.stimuliLocation, 'catch_houseface.png'));
[design.stimuli.faceHouse,design.masks.faceHouse,design.images.faceHouse] = createTexture(ptb,fullfile(myPaths.stimuliLocation, 'catch_facehouse.png'));
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
fusionMaskResized = imresize(fusionMask, [design.fusionMaskInPixelsX, design.fusionMaskInPixelsY]);
design.backGroundTexture = Screen('MakeTexture', ptb.window, fusionMaskResized);

% Create combined fixation-dot/frame texture
design.fixDotTexture.houseL = generate.createFixDotTexture( ...
    ptb, ...
    design.fixDotFrameSizeInPixels, ...
    design.fixDotSizeInPixels, ...
    design.fixDotFrameColor, ...
    design.fixDotFrameLineWidth, ...
    design.fixDotColor, ...
    stimuliParameters.houseContrast * eyeContrasts(1) * houseCfg(1));
design.fixDotTexture.houseR = generate.createFixDotTexture( ...
    ptb, ...
    design.fixDotFrameSizeInPixels, ...
    design.fixDotSizeInPixels, ...
    design.fixDotFrameColor, ...
    design.fixDotFrameLineWidth, ...
    design.fixDotColor, ...
    stimuliParameters.houseContrast * eyeContrasts(2) * houseCfg(2));
design.fixDotTexture.faceL = generate.createFixDotTexture( ...
    ptb, ...
    design.fixDotFrameSizeInPixels, ...
    design.fixDotSizeInPixels, ...
    design.fixDotFrameColor, ...
    design.fixDotFrameLineWidth, ...
    design.fixDotColor, ...
    stimuliParameters.faceContrast * eyeContrasts(1) * faceCfg(1));
design.fixDotTexture.faceR = generate.createFixDotTexture( ...
    ptb, ...
    design.fixDotFrameSizeInPixels, ...
    design.fixDotSizeInPixels, ...
    design.fixDotFrameColor, ...
    design.fixDotFrameLineWidth, ...
    design.fixDotColor,...
    stimuliParameters.faceContrast * eyeContrasts(2) * faceCfg(2));
design.fixDotTexture.houseFaceL = generate.createFixDotTexture( ...
    ptb, ...
    design.fixDotFrameSizeInPixels, ...
    design.fixDotSizeInPixels, ...
    design.fixDotFrameColor, ...
    design.fixDotFrameLineWidth, ...
    design.fixDotColor, ...
    stimuliParameters.houseContrast * eyeContrasts(1) * houseCfg(1));
design.fixDotTexture.houseFaceR = generate.createFixDotTexture( ...
    ptb, ...
    design.fixDotFrameSizeInPixels, ...
    design.fixDotSizeInPixels, ...
    design.fixDotFrameColor, ...
    design.fixDotFrameLineWidth, ...
    design.fixDotColor, ...
    stimuliParameters.houseContrast * eyeContrasts(2) * houseCfg(2));
design.fixDotTexture.faceHouseL = generate.createFixDotTexture( ...
    ptb, ...
    design.fixDotFrameSizeInPixels, ...
    design.fixDotSizeInPixels, ...
    design.fixDotFrameColor, ...
    design.fixDotFrameLineWidth, ...
    design.fixDotColor, ...
    stimuliParameters.faceContrast * eyeContrasts(1) * faceCfg(1));
design.fixDotTexture.faceHouseR = generate.createFixDotTexture( ...
    ptb, ...
    design.fixDotFrameSizeInPixels, ...
    design.fixDotSizeInPixels, ...
    design.fixDotFrameColor, ...
    design.fixDotFrameLineWidth, ...
    design.fixDotColor,...
    stimuliParameters.faceContrast * eyeContrasts(2) * faceCfg(2));
% Create textures for legend pictograms
[housePictogram,~,houseAlpha] = imread(fullfile(myPaths.conditionPath,'house_pictogram.png'));
[facePictogram,~,faceAlpha] = imread(fullfile(myPaths.conditionPath,'face_pictogram.png'));
housePictogram = cat(3,housePictogram,houseAlpha);
facePictogram = cat(3,facePictogram,faceAlpha);
design.housePictogramTexture = Screen('MakeTexture',ptb.window,housePictogram);
design.facePictogramTexture = Screen('MakeTexture',ptb.window,facePictogram);

end

function [texture,alpha,image] = createAdaptiveTexture(ptb, filename, luminance, contrast)
[image,~,alpha] = imread(filename);
image = double(image);
meanImage = mean(image(:));
image = (image - meanImage) .* contrast + luminance;
image = uint8(image);
if ~isempty(alpha)
    rgba = cat(3, image, alpha);  % grayscale→RGB + alpha
    texture = Screen('MakeTexture', ptb.window, rgba);
else
    texture = Screen('MakeTexture', ptb.window, image);
end
end
function [texture,alpha,image] = createTexture(ptb, filename)
[image,~,alpha] = imread(filename);
if ~isempty(alpha)
    rgba = cat(3, image, alpha);  % grayscale→RGB + alpha
    texture = Screen('MakeTexture', ptb.window, rgba);
else
    texture = Screen('MakeTexture', ptb.window, image);
end
end