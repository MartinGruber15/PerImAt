function [mask, refMean, info] = contrastReferenceMask(img, design)
% generate.contrastReferenceMask  Pixels whose mean is the centre of the contrast scaling. [added 2026-11-10]
%
%   [mask, refMean, info] = generate.contrastReferenceMask(img, design)
%
% The texture contrast c is applied as out = (img - m) * c + 128
% (generate.getContrastAdjustedImages, questplus.applyContrast). This
% function returns the pixels m is taken from, per design.contrastReference:
%   'visible' (default): stimulus content (not the uniform grey background,
%             which becomes pink noise) that is VISIBLE through the frame
%             aperture (generate.visibleMask). Then the visible part of every
%             texture has mean 128 at every contrast, and its RMS contrast is
%             c times that of the image file (createFMRIStimuli 'visible'
%             matches mean and RMS on the same region).
%   'image'  : the whole captured image (before 2026-11-10; sub-01 to sub-99)
% img    : captured image (as questplus.captureRawStimuli /
%          getContrastAdjustedImages capture it), later drawn into
%          design.destinationRect
% design : needs destinationRect, frameRect, frameSizeInPixelsX/Y,
%          apertureDiameterInPixels, frameThickness for 'visible'; without
%          them (e.g. tests) the whole image is used, with a warning
% refMean: mean grey of img over mask
% info   : mode used, number of pixels, content / visible pixel counts
g = double(img(:, :, 1));
mode = 'visible';
if hasF(design, 'contrastReference') && ~isempty(design.contrastReference); mode = lower(char(design.contrastReference)); end
needed = {'destinationRect', 'frameRect', 'frameSizeInPixelsX', 'frameSizeInPixelsY', 'apertureDiameterInPixels', 'frameThickness'};
if strcmp(mode, 'visible') && ~all(cellfun(@(f) hasF(design, f), needed))
    warning('contrastReferenceMask:noFrame', 'No frame geometry in design: contrast reference = whole image.');
    mode = 'image';
end
switch mode
    case 'image'
        mask = true(size(g));
        content = mask; visible = mask;
    case 'visible'
        border = [g(1, :), g(end, :), g(:, 1)', g(:, end)'];
        bgValue = mode_(round(border));
        content = imfill(round(g) ~= bgValue, 'holes');   % as makePinkNoiseTex (estimateContentMask)
        visible = generate.visibleMask(design, size(g, 1), size(g, 2));
        mask = content & visible;
        if nnz(mask) < 0.05 * numel(mask)
            warning('contrastReferenceMask:tooSmall', ...
                'Only %d visible content pixels: contrast reference = whole image.', nnz(mask));
            mask = true(size(g)); mode = 'image';
        end
    otherwise
        error('contrastReferenceMask:mode', 'design.contrastReference must be ''visible'' or ''image''.');
end
refMean = mean(g(mask));
info = struct('mode', mode, 'nPixels', nnz(mask), 'nContent', nnz(content), 'nVisible', nnz(visible), ...
    'refMean', refMean, 'refSD', std(g(mask), 1));
end

function tf = hasF(s, f)
if isstruct(s); tf = isfield(s, f); else; tf = s.hasField(f); end
end

function m = mode_(v)
m = mode(v(:)');
end
