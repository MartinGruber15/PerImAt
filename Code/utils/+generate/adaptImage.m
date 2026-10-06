function image = adaptImage(rawImage, luminance, contrast)
% adaptImage  Set mean luminance and contrast of a stimulus image.
%
% Same operation as createAdaptiveTexture in getVisualDesignSettings, but
% returns the uint8 image so it can be re-generated with new contrast values
% at any time (e.g. block by block in speedRunOnset) and then be passed to
% generate.makePinkNoiseTex.
%
%   image = (raw - mean(raw)) * contrast + luminance      (clipped to 0..255)

image = double(rawImage);
meanImage = mean(image(:));
image = (image - meanImage) .* contrast + luminance;
image = uint8(image);
end
