function [gray, mask, source] = foregroundMask(filename, bgGray)
% image_stats.foregroundMask  Load a stimulus image as grey levels and find its foreground.
%
%   [gray, mask, source] = image_stats.foregroundMask(filename)
%   [gray, mask, source] = image_stats.foregroundMask(filename, bgGray)
%
% gray    double grey-level image (0-255; rgb2gray for colour images)
% mask    logical foreground (true = house/face pixels)
% source  how the mask was found, in this order:
%   'alpha'   : PNG alpha channel > 0
%   'magenta' : pixels that are not pure magenta [255 0 255] (the original
%               original source images)
%   'border'  : pixels that differ from the uniform background grey that
%               touches the image border; enclosed background-grey pixels count
%               as foreground (same idea as estimateContentMask in
%               generate.makePinkNoiseTex)
% bgGray  (optional) background grey of already matched images, used for
%         'border' instead of the most frequent border value.

[img, ~, alpha] = imread(filename);
img = double(img);
if size(img, 3) == 1
    rgb = repmat(img, [1 1 3]);
else
    rgb = img(:, :, 1:3);
end
gray = 0.2989 * rgb(:, :, 1) + 0.5870 * rgb(:, :, 2) + 0.1140 * rgb(:, :, 3);   % = rgb2gray weights

isMagenta = rgb(:, :, 1) == 255 & rgb(:, :, 2) == 0 & rgb(:, :, 3) == 255;
if ~isempty(alpha) && any(alpha(:) == 0)
    mask = alpha > 0;
    source = 'alpha';
elseif any(isMagenta(:))
    mask = ~isMagenta;
    source = 'magenta';
else
    g = round(gray);
    if nargin < 2 || isempty(bgGray)
        border = [g(1, :), g(end, :), g(:, 1)', g(:, end)'];
        bgGray = mode(border);
    end
    mask = imfill(g ~= round(bgGray), 'holes');
    source = 'border';
end
% the background is shown as 50 % grey (128) in all later steps
gray(~mask) = 128;
end
