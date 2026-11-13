function S = compareStimulusStats(houseIn, faceIn, opts)
% image_stats.compareStimulusStats  Low-level comparison of the house and face stimulus.
%
%   S = image_stats.compareStimulusStats('house.png', 'face.png')
%   S = image_stats.compareStimulusStats(houseIn, faceIn, opts)
%
% Shows which low-level differences remain when house and face are matched
% in mean luminance and RMS contrast of the foreground
% (stimulusPreparation/createFMRIStimuli.m):
%   1. foreground area: inside the circular aperture, fraction of the
%      aperture covered, part hidden by the frame
%   2. mean luminance and RMS contrast (SD/mean; note that
%      createFMRIStimuli uses SD/255) over (a) the foreground, (b) the
%      foreground inside the aperture, (c) the whole aperture (foreground +
%      grey background), and the proportion of clipped pixels (0 or 255)
%   3. contrast per spatial-frequency band (octaves, cycles/deg) inside the
%      aperture: the RMS contrast carried by each band (the squares of the
%      bands add up to the squared RMS contrast of the aperture, Parseval)
%   4. contrast per orientation (structure that is horizontal / vertical /
%      oblique)
%   5. local RMS contrast (Gaussian window) in the foreground: mean,
%      median, 95th percentile - high values = contrast concentrated in a few
%      features (e.g. eyes, mouth)
%
% Inputs: file names, or structs with fields .gray (0-255) and .mask
% (logical foreground). Images are analysed in the geometry in which they are
% shown: the image width spans opts.stimSizeDeg degrees (destinationRect in
% getVisualDesignSettings), and only the circular aperture of
% opts.apertureDeg is visible (frame of design.frameTexture). Use the
% images in the format the experiment loads (stimuli/house.png etc.).
%
% opts (all optional):
%   stimSizeDeg     3     design.stimSizeInDegrees
%   apertureDeg     2.6   design.stimSizeInDegrees * frameSizeFactor * frameApertureFactor
%   screenPixPerDeg []    if given, bands above the screen Nyquist (pixPerDeg/2) are dropped
%   bandEdgesCpd    [0.5 1 2 4 8 16 32 64]
%   localSigmaDeg   0.15  SD of the Gaussian window for local contrast
%   bgGray          []    background grey of matched images (default: from the border)
%   labels          {'house', 'face'}
%   showPlots       true
%   quiet           false  (true: no table)
%
% S.house / S.face: all measures; S.ratio: house/face ratios; printed as a table.
% Base MATLAB + Image Processing Toolbox (imfill, via foregroundMask).

if nargin < 3; opts = struct(); end
opts = setDefault(opts, 'stimSizeDeg', 3);
opts = setDefault(opts, 'apertureDeg', 3 * 1.3 * 2/3);
opts = setDefault(opts, 'screenPixPerDeg', []);
opts = setDefault(opts, 'bandEdgesCpd', [0.5 1 2 4 8 16 32 64]);
opts = setDefault(opts, 'localSigmaDeg', 0.15);
opts = setDefault(opts, 'bgGray', []);
opts = setDefault(opts, 'labels', {'house', 'face'});
opts = setDefault(opts, 'showPlots', true);
opts = setDefault(opts, 'quiet', false);

ins = {houseIn, faceIn};
for k = 1:2
    if ischar(ins{k}) || isstring(ins{k})
        [g, m, src] = image_stats.foregroundMask(char(ins{k}), opts.bgGray);
        name = char(ins{k});
    else
        g = double(ins{k}.gray); m = logical(ins{k}.mask); src = 'given'; name = '(matrix)';
    end
    r = analyse(g, m, opts);
    r.file = name;
    r.maskSource = src;
    if k == 1; R = r; else; R(2) = r; end
end
S.(opts.labels{1}) = R(1);
S.(opts.labels{2}) = R(2);
S.opts = opts;
S.ratio.areaInAperture   = R(1).areaInAperture / R(2).areaInAperture;
S.ratio.rmsForeground    = R(1).rmsForeground / R(2).rmsForeground;
S.ratio.rmsAperture      = R(1).rmsAperture / R(2).rmsAperture;
S.ratio.bandRms          = R(1).bandRms ./ R(2).bandRms;
S.ratio.orientationRms   = R(1).orientationRms ./ R(2).orientationRms;
S.ratio.localRmsMean     = R(1).localRms.mean / R(2).localRms.mean;

if ~opts.quiet
    printTable(S, R, opts);
end
if opts.showPlots
    plotStats(R, opts);
end
end


%% =========================================================================
function r = analyse(g, m, opts)
[nr, nc] = size(g);
pixPerDeg = nc / opts.stimSizeDeg;
if nr ~= nc && ~opts.quiet
    warning('compareStimulusStats:notSquare', ...
        'Image is %dx%d; the experiment draws it into a square rect. Degrees are based on the width.', nr, nc);
