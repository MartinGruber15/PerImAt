function design = computeDesignScreenPositions(ptb, design)
% computeDesignScreenPositions
%
% Computes all screen-related design parameters from the visual-angle
% definitions stored in design and the display properties stored in ptb.
%
% INPUTS
%   ptb     - PTB/display parameters, including:
%             .PixPerDegWidth
%             .PixPerDegHeight
%             .centerX
%             .centerY
%
%   design  - Design structure containing visual-angle definitions:
%             .stimSizeInDegrees
%             .fusionMaskInDegrees
%             .fixCrossInDegrees
%             .fixDotSizeInDegrees
%
% OUTPUT
%   design  - Design structure with all corresponding pixel values,
%             positions, and rectangles added.
%% Screen center
design.centerX = ptb.centerX;
design.centerY = ptb.centerY;

%% Convert visual degrees to pixels
% Stimulus size
design.stimSizeInPixelsX = round(ptb.PixPerDegWidth * design.stimSizeInDegrees);
design.stimSizeInPixelsY = round(ptb.PixPerDegHeight * design.stimSizeInDegrees);
%% Frame / aperture
design.frameSizeInDegrees = design.stimSizeInDegrees * design.frameSizeFactor;
design.frameSizeInPixelsX = round(ptb.PixPerDegWidth * design.frameSizeInDegrees);
design.frameSizeInPixelsY = round(ptb.PixPerDegHeight * design.frameSizeInDegrees);
% Circular aperture
design.frameApertureInDegrees = design.frameSizeInDegrees * design.frameApertureFactor;
design.apertureDiameterInPixels = round(ptb.PixPerDegWidth * design.frameApertureInDegrees);
design.fusionMaskInPixelsX = round(ptb.PixPerDegWidth * design.fusionMaskInDegrees);
design.fusionMaskInPixelsY = round(ptb.PixPerDegHeight * design.fusionMaskInDegrees);
% Fixation cross size
design.fixCrossInPixelsX = round(ptb.PixPerDegWidth * design.fixCrossInDegrees);
design.fixCrossInPixelsY = round(ptb.PixPerDegHeight * design.fixCrossInDegrees);
% Fixation dot(s) size and frame size
design.fixDotSizeInPixels = round(ptb.PixPerDegWidth * design.fixDotSizeInDegrees);
design.fixDotFrameSizeInPixels = round(ptb.PixPerDegWidth * design.fixDotFrameSizeInDegrees);
% legend pictograms
design.legendPictogramSize = round(design.legendPictogramInDegrees * ptb.PixPerDegHeight);
design.cueY = design.centerY - design.stimSizeInPixelsY/6; % cue position on screen

textY = design.centerY + design.stimSizeInPixelsY/10;
% Legend layout
design.legendYSpacing = round(0.5 * ptb.PixPerDegHeight);
design.legendCrossSize = round(0.2 * ptb.PixPerDegWidth);
design.legendArrowLength = round(0.3 * ptb.PixPerDegWidth);
design.legendGap = round(0.08 * ptb.PixPerDegWidth);

% Total width: cross + gap + arrow + gap + pictogram
legendWidth = design.legendCrossSize + ...
    design.legendGap + design.legendArrowLength + ...
    design.legendGap + design.legendPictogramSize;

design.legendX = ptb.xCenter - legendWidth/2;

% X positions
design.legendCrossCenterX = design.legendX + design.legendCrossSize/2;
design.legendArrowX = design.legendX + design.legendCrossSize + design.legendGap;
design.legendPictogramX = design.legendArrowX + design.legendArrowLength + design.legendGap;

% Y positions
design.legendY1 = textY;
design.legendY2 = textY + design.legendYSpacing;

% Pictogram rectangles
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

%% Fixation cross
% Fixation cross coordinates relative to its center
design.fixCrossCoords = [
    -design.fixCrossInPixelsX/2 design.fixCrossInPixelsX/2 0 0; ...
    0 0 -design.fixCrossInPixelsY/2 design.fixCrossInPixelsY/2];
% Appearance
design.fixCrossLineWidth = 1;
design.fixCrossColor = ptb.black;

%% Fixation dots
% Distance of fixation dots from the center
design.fixDotDistanceInPixels = min( ...
    design.stimSizeInPixelsX / 3, ...
    design.stimSizeInPixelsY / 3) / 2;

