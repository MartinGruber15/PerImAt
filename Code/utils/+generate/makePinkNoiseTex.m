function [tex, info] = makePinkNoiseTex(win, stimImg, mask, design)
% makePinkNoiseTex  Composite stimulus over fresh pink noise, return one texture.
%
% Inputs
%   win      PTB window pointer
%   stimImg  HxW uint8 grayscale stimulus image (RGB before alpha was added)
%   mask     HxW uint8 alpha mask (0=background, 255=stimulus)
%   design   struct from getVisualDesignSettings

meanLum  = getParam(design, 'pinkNoiseMeanLum',  0.5);
noiseSD  = getParam(design, 'pinkNoiseRMS',       0.10);
exponent = getParam(design, 'pinkNoiseExponent',  1);
if isempty(mask) || all(mask(:) == 0)
    mask = uint8(estimateContentMask(stimImg(:,:,1))) * 255;
end
alpha = double(mask) / 255;
[nRows, nCols] = size(alpha);
stim = double(stimImg(:,:,1));

visible = visibleThroughFrame(design, nRows, nCols);
w  = (1 - alpha) .* visible;
sw = sum(w(:));

if sw < 1
    warning('makePinkNoiseTex:noBackground', ...
        'No visible background pixels.');
    % Fall back to stimulus only, fully opaque
    rgba = cat(3, stimImg, stimImg, stimImg, mask);
    tex  = Screen('MakeTexture', win, rgba);
    info = struct('meanLum', NaN, 'rms', NaN, 'nPixels', 0);
    return
end

noise = oneOverFNoise(nRows, nCols, exponent);
mu    = sum(w(:) .* noise(:)) / sw;
sd    = sqrt(sum(w(:) .* (noise(:) - mu).^2) / sw);
bg    = 255 * (meanLum + noiseSD * (noise - mu) / sd);

target = 255 * meanLum;
for iter = 1:20
    bgQ = min(max(round(bg), 0), 255);
    err = sum(w(:) .* bgQ(:)) / sw - target;
    if abs(err) < 0.005; break; end
    bg  = bg - err;
end

% Composite: stimulus where alpha=1, noise where alpha=0
out  = uint8(alpha .* stim + (1 - alpha) .* bgQ);
rgba = cat(3, out, out, out, 255*ones(nRows, nCols, 'uint8'));
tex = Screen('MakeTexture', win, rgba);

visMean      = sum(w(:) .* bgQ(:)) / sw;
info.meanLum = visMean / 255;
info.rms     = sqrt(sum(w(:) .* (bgQ(:) - visMean).^2) / sw) / 255;
info.nPixels = sw;
end

function visible = visibleThroughFrame(design, nRows, nCols)
% Logical nRows x nCols map of the stimulus pixels that are not covered by
% the frame texture, i.e. that fall into its transparent circular aperture.
dst = design.destinationRect;      % where the stimulus image is drawn
frm = design.frameRect;            % where the frame texture is drawn
texW = design.frameSizeInPixelsX;  % frame texture size (texture pixels)
texH = design.frameSizeInPixelsY;

% Screen coordinates of the centres of the stimulus pixels
x = dst(1) + ((1:nCols) - 0.5) .* (dst(3) - dst(1)) ./ nCols;
y = dst(2) + ((1:nRows) - 0.5) .* (dst(4) - dst(2)) ./ nRows;
[X, Y] = meshgrid(x, y);

% ... expressed in (1-based) frame-texture pixel coordinates
u = (X - frm(1)) ./ ((frm(3) - frm(1)) / texW) + 0.5;
v = (Y - frm(2)) ./ ((frm(4) - frm(2)) / texH) + 0.5;

% Transparent aperture exactly as in generate.createOApertureXFrame
radiusInner = design.apertureDiameterInPixels / 2 * (1 - design.frameThickness);
inCircle    = hypot(u - (texW + 1) / 2, v - (texH + 1) / 2) < radiusInner;
insideFrame = u >= 0.5 & u <= texW + 0.5 & v >= 0.5 & v <= texH + 0.5;

visible = inCircle | ~insideFrame;   % outside the frame nothing covers it
end


function noise = oneOverFNoise(nRows, nCols, exponent)
% Real-valued noise with an exact 1/f^exponent amplitude spectrum and random
% phases (any image size, odd or even).  Same idea as generate.img_one_over_f,
% but vectorised and without abs(): the random phases are Hermitian
% symmetric, so the inverse FFT is real and the histogram stays symmetric
% (no skew towards dark values, no clipping when centred on 0.5).
fy = [0:ceil(nRows/2) - 1, -floor(nRows/2):-1].' ./ nRows;   % cycles/pixel,
fx = [0:ceil(nCols/2) - 1, -floor(nCols/2):-1]   ./ nCols;   % FFT order
[FX, FY]  = meshgrid(fx, fy);
f         = hypot(FX, FY);
amplitude = zeros(nRows, nCols);
amplitude(f > 0) = f(f > 0) .^ (-exponent);                  % no DC

randomPhase = angle(fft2(randn(nRows, nCols)));
noise = real(ifft2(amplitude .* exp(1i .* randomPhase)));
end


function mask = estimateContentMask(stim)
% Fallback for stimulus PNGs without alpha channel: the background is the
% uniform grey that touches the image border; grey pixels enclosed by the
% stimulus are counted as stimulus.
persistent warned
if isempty(warned)
    warning('pinkNoiseBackground:noAlpha', ...
        ['Stimulus PNG has no alpha channel - the stimulus mask is estimated ', ...
        'from the grey background. Re-create the stimuli with ', ...
        'createFMRIStimuli.m (saves the mask as alpha channel).']);
    warned = true;
end
border  = [stim(1, :), stim(end, :), stim(:, 1).', stim(:, end).'];
bgValue = mode(border);
mask    = imfill(stim ~= bgValue, 'holes');
end


function value = getParam(s, name, default)
if s.hasField(name) && ~isempty(s.(name))
    value = s.(name);
else
    value = default;
end
end
