function design = designSettingsVisuals(ptb, myPaths)
design = struct(); % Initialize the design structure

% Screen center
design.centerX = ptb.centerX;
design.centerY = ptb.centerY;

%% Displayed elements in visual degrees
design.stimSizeInDegrees        = 3.5;      % stimulus size in visual deg.
design.frameSizeFactor          = 1.3;%1.1  % frame around stimulus
design.frameApertureFactor      = 2/3;      % circular aperture (=stimulus window)
design.crossesSizeInDegrees     = 0.5;      % Crosses in the edge of the frame
design.crossesWidthInDegrees    = 0.08;     % width of crosses in frame edges
design.crossesInsetInDegrees    = 0.15;     % distance of frame crosses from edges
design.fusionMaskInDegrees      = 8;        % surrounding fusion-aid frame
design.fixCrossInDegrees        = 0.2;      % Fixation cross in degrees
design.fixDotSizeInDegrees      = 0.1;      % Fixation dots for no-report in degrees
design.fixDotFrameSizeInDegrees = 0.15;%35? % Frame around fixation dot
design.legendPictogramInDegrees = 0.5;      % key assignment legend pictograms

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
%TODO

% Fixation cross coordinates relative to its center
design.fixCrossCoords = [
    -design.fixCrossInPixelsX/2 design.fixCrossInPixelsX/2 0 0; ...
    0 0 -design.fixCrossInPixelsY/2 design.fixCrossInPixelsY/2];

% Fixation dot positions and coordinates for no-report BR
% Distance of fixation dots from the center
design.fixDotDistanceInPixels = min(design.stimSizeInPixelsX / 3,design.stimSizeInPixelsY / 3) / 2;
d = design.fixDotDistanceInPixels;
% screen coordinates of the 8 possible positions
% 5 2 6
% 1 + 3
% 7 4 8
design.fixDotPositions = [
    design.centerX - d, design.centerY;      % 1 = left
    design.centerX,     design.centerY - d;  % 2 = top
    design.centerX + d, design.centerY;      % 3 = right
    design.centerX,     design.centerY + d;  % 4 = bottom
    design.centerX - d, design.centerY - d;  % 5 = top-left
    design.centerX + d, design.centerY - d;  % 6 = top-right
    design.centerX - d, design.centerY + d;  % 7 = bottom-left
    design.centerX + d, design.centerY + d   % 8 = bottom-right
    ];
% valid position pairs (opposite sides)
design.fixDotValidPairs = [
    1 3
    3 1
    2 4
    4 2
    5 8
    8 5
    6 7
    7 6
    ];
% frame rectangles around fix dots
frameSize = design.fixDotFrameSizeInPixels;
design.fixDotTextureRects = zeros(4, 8);
for i = 1:8
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
design.cueY                 = design.centerY - design.stimSizeInPixelsY/6; % cue position on screen
% Cue legend layout
design.legendYSpacing       = round(0.5 * ptb.PixPerDegHeight);
design.legendCrossSize      = round(0.2 * ptb.PixPerDegWidth);
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
design.legendY1             = design.centerY + design.stimSizeInPixelsY/10;
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

%% Appearance of elements
% stimulus frame
design.frameThickness = 0.02;
design.frameColor = ptb.black;
design.crossesColor = ptb.black;
design.frameBaseColor = ptb.grey;

% fixation cross
design.fixCrossLineWidth = 1;
design.fixCrossColor = ptb.black;
design.conditionColors = [[255, 0, 0]; [0, 0, 135]]; % colors of fix cross used to indicate condition

% fixation dot(s)
design.fixDotTransparency       = 0.5;
design.fixDotColor              = [0.25, 0.25, 0.25];

% fixation dot frame(s)
design.fixDotFrameLineWidth = 1;
design.fixDotFrameColor = [0.75, 0.55, 0.75];

%% Additional visual parameters
% fixation dot(s)/frame(s)
design.fixDotFadeDuration = 0.2;
design.fixDotFadeFrames = round(design.fixDotFadeDuration / ptb.ifi);

%% Create Textures
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
fusionMask = imread(fullfile(myPaths.conditionPath, 'background.jpg'));
fusionMaskResized = imresize(fusionMask, [design.fusionMaskInPixelsX, design.fusionMaskInPixelsY]);
design.backGroundTexture = Screen('MakeTexture', ptb.window, fusionMaskResized);

% Create combined fixation-dot/frame texture
design.fixDotTexture = generate.createFixDotTexture( ...
    ptb, ...
    design.fixDotFrameSizeInPixels, ...
    design.fixDotSizeInPixels, ...
    design.fixDotFrameColor, ...
    design.fixDotFrameLineWidth, ...
    design.fixDotColor);

% Create textures for legend pictograms
[housePictogram,~,houseAlpha] = imread(fullfile(myPaths.conditionPath,'house_pictogram.png'));
[facePictogram,~,faceAlpha] = imread(fullfile(myPaths.conditionPath,'face_pictogram.png'));
housePictogram = cat(3,housePictogram,houseAlpha);
facePictogram = cat(3,facePictogram,faceAlpha);
design.housePictogramTexture = Screen('MakeTexture',ptb.window,housePictogram);
design.facePictogramTexture = Screen('MakeTexture',ptb.window,facePictogram);

end