%% Fixation-dot positions
d = design.fixDotDistanceInPixels;

% Position numbering:
%
%   1 = left
%   2 = top
%   3 = right
%   4 = bottom
%   5 = top-left
%   6 = top-right
%   7 = bottom-left
%   8 = bottom-right

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


%% Valid fixation-dot pairs
% Cardinal pairs
design.fixDotCardinalPairs = [];
for i = 1:4
    for j = 1:4
        if i ~= j
            design.fixDotCardinalPairs(end+1,:) = [i j];
        end
    end
end
% Diagonal pairs
design.fixDotDiagonalPairs = [];
for i = 5:8
    for j = 5:8
        if i ~= j
            design.fixDotDiagonalPairs(end+1,:) = [i j];
        end
    end
end

%% Fixation-dot frame rectangles
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

%fade parameter
design.fixDotFadeDuration = 0.2;
design.fixDotFadeFrames = round(design.fixDotFadeDuration / ptb.ifi);

% Fixation dot(s) appearance
design.fixDotTransparency       = 0.5;
design.fixDotColor              = [0.25, 0.25, 0.25];
% Frame appearance
design.fixDotFrameLineWidth = 1;
design.fixDotFrameColor = [0.75, 0.55, 0.75];

% Create combined fixation-dot/frame texture
design.fixDotTexture = createFixDotTexture( ...
    ptb, ...
    design.fixDotFrameSizeInPixels, ...
    design.fixDotSizeInPixels, ...
    design.fixDotFrameColor, ...
    design.fixDotFrameLineWidth, ...
    design.fixDotColor);

%% Destination rectangle
% Rectangle in which the stimulus is drawn
design.destinationRect = [ ...
    design.centerX - design.stimSizeInPixelsX/2, ...
    design.centerY - design.stimSizeInPixelsY/2, ...
    design.centerX + design.stimSizeInPixelsX/2, ...
    design.centerY + design.stimSizeInPixelsY/2];

design.frameRect = [ ...
    design.centerX - design.frameSizeInPixelsX/2, ...
    design.centerY - design.frameSizeInPixelsY/2, ...
    design.centerX + design.frameSizeInPixelsX/2, ...
    design.centerY + design.frameSizeInPixelsY/2];

design.frameTexture = createFrameTexture( ...
    ptb, ...
    design.frameSizeInPixelsX, ...
    design.frameSizeInPixelsY, ...
    design.apertureDiameterInPixels);
end

function texture = createFixDotTexture( ...
        ptb, frameSize, dotSize, frameColor, frameLineWidth, dotColor)

    % RGB image
    image = zeros(frameSize, frameSize, 3, 'uint8');
    center = (frameSize + 1) / 2;

    %% Frame
    frameMask = false(frameSize, frameSize);

    frameMask(1:frameLineWidth, :) = true;
    frameMask(end-frameLineWidth+1:end, :) = true;
    frameMask(:, 1:frameLineWidth) = true;
    frameMask(:, end-frameLineWidth+1:end) = true;
    frameColor255 = uint8(round(frameColor * 255));
    for c = 1:3
        channel = image(:,:,c);
        channel(frameMask) = frameColor255(c);
        image(:,:,c) = channel;
    end

    %% Fixation dot
    [X, Y] = meshgrid(1:frameSize, 1:frameSize);
    dotMask = ...
        (X - center).^2 + ...
        (Y - center).^2 <= (dotSize/2)^2;

    dotColor255 = uint8(round(dotColor));
    for c = 1:3
        channel = image(:,:,c);
        channel(dotMask) = dotColor255(c);
        image(:,:,c) = channel;
    end

    %% Make everything outside the frame transparent
    %
    % We need an alpha channel so that the rectangular texture does not
    % obscure the stimulus. The frame and dot themselves are opaque.
    alpha = uint8((frameMask | dotMask) * 255);
    image = cat(3, image, alpha);
    %% Create PTB texture
    texture = Screen('MakeTexture', ptb.window, image);

end

function texture = createFrameTexture(ptb, frameWidth, frameHeight, apertureDiameter)

%% Parameters
frameThickness = 0.02;
frameColor = ptb.black;
crossSize = round(0.5 * ptb.PixPerDegWidth);
crossThickness = round(0.08 * ptb.PixPerDegWidth);
crossColor = ptb.black;
crossInset = round(0.15 * ptb.PixPerDegWidth);

