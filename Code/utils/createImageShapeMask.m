function masktex = createImageShapeMask(window, img, shape)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cuts an image into an hexagonal, octagonal or decagonal shape and returns
% it as texture
% 
% Input:
%   window: the window the texture is created for
%   img: the image that is cut into the shape
%   shape: the shape. Options: ['hex', 'oct', 'dec']
% 
% Output: n-sided image texture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[height, width, ~] = size(img);
[x, y] = meshgrid(linspace(-1, 1, width), linspace(-1, 1, height));

% Convert to polar coordinates
[theta, r] = cart2pol(x, y);

% Define polygon mask
switch lower(shape)
    case 'hex'
        nSides = 6;
    case 'oct'
        nSides = 8;
    case 'dec'
        nSides = 10;
    otherwise
        error('Shape must be "hex" or "oct"');
end

% Polygonal boundary function
rMax = cos(pi/nSides) ./ cos(mod(theta, 2*pi/nSides) - pi/nSides);

mask = double(r <= rMax); % inside polygon = 1, outside = 0

% Combine with image
if size(img,3)==3
    img = uint8(img); % ensure image type
    maskAlpha = uint8(mask * 255);
    imgWithAlpha = cat(3, img, maskAlpha);
else
    error('Image must be RGB');
end

% Make texture
masktex = Screen('MakeTexture', window, imgWithAlpha);
end