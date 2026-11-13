function texture = createGaussianFixDotTexture(ptb, sizePx, sigmaPx, color, peakAlpha, supersample)
% generate.createGaussianFixDotTexture  Soft no-report fixation dot without frame.
%
%   texture = generate.createGaussianFixDotTexture(ptb, sizePx, sigmaPx, color, peakAlpha)
%
% RGBA texture: uniform colour, alpha = peakAlpha * Gaussian(sigmaPx), going
% smoothly to 0 at the texture border. Drawn with alpha blending
% (getPTBSettings: GL_SRC_ALPHA / GL_ONE_MINUS_SRC_ALPHA) it blends into the
% stimulus instead of covering it with a uniform square:
%   pixel = (1 - a) * stimulus + a * color,  a = peakAlpha * exp(-r^2 / (2 sigma^2)) * dotTransparency
% Used in place of generate.createFixDotTexture when design.fixDotStyle =
% 'gaussian' (getVisualDesignSettings). It is drawn into
% design.fixDotTextureRects (sizePx x sizePx on screen), exactly where the old
% dot + frame was drawn, by generate.getContrastAdjustedImages (before the
% contrast adjustment, so the dot's contrast scales with the stimulus
% contrast).
%
% sizePx       on-screen size of the texture rect (should be >= 6 * sigmaPx)
% sigmaPx      SD of the Gaussian in screen pixels
% color        RGB in 0-1 (e.g. [0.85 0.85 0.85] light, [0.15 0.15 0.15] dark)
% peakAlpha    opacity at the centre (0-1)
% supersample  texture resolution relative to the screen (default 8), so
%              that the small Gaussian is smooth after PTB's bilinear scaling

if nargin < 6 || isempty(supersample); supersample = 8; end
n = max(3, round(sizePx * supersample));
c = (n + 1) / 2;
[X, Y] = meshgrid(1:n, 1:n);
r = hypot(X - c, Y - c) / supersample;           % distance in screen pixels
g = exp(-r.^2 / (2 * sigmaPx^2));
edgeValue = exp(-(sizePx / 2)^2 / (2 * sigmaPx^2));
g = max(g - edgeValue, 0) / (1 - edgeValue);     % exactly 0 at the inscribed circle, no visible edge
alpha = uint8(round(255 * peakAlpha * g));
rgb = repmat(reshape(uint8(round(255 * color(:)')), 1, 1, 3), n, n);
texture = Screen('MakeTexture', ptb.window, cat(3, rgb, alpha));
end
