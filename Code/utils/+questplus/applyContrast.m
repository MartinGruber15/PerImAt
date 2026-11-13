function output = applyContrast(input, contrast, targetLuminance, refMask)
% questplus.applyContrast  Scale image contrast around its mean.
%
% Identical to the local function applyContrast in
% generate.getContrastAdjustedImages (keep both in sync), so that the
% textures tested by QUEST+ are exactly those of the main experiment.
% [changed 2026-11-10] refMask (optional): pixels whose mean is the centre of
% the scaling (generate.contrastReferenceMask: visible stimulus content);
% without it the whole image (as before).
pixels = double(input);
if nargin < 4 || isempty(refMask)
    imageMean = mean(pixels(:));
else
    p1 = pixels(:,:,1);
    imageMean = mean(p1(refMask));
end
output = uint8(round(min(max((pixels - imageMean) .* contrast + targetLuminance, 0), 255)));
end
