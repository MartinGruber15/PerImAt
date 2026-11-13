function [T, info] = localDotTargets(bases, dotA, dotAC, contrasts, rawMeans, lum, radiusPx, maskGain, names, weberFixed, lumExponent)
% generate.localDotTargets  Fixation-dot grey levels for design.fixDotContrastMode = 'local'
% [added 2026-11-05]
%
%   [T, info] = generate.localDotTargets(bases, dotA, dotAC, contrasts, rawMeans, lum, radiusPx, maskGain, names, weberFixed, lumExponent)
%
% In 'texture' mode every dot of a texture is blended towards the SAME grey
% level, 128 + (C - m) * c, so its step over the image is large on dark parts
% of the image and small on bright parts (e.g. on the cheek). 'local' keeps
% the between-texture rule of 'texture' (dot contrast proportional to the
% texture contrast c) but sets the grey level per dot so that its step over
% the LOCAL mean grey under the dot is a fixed fraction of that mean (Weber
% contrast):
%
%   wRef  = Aref * (C - m) * c / lum      Weber contrast the 'texture' dot has
%                                         on a background of lum (= 128)
%           or wRef = weberFixed          [added 2026-11-05] the same Weber
%                                         contrast in all four textures
%                                         (design.fixDotLocalWeber)
%   Lloc  = mean grey under the dot, weighted by its opacity profile A
%   Cloc  = RMS contrast (SD / mean) of the texture in a disc of radiusPx
%           around the dot centre (local clutter)
%   f     = 1 + maskGain * Cloc, divided by its mean over all textures and
%           positions (maskGain = 0: f = 1); only redistributes dot strength
%           towards busy spots, the mean level stays that of the luminance rule
%   step  = wRef * f * lum * (Lloc / lum)^k   peak step over the local mean
%           [changed 2026-11-05] k = lumExponent: 1 = Weber (step proportional to
%           the local mean: same step / local mean everywhere), 0 = the same
%           step in grey levels everywhere (wRef * f * lum, independent of how
%           bright the spot is), in between = partly. wRef is the Weber value
%           at mid-grey (Lloc = lum) for every k.
%   T     = Lloc + step / Aref             grey level the dot is blended to
%
% The dot is then drawn as before, out = (1 - A) .* image + A .* T, so its
% shape (opacity profile) and the partial covering of the texture under it are
% unchanged. T can exceed 255 (only the blended pixels are clipped; the
% caller counts clipped pixels).
%
% Grey levels are treated as proportional to luminance (gamma-corrected
% display, black level ignored).
%
% input:
%   bases      1 x K cell, contrast-adjusted texture images without dots (uint8)
%   dotA       1 x P cell, opacity map of the dot at each position (0-1)
%   dotAC      1 x P cell, premultiplied colour A*C (0-255)
%   contrasts  1 x K texture contrasts c
%   rawMeans   1 x K mean grey m of the raw (not contrast-adjusted) images
%   lum        target mean grey of the textures (design.defaultLuminance)
%   radiusPx   radius of the disc for Cloc (screen pixels)
%   maskGain   weight of the local clutter (0 = luminance only)
%   names      1 x K cell of texture names (for info)
%   weberFixed [] (default): wRef scales with the texture contrast c;
%              a number: wRef = weberFixed for every texture [added 2026-11-05]
%   lumExponent k (default 1), see above [added 2026-11-05]
% output:
%   T          K x P grey levels the dots are blended to
%   info       struct with Lloc, Cloc, weber (= step / Lloc), weberRef (wRef * f),
%              step, maskFactor, target (= T), Aref, radiusPx, maskGain,
%              lumExponent, names

if nargin < 11 || isempty(lumExponent); lumExponent = 1; end
if nargin < 10; weberFixed = []; end
if nargin < 9 || isempty(names); names = arrayfun(@(k) sprintf('tex%d', k), 1:numel(bases), 'UniformOutput', false); end
K = numel(bases); P = numel(dotA);
Aref = max(cellfun(@(a) max(a(:)), dotA));     % peak opacity of the dot (fixDotGaussPeakAlpha)
[nRows, nCols] = size(dotA{1});
[X, Y] = meshgrid(1:nCols, 1:nRows);
Lloc = zeros(K, P); Cloc = zeros(K, P); colour = zeros(1, P);
for p = 1:P
    A = double(dotA{p}); sA = sum(A(:));
    colour(p) = sum(double(dotAC{p}(:))) / sA;   % dot colour C (0-255)
    cx = sum(A(:) .* X(:)) / sA; cy = sum(A(:) .* Y(:)) / sA;
    disc = (X - cx).^2 + (Y - cy).^2 <= radiusPx^2;
    for k = 1:K
        b = double(bases{k}(:, :, 1));
        Lloc(k, p) = sum(A(:) .* b(:)) / sA;
        v = b(disc);
        Cloc(k, p) = std(v, 1) / mean(v);
    end
end
f = ones(K, P);
if maskGain > 0
    f = 1 + maskGain * Cloc;
    f = f / mean(f(:));
end
if isempty(weberFixed)
    wRef = Aref * bsxfun(@minus, colour, rawMeans(:)) .* repmat(contrasts(:), 1, P) / lum;   % K x P
    reference = 'texture contrast';
else
    wRef = repmat(weberFixed, K, P);                                                        % K x P
    reference = sprintf('fixed %.3f', weberFixed);
end
weberRef = wRef .* f;                                   % Weber value at mid-grey
step  = weberRef .* lum .* (Lloc / lum) .^ lumExponent;   % peak step (grey levels)
weber = step ./ Lloc;                                   % resulting step / local mean
T     = Lloc + step / Aref;
info = struct('names', {names}, 'Lloc', Lloc, 'Cloc', Cloc, 'maskFactor', f, 'weber', weber, ...
    'weberRef', weberRef, 'step', step, 'target', T, 'Aref', Aref, 'radiusPx', radiusPx, ...
    'maskGain', maskGain, 'lumExponent', lumExponent, 'reference', reference);
end