% Convert PTB colors to RGB uint8
grey = colorToUint8(ptb.grey);
frameColor = colorToUint8(frameColor);
crossColor = colorToUint8(crossColor);

%% Create RGBA image
image = zeros(frameHeight, frameWidth, 4, 'uint8');
image(:,:,1) = grey(1);
image(:,:,2) = grey(2);
image(:,:,3) = grey(3);

%% Circular aperture
centerX = (frameWidth + 1) / 2;
centerY = (frameHeight + 1) / 2;
[X,Y] = meshgrid(1:frameWidth, 1:frameHeight);
distanceFromCenter = hypot(X - centerX, Y - centerY);

radiusOuter = apertureDiameter / 2;
radiusInner = radiusOuter * (1 - frameThickness);

apertureMask = distanceFromCenter < radiusInner;
ringMask = distanceFromCenter >= radiusInner & distanceFromCenter <= radiusOuter;

alpha = uint8(255 * ones(frameHeight, frameWidth));
alpha(apertureMask) = 0;

% Circular border
for c = 1:3
    channel = image(:,:,c);
    channel(ringMask) = frameColor(c);
    image(:,:,c) = channel;
end

%% Corner Xs
% Define the four corner centers symmetrically.
leftX = crossInset + crossSize/2;
rightX = frameWidth - crossInset - crossSize/2;
topY = crossInset + crossSize/2;
bottomY = frameHeight - crossInset - crossSize/2;

% Top-left
image = drawThickLine(image, ...
    leftX - crossSize/2, topY - crossSize/2, ...
    leftX + crossSize/2, topY + crossSize/2, ...
    crossThickness, crossColor);
image = drawThickLine(image, ...
    leftX - crossSize/2, topY + crossSize/2, ...
    leftX + crossSize/2, topY - crossSize/2, ...
    crossThickness, crossColor);

% Top-right
image = drawThickLine(image, ...
    rightX - crossSize/2, topY - crossSize/2, ...
    rightX + crossSize/2, topY + crossSize/2, ...
    crossThickness, crossColor);
image = drawThickLine(image, ...
    rightX - crossSize/2, topY + crossSize/2, ...
    rightX + crossSize/2, topY - crossSize/2, ...
    crossThickness, crossColor);

% Bottom-left
image = drawThickLine(image, ...
    leftX - crossSize/2, bottomY - crossSize/2, ...
    leftX + crossSize/2, bottomY + crossSize/2, ...
    crossThickness, crossColor);
image = drawThickLine(image, ...
    leftX - crossSize/2, bottomY + crossSize/2, ...
    leftX + crossSize/2, bottomY - crossSize/2, ...
    crossThickness, crossColor);

% Bottom-right
image = drawThickLine(image, ...
    rightX - crossSize/2, bottomY - crossSize/2, ...
    rightX + crossSize/2, bottomY + crossSize/2, ...
    crossThickness, crossColor);
image = drawThickLine(image, ...
    rightX - crossSize/2, bottomY + crossSize/2, ...
    rightX + crossSize/2, bottomY - crossSize/2, ...
    crossThickness, crossColor);

%% Create texture
image(:,:,4) = alpha;
texture = Screen('MakeTexture', ptb.window, image);

end

function color = colorToUint8(color)
if isscalar(color), color = [color color color]; end
color = double(color);

if max(color) <= 1
    color = color * 255;
elseif max(color) > 255
    color = color / max(color) * 255;
end

color = uint8(round(max(0, min(255, color))));
end

function image = drawThickLine(image, x0, y0, x1, y1, thickness, color)
dx = abs(x1 - x0);
dy = abs(y1 - y0);
sx = sign(x1 - x0);
sy = sign(y1 - y0);
err = dx - dy;

while true
    for tx = -floor(thickness/2):ceil(thickness/2)
        for ty = -floor(thickness/2):ceil(thickness/2)
            x = round(x0 + tx);
            y = round(y0 + ty);

            if x >= 1 && x <= size(image,2) && y >= 1 && y <= size(image,1)
                image(y,x,1:3) = reshape(color,1,1,3);
                image(y,x,4) = 255;
            end
        end
    end

    if x0 == x1 && y0 == y1, break; end

    e2 = 2 * err;
    if e2 > -dy
        err = err - dy;
        x0 = x0 + sx;
    end
    if e2 < dx
        err = err + dx;
        y0 = y0 + sy;
    end
end
end
