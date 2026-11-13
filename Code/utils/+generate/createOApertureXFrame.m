function texture = createOApertureXFrame(frameWidth, frameHeight, apertureDiameter, frameThickness, frameColor, crossSize, crossThickness,crossColor, crossInset, baseColor, window)
% All size values have to be in pixels
% Convert PTB colors to RGB uint8
baseColor = colorToUint8(baseColor);
frameColor = colorToUint8(frameColor);
crossColor = colorToUint8(crossColor);

%% Create RGBA image
image = zeros(frameHeight, frameWidth, 4, 'uint8');
image(:,:,1) = baseColor(1);
image(:,:,2) = baseColor(2);
image(:,:,3) = baseColor(3);

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
texture = Screen('MakeTexture', window, image);
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
