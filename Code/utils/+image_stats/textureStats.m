function T = textureStats(design, ptb, doPrint)
% image_stats.textureStats  Low-level statistics of this subject's rivalry textures.
%
%   T = image_stats.textureStats(design, ptb)          % called by getVisualDesignSettings
%   T = image_stats.textureStats(design, ptb, true)    % also prints a short summary
%
% For both eye configurations, the house and the face texture that are
% shown together in a trial (design.images, i.e. after the contrast
% adjustment of generate.getContrastAdjustedImages with the subject's
% training contrasts) are compared with image_stats.compareStimulusStats,
% in the geometry in which they are shown (design.stimSizeInDegrees,
% circular aperture design.frameApertureInDegrees):
%   T.HouseLFaceR   house = design.images.houseL, face = design.images.faceR
%   T.FaceLHouseR   house = design.images.houseR, face = design.images.faceL
% each with .house, .face and .ratio (house/face) of
%   areaInAperture   fraction of the aperture covered by the stimulus
%   rmsForeground    RMS contrast (SD/mean) of the stimulus pixels
%   rmsAperture      RMS contrast of the whole aperture (stimulus + background)
%   meanForeground   mean grey level of the stimulus pixels
%   localRmsMean     mean local RMS contrast (Gaussian window) in the stimulus
%   bandRms          RMS contrast per spatial-frequency band (T.bandEdgesCpd)
%   orientationRms   RMS contrast horizontal / vertical / oblique
% The stimulus pixels are those that differ from the uniform background
% grey at the image border (enclosed grey pixels count as stimulus), as in
% generate.makePinkNoiseTex. The area does not depend on the contrasts; the
% contrast measures do. For the full analysis with plots, call
% image_stats.compareStimulusStats directly (e.g. with stimuli/house.png).
% Needs imfill (Image Processing Toolbox).

if nargin < 3; doPrint = false; end
pairs = {'HouseLFaceR', 'houseL', 'faceR'; 'FaceLHouseR', 'houseR', 'faceL'};
opts = struct('stimSizeDeg', design.stimSizeInDegrees, 'apertureDeg', design.frameApertureInDegrees, ...
    'screenPixPerDeg', ptb.PixPerDegWidth, 'showPlots', false, 'quiet', true);
measures = {'areaInAperture', 'rmsForeground', 'rmsAperture', 'meanForeground', 'bandRms', 'orientationRms'};
for p = 1:size(pairs, 1)
    S = image_stats.compareStimulusStats(toGrayMask(design.images.(pairs{p, 2})), ...
        toGrayMask(design.images.(pairs{p, 3})), opts);
    for k = {'house', 'face'}
        for m = 1:numel(measures)
            T.(pairs{p, 1}).(k{1}).(measures{m}) = S.(k{1}).(measures{m});
        end
        T.(pairs{p, 1}).(k{1}).localRmsMean = S.(k{1}).localRms.mean;
    end
    T.(pairs{p, 1}).ratio = S.ratio;
end
T.bandEdgesCpd = S.house.bandEdgesCpd;
T.orientationNames = S.house.orientationNames;
T.opts = opts;

if doPrint
    fprintf('\nTexture statistics (house / face shown together; image_stats.textureStats):\n');
    for p = 1:size(pairs, 1)
        t = T.(pairs{p, 1});
        fprintf(['  %s: aperture covered %.2f / %.2f (x%.2f) | RMS stimulus %.3f / %.3f (x%.2f) | ' ...
            'RMS aperture %.3f / %.3f (x%.2f)\n'], pairs{p, 1}, ...
            t.house.areaInAperture, t.face.areaInAperture, t.ratio.areaInAperture, ...
            t.house.rmsForeground, t.face.rmsForeground, t.ratio.rmsForeground, ...
            t.house.rmsAperture, t.face.rmsAperture, t.ratio.rmsAperture);
    end
end
end


function s = toGrayMask(img)
img = double(img);
if size(img, 3) >= 3
    g = 0.2989 * img(:, :, 1) + 0.5870 * img(:, :, 2) + 0.1140 * img(:, :, 3);
else
    g = img(:, :, 1);
end
gr = round(g);
border = [gr(1, :), gr(end, :), gr(:, 1)', gr(:, end)'];
s.gray = g;
s.mask = imfill(gr ~= mode(border), 'holes');
end