end
% aperture (circle centred on the image) with a small raised-cosine edge
[X, Y] = meshgrid(((1:nc) - (nc + 1) / 2) / pixPerDeg, ((1:nr) - (nr + 1) / 2) / pixPerDeg);
radius = hypot(X, Y);
R0 = opts.apertureDeg / 2;
ap = radius <= R0;
edge = 0.05;                                            % deg
win = min(max((R0 - radius) / edge, 0), 1);
win = 0.5 - 0.5 * cos(pi * win);

r.sizePx = [nr nc];
r.pixPerDeg = pixPerDeg;
r.areaForegroundDeg2 = nnz(m) / pixPerDeg^2;
r.areaInAperture     = nnz(m & ap) / nnz(ap);           % fraction of the aperture covered
r.hiddenByFrame      = nnz(m & ~ap) / max(nnz(m), 1);   % fraction of the foreground outside the aperture

fg = g(m); fgA = g(m & ap); apAll = g(ap);
r.meanForeground = mean(fg);
r.rmsForeground  = std(fg) / mean(fg);                  % SD/mean
r.meanFgInAperture = mean(fgA);
r.rmsFgInAperture  = std(fgA) / mean(fgA);
r.meanAperture   = mean(apAll);
r.rmsAperture    = std(apAll) / mean(apAll);
r.clipped        = mean(fg <= 0 | fg >= 255);

% ---- spatial frequency / orientation (Weber contrast re. background 128) ----
c = (g - 128) / 128 .* win;
c = c - sum(c(:)) / sum(win(:)) .* win;                 % remove the mean inside the window
F = fft2(c);
P = abs(F).^2 / numel(c) / sum(win(:).^2);              % so that sum(P) = mean squared contrast in the window
P(1, 1) = 0;
fy = [0:ceil(nr/2) - 1, -floor(nr/2):-1]' / nr * pixPerDeg;   % cycles/deg
fx = [0:ceil(nc/2) - 1, -floor(nc/2):-1]  / nc * pixPerDeg;
[FX, FY] = meshgrid(fx, fy);
f = hypot(FX, FY);
nyq = min(nr, nc) / 2 / opts.stimSizeDeg;
if ~isempty(opts.screenPixPerDeg); nyq = min(nyq, opts.screenPixPerDeg / 2); end
edges = opts.bandEdgesCpd(opts.bandEdgesCpd <= nyq * 1.0001);
if numel(edges) < 2; edges = [opts.bandEdgesCpd(1) nyq]; end
r.bandEdgesCpd = edges;
r.bandRms = zeros(1, numel(edges) - 1);
for b = 1:numel(edges) - 1
    sel = f >= edges(b) & f < edges(b + 1);
    r.bandRms(b) = sqrt(sum(P(sel)));
end
% orientation of the image STRUCTURE (frequency vector is perpendicular)
theta = mod(atan2(FY, FX) * 180 / pi, 180);             % frequency direction
structOri = mod(theta + 90, 180);                        % 0 = horizontal structure
valid = f >= edges(1) & f < edges(end);
d0 = min(structOri, 180 - structOri);                    % distance to horizontal
d90 = abs(structOri - 90);                               % distance to vertical
r.orientationNames = {'horizontal', 'vertical', 'oblique'};
r.orientationRms = [sqrt(sum(P(valid & d0 < 22.5))), sqrt(sum(P(valid & d90 < 22.5))), ...
    sqrt(sum(P(valid & d0 >= 22.5 & d90 >= 22.5)))];
% radial amplitude spectrum for plotting
fb = logspace(log10(max(0.25, fx(2))), log10(nyq), 30);
r.radialF = sqrt(fb(1:end-1) .* fb(2:end));
r.radialAmp = nan(size(r.radialF));
for b = 1:numel(fb) - 1
    sel = f >= fb(b) & f < fb(b + 1);
    if any(sel(:)); r.radialAmp(b) = sqrt(mean(P(sel))); end
end

% ---- local RMS contrast ----
sigma = opts.localSigmaDeg * pixPerDeg;
h = ceil(3 * sigma);
k1 = exp(-0.5 * ((-h:h) / sigma).^2); k1 = k1 / sum(k1);
cl = (g - 128) / 128;
m1 = conv2(k1, k1, cl, 'same');
m2 = conv2(k1, k1, cl.^2, 'same');
loc = sqrt(max(m2 - m1.^2, 0));
vals = loc(m & ap);
r.localRmsMap = loc;
r.localRms.mean = mean(vals);
r.localRms.median = median(vals);
srt = sort(vals);
r.localRms.p95 = srt(max(1, ceil(0.95 * numel(srt))));
r.gray = g; r.mask = m; r.aperture = ap;
end


function printTable(S, R, opts)
L = opts.labels;
fprintf('\n=================== %s vs %s ===================\n', L{1}, L{2});
fprintf('mask from: %s: %s | %s: %s\n', L{1}, R(1).maskSource, L{2}, R(2).maskSource);
fprintf('%-38s %10s %10s %10s\n', '', L{1}, L{2}, 'ratio');
row = @(name, a, b) fprintf('%-38s %10.4f %10.4f %10.3f\n', name, a, b, a / b);
row('foreground area (deg^2)', R(1).areaForegroundDeg2, R(2).areaForegroundDeg2);
row('fraction of aperture covered', R(1).areaInAperture, R(2).areaInAperture);
row('fraction of foreground hidden by frame', R(1).hiddenByFrame, R(2).hiddenByFrame);
row('mean luminance, foreground', R(1).meanForeground, R(2).meanForeground);
row('RMS contrast, foreground (matched)', R(1).rmsForeground, R(2).rmsForeground);
row('RMS contrast, foreground in aperture', R(1).rmsFgInAperture, R(2).rmsFgInAperture);
row('RMS contrast, whole aperture', R(1).rmsAperture, R(2).rmsAperture);
row('clipped foreground pixels', R(1).clipped, R(2).clipped);
row('local RMS contrast, mean', R(1).localRms.mean, R(2).localRms.mean);
row('local RMS contrast, 95th percentile', R(1).localRms.p95, R(2).localRms.p95);
fprintf('RMS contrast per spatial-frequency band (inside the aperture):\n');
e = R(1).bandEdgesCpd;
for b = 1:numel(e) - 1
    row(sprintf('  %5.2f - %5.2f c/deg', e(b), e(b + 1)), R(1).bandRms(b), R(2).bandRms(b));
end
fprintf('RMS contrast per orientation of the image structure (%.2f - %.1f c/deg):\n', e(1), e(end));
for o = 1:3
    row(['  ' R(1).orientationNames{o}], R(1).orientationRms(o), R(2).orientationRms(o));
end
fprintf('(ratio > 1: more in the %s. For scale: in the QUEST+ calibration of sub-01 the house needed\n about 2x the face contrast, i.e. log2 ratio = 1)\n', L{1});
fprintf('==========================================================\n');
end


function plotStats(R, opts)
L = opts.labels; col = {[0.85 0.33 0.10], [0.00 0.45 0.74]};
figure('Name', 'Stimulus statistics', 'Color', 'w', 'Position', [80 80 1400 700]);
for k = 1:2
    subplot(2, 4, k);
    imagesc(R(k).gray, [0 255]); colormap(gca, gray); axis image off; hold on;
    contour(double(R(k).mask), [0.5 0.5], 'Color', col{k});
    contour(double(R(k).aperture), [0.5 0.5], 'g');
    title(sprintf('%s (green: aperture)', L{k}));
    subplot(2, 4, 4 + k);
    imagesc(R(k).localRmsMap .* R(k).aperture); axis image off; colorbar;
    title(sprintf('%s: local RMS contrast', L{k}));
end
subplot(2, 4, 3); hold on;
for k = 1:2; loglog(R(k).radialF, R(k).radialAmp, '-o', 'Color', col{k}, 'MarkerSize', 3); end
set(gca, 'XScale', 'log', 'YScale', 'log'); xlabel('cycles/deg'); ylabel('amplitude (contrast)');
legend(L, 'Location', 'southwest'); title('radial amplitude spectrum'); box on;
subplot(2, 4, 4);
e = R(1).bandEdgesCpd; labels = arrayfun(@(b) sprintf('%g-%g', e(b), e(b + 1)), 1:numel(e) - 1, 'UniformOutput', false);
hb = bar([R(1).bandRms; R(2).bandRms]'); hb(1).FaceColor = col{1}; hb(2).FaceColor = col{2};
set(gca, 'XTickLabel', labels); xtickangle(45);
xlabel('cycles/deg'); ylabel('RMS contrast in band'); legend(L); title('contrast per SF band');
subplot(2, 4, 7);
hb = bar([R(1).orientationRms; R(2).orientationRms]'); hb(1).FaceColor = col{1}; hb(2).FaceColor = col{2};
set(gca, 'XTickLabel', R(1).orientationNames);
ylabel('RMS contrast'); legend(L); title('contrast per orientation');
subplot(2, 4, 8);
bar(log2([R(1).bandRms ./ R(2).bandRms])); set(gca, 'XTickLabel', labels); xtickangle(45);
ylabel(sprintf('log2(%s / %s)', L{1}, L{2})); title('band ratio'); yline(0, 'k');
end


function s = setDefault(s, name, value)
if ~isfield(s, name) || (isempty(s.(name)) && ~isempty(value))
    s.(name) = value;
end
end
