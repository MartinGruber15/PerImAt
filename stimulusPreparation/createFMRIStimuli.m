function createFMRIStimuli(varargin)
% createFMRIStimuli  Generate fMRI stimuli from house and face source images.
%
% Based on getStimuliSettings.m but WITHOUT sinusoidal gratings.
% Matches
% mean luminance and RMS contrast so that all stimuli are equated on these
% low-level properties.
%
% -------------------------------------------------------------------------
% STIMULUS CATEGORIES  (10 total, each with <numAngles> PNG files)
% -------------------------------------------------------------------------
%   house          – house image, orientation-filtered
%   face           – face image, orientation-filtered
%   plaid          – 50/50 equal-weight blend of house + face (re-normalised)
%   catch_hf       – left half = house, right half = face, cosine-fade join
%   catch_fh       – left half = face, right half = house, cosine-fade join
%   house_low      – house at low contrast
%   face_low       – face at low contrast
%   plaid_low      – plaid at low contrast
%   catch_hf_low   – catch (house|face) at low contrast
%   catch_fh_low   – catch (face|house) at low contrast
%
% -------------------------------------------------------------------------
% REQUIREMENTS
% -------------------------------------------------------------------------
%   • house_raw.png and face_raw.png in the CURRENT directory.
%     Both images must use solid magenta ([255 0 255]) as background mask.
%   • MATLAB Image Processing Toolbox  (imresize, imhistmatch, rgb2gray)
%   • No Psychtoolbox needed for stimulus generation.
%
% -------------------------------------------------------------------------
% USAGE
% -------------------------------------------------------------------------
%   createFMRIStimuli()
%   createFMRIStimuli('outputDir','stimuli_fmri','targetRMS',0.15)
%   createFMRIStimuli('numAngles',1)   % one static image per category
%
% -------------------------------------------------------------------------
% PARAMETERS  (name-value pairs)
% -------------------------------------------------------------------------
%   outputDir   Folder where stimuli are saved           (default: 'stimuli')
%   targetLum   Target mean luminance, 0–255            (default: 128)
%   targetRMS   Normal RMS contrast, fraction of 255   (default: 0.20)
%   lowRMS      Low-contrast RMS, fraction of 255      (default: 0.05)
%   setUp       Lab/scanner setup name, one of:         (default: 'CIN-experimentroom')
%               'MPI'              – fMRI scanner at Max Planck Institute
%               'CIN-personal'     – personal monitor at CIN
%               'CIN-experimentroom' – experiment room at CIN
%   screenXpixels  Width of the drawing buffer in pixels, i.e. the value
%               Screen('WindowSize') returns in getPTBSettings (ptb.screenXpixels).
%               In side-by-side stereo (stereomode 4) this is the width of ONE
%               eye's buffer. Default (NaN) = value of the setup:
%                 CIN-experimentroom 1280 (2560 px monitor, side-by-side)
%                 CIN-personal        960 (1920 px window, side-by-side)
%                 MPI                1920 (sequential stereo)
%   screenYpixels  Height of the drawing buffer (ptb.screenYpixels). Default
%               (NaN) = 1440 / 1200 / 1080 for the setups above.
%   stimSizeInDegrees  Stimulus size in visual degrees (default: 3)
%               Must match design.stimSizeInDegrees in getVisualDesignSettings.
%               The images are written at exactly the on-screen size
%               (design.stimSizeInPixelsX x design.stimSizeInPixelsY, e.g.
%               125 x 124 px in the CIN experiment room), so Psychtoolbox
%               does not have to resample them.
%   stereomodeSequential  true  → stereomode 1 (sequential, shutter glasses)
%                         false → stereomode 4 (side-by-side)  (default)
%               Matches stereomodeSequential arg of getPTBSettings
%               (PixPerDeg formula identical to getPTBSettings).
%   numAngles   Number of orientations of the cosine patch mask used by
%               catch_ov / catch_half (default: 24 -> 0:15:345 deg).
%               Angles = (0:numAngles-1) * 360/numAngles. Note: the mask is a
%               cosine around the image centre, so theta and theta+180 give
%               the SAME image (0:15:345 -> 12 distinct patterns).
%               house/face/plaid/catch_hf/catch_fh do not depend on the angle
%               (identical copies, kept for the naming scheme).
%   fadeWidthDeg  Fade width in visual degrees (default: 0.24 = 10 px in the CIN
%               experiment room): half-width of the cosine join in catch_hf/catch_fh;
%               Gaussian SD of the overlap edge in catch_ov and catch_ov5050 (in
%               catch_ov5050 the fade lies only outside the overlap). Not used by
%               catch_half. Converted to px with the set-up's PixPerDeg, so the fade
%               is the same in degrees on every set-up.
%   fadeWidth   Fade width in px; overrides fadeWidthDeg if given (default: NaN).
%   matchRegion [added 2026-11-10] region on which mean luminance and RMS
%               contrast are matched (default: 'visible'):
%                 'visible' – only the content VISIBLE through the frame
%                             aperture in the experiment: a circle of radius
%                             apertureDiameter/2 * (1 - frameThickness) around
%                             the image centre (generate.createOApertureXFrame /
%                             generate.visibleMask), in this set-up's pixels.
%                             Content outside it (hidden behind the frame) is set
%                             to the background grey, so all statistics, plaids,
%                             catch images and weight maps refer to what is seen.
%                 'content' – all content of the source image (before 2026-11-10)
%   frameSizeFactor, frameApertureFactor, frameThickness  [added 2026-11-10]
%               frame geometry, must match getVisualDesignSettings
%               (defaults 1.3, 2/3, 0.02): aperture diameter in px =
%               round(PixPerDeg * stimSizeInDegrees * frameSizeFactor * frameApertureFactor).
%               The experiment uses the same aperture as centre of the contrast
%               scaling (design.contrastReference = 'visible'), so the visible
%               part of every texture keeps mean targetLum at every contrast.
%
% -------------------------------------------------------------------------
% OUTPUT FILES
% -------------------------------------------------------------------------
%   <outputDir>/<category>/<category><angle>.png
%   RGB PNG (R=G=B), background = targetLum. No alpha channel: the
%   experiment captures every image from an offscreen window (RGB only) and
%   makePinkNoiseTex estimates the content mask from the grey background.
%
%   catch_ov5050   – [added 2026-11-04] like catch_ov, but house and face each
%                    make up exactly 50 % of the whole catch image (see
%                    makeCatchOv5050); catch_ov5050_low at low contrast.
%
%   Catch categories (catch_hf, catch_fh, catch_ov, catch_ov5050, catch_half) additionally:
%   <outputDir>/<category>/<category><angle>_weights.png
%   (catch_ov5050: catch_ov5050_<angle>.png / catch_ov5050_<angle>_weights.png)
%   R = weight of the house image, G = weight of the face image (0-255 = 0-1)
%   in the blend. generate.getContrastAdjustedImages uses this map to build
%   the catch images from the subject's contrast-calibrated house and face
%   textures (rename it together with the catch image, e.g.
%   catch_houseface.png + catch_houseface_weights.png).
%
% -------------------------------------------------------------------------
% NOTES ON RMS CONTRAST DEFINITION
% -------------------------------------------------------------------------
%   RMS contrast here is defined as std(content_pixels) / 255.
%   targetRMS = 0.20  →  std ≈ 51 DN (out of 255)
%   lowRMS    = 0.05  →  std ≈ 13 DN
%
% -------------------------------------------------------------------------
% COMPATIBILITY WITH readInStimuli
% -------------------------------------------------------------------------
%   Set stimuli.image.RMS = [1; 1] and stimuli.image.luminance = [128; 128]
%   (or your targetLum) in getStimuliSettings when loading these stimuli,
%   so readInStimuli does not re-scale the already-matched images.

%% ===== Parse inputs =====================================================

p = inputParser;
addParameter(p, 'outputDir',           'stimuli',  @(x) ischar(x)||isstring(x));
addParameter(p, 'targetLum',           128,        @(x) isnumeric(x) && isscalar(x) && x>=0  && x<=255);
addParameter(p, 'targetRMS',           0.1,       @(x) isnumeric(x) && isscalar(x) && x>0); % actual RMS is *2
addParameter(p, 'lowRMS',             0.025,       @(x) isnumeric(x) && isscalar(x) && x>0); % actual RMS is *2
addParameter(p, 'numAngles',           24,         @(x) isnumeric(x) && isscalar(x) && x>=1 && x<=360);
% [changed 2026-11-04] The fade is set in visual degrees (fadeWidthDeg) and
% converted to pixels for the set-up, so it looks the same on every set-up
% (the images have a different number of pixels per degree, e.g. 41.7 px/deg in
% the CIN experiment room, ~75 px/deg at the MPI). 0.24 deg = 10 px in the CIN
% experiment room (was a fixed 20 px). fadeWidth (px) still overrides it.
addParameter(p, 'fadeWidthDeg',        0.24,       @(x) isnumeric(x) && isscalar(x) && x>=0);
addParameter(p, 'fadeWidth',           NaN,        @(x) isnumeric(x) && isscalar(x) && (isnan(x) || x>=0));   % px; NaN = from fadeWidthDeg
addParameter(p, 'patchFreq',           3,          @(x) isnumeric(x) && isscalar(x) && x>0);
% patchFreq: cycles per image for the sinusoidal modulation mask used in
% catch_ov and catch_half.  3 = ~3 full patches visible across the diagonal.
% Setup / display geometry (mirrors getPTBSettings + getVisualDesignSettings)
addParameter(p, 'setUp',               'CIN-experimentroom', @(x) ischar(x)||isstring(x));
addParameter(p, 'screenXpixels',       NaN,        @(x) isnumeric(x) && isscalar(x));   % NaN = setup default
addParameter(p, 'screenYpixels',       NaN,        @(x) isnumeric(x) && isscalar(x));   % NaN = setup default
addParameter(p, 'stimSizeInDegrees',   3,          @(x) isnumeric(x) && isscalar(x) && x>0);
addParameter(p, 'matchRegion',         'visible',  @(x) any(strcmpi(char(x), {'visible','content'})));   % [added 2026-11-10]
addParameter(p, 'frameSizeFactor',     1.3,        @(x) isnumeric(x) && isscalar(x) && x>0);   % = design.frameSizeFactor
addParameter(p, 'frameApertureFactor', 2/3,        @(x) isnumeric(x) && isscalar(x) && x>0);   % = design.frameApertureFactor
addParameter(p, 'frameThickness',      0.02,       @(x) isnumeric(x) && isscalar(x) && x>=0);  % = design.frameThickness
addParameter(p, 'stereomodeSequential', false,     @(x) islogical(x)||(isnumeric(x)&&isscalar(x)));
parse(p, varargin{:});
o = p.Results;
o.outputDir = char(o.outputDir);
o.setUp     = char(o.setUp);



%% ===== Create output directories ========================================

categories = {'house','face','plaid','catch_hf','catch_fh', ...
               'house_low','face_low','plaid_low','catch_hf_low','catch_fh_low', ...
               'plaid_full','plaid_full_low', ...   % full-mask plaid (union, not overlap)
               'catch_ov','catch_ov_low', ...       % patch catch: non-overlap shows full stim
               'catch_ov5050','catch_ov5050_low', ... % [added 2026-11-04] as catch_ov, house:face = 50:50 overall
               'catch_half','catch_half_low'};      % patch catch: 50/50 globally, grey for non-overlap

%% ===== Resolve display geometry (mirrors getPTBSettings) =================
% Physical constants per setup — must match getPTBSettings.m exactly.
% screenX/Ypixels = size of the drawing buffer as returned by
% Screen('WindowSize') (ptb.screenXpixels / ptb.screenYpixels); in
% side-by-side stereo that is ONE eye's half (sub-01: 1280 x 1440).
switch o.setUp
    case 'CIN-personal'
        distToMonitor = 570;   widthMonitor = 180;   heightMonitor = 120;
        defX = 960;   defY = 1200;   % window [0 0 1920 1200], side-by-side
    case 'CIN-experimentroom'
        distToMonitor = 560;   widthMonitor = 600;   heightMonitor = 340;
        defX = 1280;  defY = 1440;   % 2560 x 1440 monitor, side-by-side
    case 'MPI'
        distToMonitor = 1050;  widthMonitor = 470;   heightMonitor = 265;
        defX = 1920;  defY = 1080;
    otherwise
        error('createFMRIStimuli:unknownSetUp', ...
              'Unknown setUp ''%s''. Use CIN-personal, CIN-experimentroom, or MPI.', o.setUp);
end
screenXpixels = o.screenXpixels; if isnan(screenXpixels); screenXpixels = defX; end
screenYpixels = o.screenYpixels; if isnan(screenYpixels); screenYpixels = defY; end

% Pixel size and degrees per pixel (same formulae as getPTBSettings)
pixWidthMm      = widthMonitor  / screenXpixels;
pixHeightMm     = heightMonitor / screenYpixels;
DegPerPixWidth  = 2 * atand(0.5 * pixWidthMm  / distToMonitor);
DegPerPixHeight = 2 * atand(0.5 * pixHeightMm / distToMonitor);
if o.stereomodeSequential
    stereomode  = 1;
    PixPerDeg   = 1 / DegPerPixWidth;          % full-screen use
else
    stereomode  = 4;
    PixPerDeg   = (1 / DegPerPixWidth) * 2;    % as getPTBSettings (stereomode 4)
end
PixPerDegHeight = 1 / DegPerPixHeight;

% Stimulus size in pixels — = design.stimSizeInPixelsX / stimSizeInPixelsY
szX = round(PixPerDeg       * o.stimSizeInDegrees);
szY = round(PixPerDegHeight * o.stimSizeInDegrees);
sz  = szX;   % reference size for the patch frequency (cycles per image width)

% Fade width in pixels for this set-up [changed 2026-11-04]
if isnan(o.fadeWidth)
    o.fadeWidth = o.fadeWidthDeg * PixPerDeg;   % constant in degrees across set-ups
    fadeSource  = 'from fadeWidthDeg';
else
    fadeSource  = 'given in px';
end

fprintf('\n=== createFMRIStimuli ===\n');
fprintf('setUp       : %s  (stereomode %d)\n', o.setUp, stereomode);
fprintf('Buffer res  : %d × %d px (per eye in side-by-side stereo)\n', screenXpixels, screenYpixels);
fprintf('Monitor     : %d × %d mm  @ %d mm distance\n', widthMonitor, heightMonitor, distToMonitor);
fprintf('PixPerDeg   : %.2f (x) / %.2f (y) px/°\n', PixPerDeg, PixPerDegHeight);
fprintf('Stim size   : %.1f°  →  %d × %d px (width × height)\n', o.stimSizeInDegrees, szX, szY);
fprintf('Output dir  : %s\n', o.outputDir);
fprintf('targetLum   : %.0f DN\n', o.targetLum);
fprintf('targetRMS   : %.4f  (std ≈ %.1f DN)\n', o.targetRMS, o.targetRMS*255);
fprintf('lowRMS      : %.4f  (std ≈ %.1f DN)\n', o.lowRMS, o.lowRMS*255);
fprintf('numAngles   : %d (step %.4g°)\n', o.numAngles, 360/o.numAngles);
fprintf('fadeWidth   : %.1f px = %.3f deg (%s)\n', o.fadeWidth, o.fadeWidth / PixPerDeg, fadeSource);
fprintf('orient.filter: none (raw grayscale)\n');
fprintf('\n');

for c = 1:numel(categories)
    d = fullfile(o.outputDir, categories{c});
    if ~exist(d, 'dir')
        mkdir(d);
    end
end

%% ===== Load source images ===============================================

fprintf('--- Loading source images ---\n');
if ~exist('house_1702x1669_plaque.png','file') || ~exist('face_noshirt.png','file') % Subtly shaded wooden house on magenta.png
    error('createFMRIStimuli:missingFiles', ...
          'house_1702x1669_plaque.png and face_noshirt.png must be in the current directory.\n');
end

houseRaw = imread('house_1702x1669_plaque.png');
faceRaw  = imread('face_noshirt.png'); % face_noshirt is OG

% Keep only the first 3 channels (drop pre-existing alpha if any)
houseRaw = houseRaw(:,:,1:3);
faceRaw  = faceRaw(:,:,1:3);

% --- Magenta background mask: logical 1 = image content ---
magenta    = uint8([255, 0, 255]);
houseMask  = ~(houseRaw(:,:,1)==magenta(1) & houseRaw(:,:,2)==magenta(2) & houseRaw(:,:,3)==magenta(3));
faceMask   = ~(faceRaw(:,:,1)==magenta(1)  & faceRaw(:,:,2)==magenta(2)  & faceRaw(:,:,3)==magenta(3));

% --- Convert to grayscale ---
houseGray  = rgb2gray(houseRaw);
faceGray   = rgb2gray(faceRaw);

% --- Match spatial bandwidth across source images ---
% Source images may have very different native resolutions (e.g., house 446 px,
% face 1702 px).  Without correction the higher-res image retains finer spatial
% detail at display size — the same confound the original orientation filter
% implicitly removed by bandpass-filtering both through the same FFT window.
%
% Fix: pre-downsample the higher-resolution image so its maximum dimension
% equals the lower-resolution image's maximum dimension.  After this step,
% both images are upscaled by the SAME factor to [sz, sz], giving identical
% spatial-frequency ceilings at display size.
%
% Example: house 446 px, face 1702 px → pre-downsample face to 446 px max dim
%   → both then upscale ×(sz/446) to display size → equal bandwidth.
maxDimHouse = max(size(houseGray,1), size(houseGray,2));
maxDimFace  = max(size(faceGray,1),  size(faceGray,2));

if maxDimFace > maxDimHouse
    % face has higher native resolution — pre-downsample to house scale
    scaleFace = maxDimHouse / maxDimFace;
    faceGray  = imresize(faceGray,          scaleFace);
    faceMask  = imresize(double(faceMask),  scaleFace) > 0.5;
elseif maxDimHouse > maxDimFace
    % house has higher native resolution — pre-downsample to face scale
    scaleHouse = maxDimFace / maxDimHouse;
    houseGray  = imresize(houseGray,         scaleHouse);
    houseMask  = imresize(double(houseMask), scaleHouse) > 0.5;
end
% Both images now share the same max dimension → same upscale factor to sz.

% --- Resize both images to the on-screen stimulus size (rows x cols) ---
houseGray  = imresize(houseGray,          [szY, szX]);
faceGray   = imresize(faceGray,           [szY, szX]);
houseMask  = imresize(double(houseMask),  [szY, szX]) > 0.5;
faceMask   = imresize(double(faceMask),   [szY, szX]) > 0.5;

% --- [added 2026-11-10] restrict the content to the visible aperture ---
% Same geometry as getVisualDesignSettings + generate.createOApertureXFrame:
% the image is drawn centred on the frame, pixel centres inside radiusInner
% are visible (generate.visibleMask). With 'visible' everything below (mean /
% RMS matching, plaids, catch images, weight maps, verification) refers to
% the visible content only; content behind the frame becomes background.
apertureDiameterPx = round(PixPerDeg * o.stimSizeInDegrees * o.frameSizeFactor * o.frameApertureFactor);
radiusInner        = apertureDiameterPx / 2 * (1 - o.frameThickness);
[Jg, Ig]   = meshgrid(1:szX, 1:szY);
visibleMask = hypot((Jg - 0.5) - szX / 2, (Ig - 0.5) - szY / 2) < radiusInner;
fprintf('Aperture       : diameter %d px, visible radius %.2f px (%.3f deg), %d of %d px visible\n', ...
    apertureDiameterPx, radiusInner, radiusInner / PixPerDeg, nnz(visibleMask), numel(visibleMask));
if strcmpi(o.matchRegion, 'visible')
    fprintf('Match region   : visible content (house %d of %d content px, face %d of %d)\n', ...
        nnz(houseMask & visibleMask), nnz(houseMask), nnz(faceMask & visibleMask), nnz(faceMask));
    houseMask = houseMask & visibleMask;
    faceMask  = faceMask  & visibleMask;
else
    fprintf('Match region   : all content (hidden parts included)\n');
end

fprintf('Source dims    : house %d×%d px,  face %d×%d px\n', ...
    size(houseRaw,2), size(houseRaw,1), size(faceRaw,2), size(faceRaw,1));
fprintf('Bandwidth match: pre-downsampled %s to %d px max dim\n', ...
    ternary(maxDimFace > maxDimHouse, 'face', 'house'), min(maxDimHouse, maxDimFace));
fprintf('Effective BW   : %.0f cycles/image  (= %d px / 2)\n', ...
    min(maxDimHouse, maxDimFace)/2, min(maxDimHouse, maxDimFace));
fprintf('Stimulus size  : %d × %d px\n', szX, szY);
fprintf('House content  : %d px  (%.1f%%)\n', sum(houseMask(:)), 100*mean(houseMask(:)));
fprintf('Face  content  : %d px  (%.1f%%)\n', sum(faceMask(:)),  100*mean(faceMask(:)));
fprintf('Overlap region : %d px  (%.1f%%)\n', sum(houseMask(:)&faceMask(:)), 100*mean(houseMask(:)&faceMask(:)));
fprintf('\n');

%% ===== Spatial modulation mask (patch-based catch stimuli) ==============
% W(x,y) ∈ [0,1], mean = 0.5, used by catch_ov and catch_half.
% A diagonal sinusoidal grating with o.patchFreq cycles per image creates
% several alternating smooth patches where house vs. face is foregrounded.
%[Xg, Yg] = meshgrid(1:sz, 1:sz);
%W = 0.5 * (1 + cos(2*pi * o.patchFreq * (Xg + Yg) / sz));
%fprintf('Patch mask  : %.0f cycles/image  mean=%.3f\n', o.patchFreq, mean(W(:)));
%fprintf('\n');

%% ===== Generate stimuli for each angle ==================================

% Evenly-spaced angles across 1–360 (keeps round numbers for readability)
%angles = unique(round(linspace(1, 360, o.numAngles)));
%nAng   = numel(angles);   % may differ by ±1 from o.numAngles due to rounding

angles = (0:o.numAngles-1) * 360 / o.numAngles;   % default 24 -> 0:15:345
nAng   = numel(angles);
% Coordinates centred on the image
[Xg, Yg] = meshgrid( ...
    (1:szX) - (szX + 1)/2, ...
    (1:szY) - (szY + 1)/2);


fprintf('--- Generating %d angle(s) ---\n', nAng);
tStart = tic;

for angi = 1:nAng
    angle = angles(angi);


    theta = deg2rad(angle);

    % Coordinate perpendicular to the stripe direction.
    % With this convention, "angle" describes the orientation of the stripes.
    normalCoordinate = -Xg .* sind(angle) + Yg .* cosd(angle);
    
    % Continuous mask used as a spatial ranking score.
    W = 0.5 .* ...
        (1 + cos(2*pi * o.patchFreq .* normalCoordinate ./ sz));
    
    fprintf('\nAngle %3d°: mask mean = %.4f\n', angle, mean(W(:)));

    % Progress display every ~10%
    if nAng >= 10 && (mod(angi, max(1,floor(nAng/10)))==0 || angi==1 || angi==nAng)
        fprintf('  [%3d/%d]  angle %d°\n', angi, nAng, angle);
    end

    % ---- No orientation filter: use raw grayscale images ----
    houseFilt = houseGray;
    faceFilt  = faceGray;

    % ---- Normal contrast ----
    houseN = matchLumRMS(houseFilt, houseMask, o.targetLum, o.targetRMS);
    faceN  = matchLumRMS(faceFilt,  faceMask,  o.targetLum, o.targetRMS);

    % ---- Low contrast ----
    houseL = matchLumRMS(houseFilt, houseMask, o.targetLum, o.lowRMS);
    faceL  = matchLumRMS(faceFilt,  faceMask,  o.targetLum, o.lowRMS);

    % ---- Plaid (50/50 blend over overlap region, re-normalised to targetRMS) ----
    plaidN = makePlaid(houseN, faceN, houseMask, faceMask, o.targetLum, o.targetRMS);
    plaidL = makePlaid(houseL, faceL, houseMask, faceMask, o.targetLum, o.lowRMS);

    % ---- Catch stimuli (left|right with cosine fade, overlap region only) ----
    [catchHF_N, catchFH_N, wHF, wFH] = makeCatch(houseN, faceN, houseMask, faceMask, o.fadeWidth, o.targetLum, o.targetRMS);
    [catchHF_L, catchFH_L] = makeCatch(houseL, faceL, houseMask, faceMask, o.fadeWidth, o.targetLum, o.lowRMS);

    % ---- Plaid (full union mask — 50/50 blend across all content) ----
    plaidFN = makePlaidFull(houseN, faceN, houseMask, faceMask, o.targetLum, o.targetRMS);
    plaidFL = makePlaidFull(houseL, faceL, houseMask, faceMask, o.targetLum, o.lowRMS);

    % ---- catch_ov: patch mask in overlap; non-overlap shows full stim ----
    [catchOvN, wOv] = makeCatchOv(houseN, faceN, houseMask, faceMask, W, o.fadeWidth, o.targetLum, o.targetRMS);
    catchOvL  = makeCatchOv(houseL, faceL, houseMask, faceMask, W, o.fadeWidth, o.targetLum, o.lowRMS);

    % ---- catch_ov5050 [added 2026-11-04]: as catch_ov, but 50:50 overall ----
    % The house gets less of the overlap so that house and face each make up
    % exactly half of the whole catch image (see makeCatchOv5050).
    [catchOv5N, wOv5] = makeCatchOv5050(houseN, faceN, houseMask, faceMask, W, o.fadeWidth, o.targetLum, o.targetRMS, angle);
    catchOv5L = makeCatchOv5050(houseL, faceL, houseMask, faceMask, W, o.fadeWidth, o.targetLum, o.lowRMS, []);

    % ---- catch_half: 50/50 patch mask everywhere; non-overlap = grey patch ----
    [catchHalfN, wHalf] = makeCatchHalf(houseN, faceN, houseMask, faceMask, W, o.targetLum, o.targetRMS);
    catchHalfL = makeCatchHalf(houseL, faceL, houseMask, faceMask, W, o.targetLum, o.lowRMS);

    % ---- Save all 18 categories ----
    saveStim(houseN,     o.outputDir, 'house',          angle);
    saveStim(faceN,      o.outputDir, 'face',           angle);
    saveStim(plaidN,     o.outputDir, 'plaid',          angle);
    saveStim(catchHF_N,  o.outputDir, 'catch_hf',       angle);
    saveStim(catchFH_N,  o.outputDir, 'catch_fh',       angle);
    saveStim(houseL,     o.outputDir, 'house_low',      angle);
    saveStim(faceL,      o.outputDir, 'face_low',       angle);
    saveStim(plaidL,     o.outputDir, 'plaid_low',      angle);
    saveStim(catchHF_L,  o.outputDir, 'catch_hf_low',   angle);
    saveStim(catchFH_L,  o.outputDir, 'catch_fh_low',   angle);
    saveStim(plaidFN,    o.outputDir, 'plaid_full',     angle);
    saveStim(plaidFL,    o.outputDir, 'plaid_full_low', angle);
    saveStim(catchOvN,   o.outputDir, 'catch_ov',       angle);
    saveStim(catchOvL,   o.outputDir, 'catch_ov_low',   angle);
    saveStim(catchOv5N,  o.outputDir, 'catch_ov5050',     angle);
    saveStim(catchOv5L,  o.outputDir, 'catch_ov5050_low', angle);
    saveStim(catchHalfN, o.outputDir, 'catch_half',     angle);
    saveStim(catchHalfL, o.outputDir, 'catch_half_low', angle);
    % blend weights of the catch images (house / face), used by
    % generate.getContrastAdjustedImages to rebuild them at calibrated contrasts
    saveWeights(wHF,   o.outputDir, 'catch_hf',   angle);
    saveWeights(wFH,   o.outputDir, 'catch_fh',   angle);
    saveWeights(wOv,   o.outputDir, 'catch_ov',   angle);
    saveWeights(wOv5,  o.outputDir, 'catch_ov5050', angle);
    saveWeights(wHalf, o.outputDir, 'catch_half', angle);
end

elapsed = toc(tStart);

%% ===== Summary ==========================================================

fprintf('\n=== Done! ===\n');
fprintf('Elapsed time    : %.1f s (%.2f s/angle)\n', elapsed, elapsed/nAng);
fprintf('Output dir      : %s\n', o.outputDir);
fprintf('Stimulus size   : %d x %d pixels (width x height)\n', szX, szY);
fprintf('Angles generated: %d\n', nAng);
fprintf('Categories      : %d\n', numel(categories));
fprintf('Total files     : %d (+ %d catch weight maps)\n', nAng * numel(categories), 5 * nAng);
fprintf('\nCategories:\n');
for c = 1:numel(categories)
    fprintf('  %-20s  %d images\n', categories{c}, nAng);
end
fprintf('\n');

% Verify final statistics (first angle only, for speed)
unionMask   = houseMask | faceMask;
overlapMask = houseMask & faceMask;
verifyStimulus(o.outputDir, 'house',      angles(1), houseMask);
verifyStimulus(o.outputDir, 'face',       angles(1), faceMask);
verifyStimulus(o.outputDir, 'plaid',      angles(1), overlapMask);
verifyStimulus(o.outputDir, 'catch_hf',   angles(1), overlapMask);
verifyStimulus(o.outputDir, 'plaid_full', angles(1), unionMask);
verifyStimulus(o.outputDir, 'catch_ov',   angles(1), unionMask);
verifyStimulus(o.outputDir, 'catch_ov5050', angles(1), unionMask);
verifyStimulus(o.outputDir, 'catch_half', angles(1), unionMask);

end % ===== end main function =============================================


%% =======================================================================
%%  LOCAL HELPER FUNCTIONS
%% =======================================================================

% (applyOrientationFilter removed — no orientation filter applied)


function out = matchLumRMS(img, mask, targetLum, targetRMS)
% matchLumRMS  Match mean luminance and RMS contrast of image content.
%
%   RMS contrast is defined as std(content_pixels) / 255.
%   Background pixels (mask == 0) are set to targetLum.
%
%   Inputs:
%     img       – uint8 grayscale image
%     mask      – logical mask: true = image content
%     targetLum – desired mean luminance (0–255)
%     targetRMS – desired RMS contrast as fraction of 255
%
%   Output:
%     out       – uint8 image with matched luminance and RMS contrast

img  = double(img);
msk  = logical(mask);

pixels = img(msk);
mu     = mean(pixels);
sig    = std(pixels);

targetStd = targetRMS * 255; % 

if sig > 0
    imgAdj = (img - mu) ./ sig .* targetStd + targetLum;
else
    imgAdj = ones(size(img)) .* targetLum;
end

imgAdj(~msk) = targetLum;           % background: flat grey
out = uint8(max(0, min(255, round(imgAdj))));

% Statistics of out inside the mask only
outPixels = double(out(msk));

meanLuminance = mean(outPixels);
stdLuminance  = std(outPixels);

% Same contrast definition used by your adjustment:
% standard deviation as a fraction of the uint8 range
rmsContrast = stdLuminance / 255;
rmsStandarddef = stdLuminance/targetLum;

fprintf('Inside mask:\n');
fprintf('  Mean luminance: %.3f\n', meanLuminance);
fprintf('  SD luminance:   %.3f\n', stdLuminance);
fprintf('  RMS contrast:   %.4f\n', rmsContrast);
fprintf('RMS: stdLum/targetLum: %.3f\n', rmsStandarddef);
end

function out = matchLumRMSLog(img, mask, targetLum, targetRMS)
% Match foreground mean and contrast after logarithmic tail compression.
%
% compression:
%   0     = no logarithmic compression
%   0.5   = mild compression
%   1     = moderate compression
%   2-3   = stronger compression
compression = 0;

img = double(img);
msk = logical(mask);

if ~any(msk(:))
    error('The mask does not contain any foreground pixels.');
end

pixels = img(msk);

mu  = mean(pixels);
sig = std(pixels);

targetStd = targetRMS * 255;

% Initialize the whole image as grey background
imgAdj = ones(size(img)) .* targetLum;

if sig > 0
    % Standardized foreground values
    z = (pixels - mu) ./ sig;

    % Signed logarithmic compression:
    % positive values remain positive, negative values remain negative
    if compression > 0
        zCompressed = sign(z) .* log1p(compression .* abs(z)) ./ compression;
    else
        zCompressed = z;
    end

    % Recenter and normalize after nonlinear compression
    zCompressed = zCompressed - mean(zCompressed);
    compressedStd = std(zCompressed);

    if compressedStd > 0
        zCompressed = zCompressed ./ compressedStd;
    end

    % Set requested foreground mean and SD
    imgAdj(msk) = targetLum + targetStd .* zCompressed;
end

% Count values outside uint8 range before clipping
nBelow = nnz(imgAdj(msk) < 0);
nAbove = nnz(imgAdj(msk) > 255);

% Clip, round, and convert to uint8
out = uint8(max(0, min(255, round(imgAdj))));

% Measure the actual final foreground statistics
outPixels = double(out(msk));

meanLuminance = mean(outPixels);
stdLuminance  = std(outPixels);
contrast255   = stdLuminance / 255;
contrastMean  = stdLuminance / meanLuminance;

fprintf('Foreground statistics after logarithmic compression:\n');
fprintf('  Mean luminance:              %.3f DN\n', meanLuminance);
fprintf('  Standard deviation:          %.3f DN\n', stdLuminance);
fprintf('  Contrast (SD / 255):         %.4f\n', contrast255);
fprintf('  RMS contrast (SD / mean):    %.4f\n', contrastMean);
fprintf('  Foreground range:            %.0f to %.0f DN\n', ...
        min(outPixels), max(outPixels));
fprintf('  Pixels clipped at 0:         %d\n', nBelow);
fprintf('  Pixels clipped at 255:       %d\n', nAbove);
end

function plaid = makePlaid(house, face, houseMask, faceMask, targetLum, targetRMS)
% makePlaid  Combine house and face as a 50/50 equal-weight plaid.
%
%   Content is restricted to the OVERLAP region (houseMask & faceMask) so
%   that each stimulus contributes equally and neither dominates.  The
%   blended pixels are then re-normalised to targetRMS via matchLumRMS.
%
%   Inputs:
%     house, face   – uint8 grayscale stimuli (already luminance/RMS matched)
%     houseMask     – logical content mask for house
%     faceMask      – logical content mask for face
%     targetLum     – background / mean luminance (0–255)
%     targetRMS     – desired RMS contrast for the output, fraction of 255

h           = double(house);
f           = double(face);
overlapMask = logical(houseMask) & logical(faceMask);

blend             = 0.5 .* h + 0.5 .* f;
blend(~overlapMask) = targetLum;    % outside overlap: plain gray

% Re-normalise so the output hits targetRMS despite the 50% amplitude drop
plaid = matchLumRMS(uint8(max(0, min(255, round(blend)))), overlapMask, targetLum, targetRMS);
end


function [catchHF, catchFH, wHF, wFH] = makeCatch(house, face, houseMask, faceMask, fadeWidth, bgLum, targetRMS)
% makeCatch  Create left|right catch stimuli with a cosine-fade transition.
%
%   catchHF : left = house, right = face
%   catchFH : left = face,  right = house
%
%   Content is restricted to the OVERLAP region (houseMask & faceMask): a
%   pixel is shown only where BOTH stimuli have content, so each half of the
%   catch is a windowed patch of its stimulus visible through the other's
%   silhouette.  The output is re-normalised to targetRMS via matchLumRMS.
%
%   A cosine interpolation is applied in the zone
%   [mid - fadeWidth, mid + fadeWidth] pixels, so the transition is smooth
%   and gradual rather than a hard edge.
%
%   Inputs:
%     house, face  – uint8 grayscale stimuli (already luminance/RMS matched)
%     houseMask    – logical content mask for house
%     faceMask     – logical content mask for face
%     fadeWidth    – half-width of transition zone in pixels
%     bgLum        – luminance value for background pixels
%     targetRMS    – desired RMS contrast for the output, fraction of 255

[height, width] = size(house);
mid             = round(width / 2);
overlapMask     = logical(houseMask) & logical(faceMask);

% Build 1-D cosine weight for LEFT image (1 on left, 0 on right)
wLeft = ones(1, width);
for x = 1:width
    if x <= mid - fadeWidth
        wLeft(x) = 1;
    elseif x >= mid + fadeWidth
        wLeft(x) = 0;
    else
        % Cosine interpolation: smooth S-curve
        t         = (x - (mid - fadeWidth)) / (2 * fadeWidth);   % 0 → 1
        wLeft(x)  = 0.5 * (1 + cos(pi * t));
    end
end
wRight = 1 - wLeft;

% Expand weights to 2-D
wL = repmat(wLeft,  [height, 1]);
wR = repmat(wRight, [height, 1]);

h  = double(house);
f  = double(face);

blendHF = h .* wL + f .* wR;
blendFH = f .* wL + h .* wR;

% Restrict to overlap: outside the intersection → plain gray
blendHF(~overlapMask) = bgLum;
blendFH(~overlapMask) = bgLum;

% Re-normalise so the output hits targetRMS
catchHF = matchLumRMS(uint8(max(0, min(255, round(blendHF)))), overlapMask, bgLum, targetRMS);
catchFH = matchLumRMS(uint8(max(0, min(255, round(blendFH)))), overlapMask, bgLum, targetRMS);
% blend weights (house, face) for saveWeights
wHF = cat(3, wL .* overlapMask, wR .* overlapMask);
wFH = cat(3, wR .* overlapMask, wL .* overlapMask);
end


function saveStim(img, outputDir, category, angle)
% saveStim  Write stimulus as a plain RGB PNG with gray background baked in.
%
%   Background pixels are already set to targetLum (gray) by matchLumRMS /
%   makePlaid / makeCatch, so no alpha channel is needed.
%
%   Filename convention matches readInStimuli:
%     <outputDir>/<category>/<category><angle>.png
%     e.g.  stimuli/house/house42.png

rgb   = cat(3, img, img, img);   % grayscale → MxNx3
fname = stimFileName(outputDir, category, angle, '.png');
imwrite(rgb, fname);
end


function verifyStimulus(outputDir, category, angle, mask)
% verifyStimulus  Load a saved stimulus and report its actual statistics.

fname = stimFileName(outputDir, category, angle, '.png');
if ~exist(fname, 'file'), return; end

img    = imread(fname);
gray   = double(img(:,:,1));   % R channel = grayscale
msk    = logical(mask);
pixels = gray(msk);

fprintf('  [verify] %-15s  mean=%.1f DN   RMS=%.4f   std=%.1f DN\n', ...
    category, mean(pixels), std(pixels)/255, std(pixels));
end


% (FFT helpers removed — not needed without orientation filter)


function out = makePlaidFull(house, face, houseMask, faceMask, targetLum, targetRMS)
% makePlaidFull  50/50 blend over the full UNION mask (not just overlap).
%
%   In the overlap region  : 0.5*house + 0.5*face  (same as makePlaid)
%   In house-only region   : 0.5*house + 0.5*gray  (face background = gray)
%   In face-only region    : 0.5*gray  + 0.5*face  (house background = gray)
%
%   Because matchLumRMS already sets non-mask pixels to targetLum (gray),
%   the simple 0.5*h + 0.5*f formula handles all regions correctly.
%   Result is re-normalised to targetRMS over the union mask.

h         = double(house);
f         = double(face);
unionMask = logical(houseMask) | logical(faceMask);

blend             = 0.5 .* h + 0.5 .* f;
blend(~unionMask) = targetLum;

out = matchLumRMS(uint8(max(0, min(255, round(blend)))), unionMask, targetLum, targetRMS);
end


function [out, wOut] = makeCatchOv(house, face, houseMask, faceMask, W, fadeWidth, bgLum, targetRMS)
% makeCatchOv  Patch-based catch stimulus: overlap uses W-modulated patches;
%              non-overlap regions show the full stimulus present there.
%
%   In the overlap region : W*house + (1-W)*face  (W = sinusoidal patch mask)
%   In house-only region  : house                 (fully shown)
%   In face-only region   : face                  (fully shown)
%   Transition at boundary: smooth cosine fade (Gaussian blur of overlapMask
%                           with sigma=fadeWidth).
%
%   The overall weight for house = softOverlap.*W + (1-softOverlap).*houseMask,
%   which is 1 in house-only, 0 in face-only, and W in the overlap, with a
%   cosine-like blend zone at the boundary of width ~fadeWidth pixels.

overlapMask  = logical(houseMask) & logical(faceMask);
unionMask    = logical(houseMask) | logical(faceMask);

% Smooth overlap indicator — creates cosine-like fade at the boundary
softOverlap  = imgaussfilt(double(overlapMask), fadeWidth);

% Weight for house: 1 in house-only, 0 in face-only, W in overlap, smooth in between
% double(houseMask) = 1 wherever house exists (including overlap)
weightHouse  = softOverlap .* W + (1 - softOverlap) .* double(houseMask);

h   = double(house);
f   = double(face);
blend            = weightHouse .* h + (1 - weightHouse) .* f;
blend(~unionMask) = bgLum;

out = matchLumRMS(uint8(max(0, min(255, round(blend)))), unionMask, bgLum, targetRMS);
wOut = cat(3, weightHouse .* unionMask, (1 - weightHouse) .* unionMask);
end


function [out, wOut, gammaUsed] = makeCatchOv5050(house, face, houseMask, faceMask, W, fadeWidth, bgLum, targetRMS, angle)
% makeCatchOv5050  [added 2026-11-04] Patch catch like catch_ov, but with
%                  house : face = 50 : 50 over the WHOLE catch image.
%
% Why: in catch_ov the house won the catch image (catch_ov45 of the current
% stimuli: 59.6 % house weight overall), for two reasons:
%   1. In makeCatchOv the weight inside the overlap falls back to the house
%      mask (= 1) wherever the blurred overlap indicator is below 1, i.e. near
%      the edge of the overlap: 56 % house in the overlap instead of 50 %.
%   2. The house-only area (shown as pure house) is larger than the face-only
%      area (shown as pure face): 904 vs. 238 px for the current stimuli.
%
% What this function does differently (house weight h, face weight 1 - h):
%   - Overlap:       h = W.^gamma exactly (no fallback to the house mask).
%                    W is the same sinusoidal patch mask as in catch_ov
%                    (values 0-1, mean ~0.5). The power gamma keeps the
%                    patches (h = 0 and h = 1 stay where they are) but
%                    narrows the house patches for gamma > 1 / widens them
%                    for gamma < 1.
%   - House-only /   pure house (h = 1) / pure face (h = 0), as in catch_ov,
%     face-only:     with a fade of width fadeWidth (Gaussian SD, px) from the
%                    patch weights at the edge of the overlap to the pure value.
%                    The fade lies only OUTSIDE the overlap.
%   - gamma is chosen (bisection) so that the mean house weight over all
%     content pixels (house mask OR face mask) is 0.5. So the house gets less
%     of the overlap exactly as much as it has more area outside it.
%     gamma only depends on the masks and W, so it is the same for the normal
%     and the low-contrast version.
%   - If 50:50 cannot be reached (an extremely unequal house-only vs.
%     face-only area), the closest gamma is used and a warning is printed.
%
% The weights (wOut: R = house, G = face) are saved like those of catch_ov;
% generate.getContrastAdjustedImages rebuilds the catch image from them at
% the subject's calibrated contrasts, so the 50:50 holds in the experiment too.
% angle: only used for the printed line (empty = no print).

if nargin < 9; angle = []; end
houseMask   = logical(houseMask);
faceMask    = logical(faceMask);
overlapMask = houseMask & faceMask;
unionMask   = houseMask | faceMask;

% fade outside the overlap: 1 at the overlap, falling off over ~2 x fadeWidth px
if fadeWidth > 0
    softOverlap = imgaussfilt(double(overlapMask), fadeWidth);
else
    softOverlap = double(overlapMask);
end
softOverlap(overlapMask) = 1;            % inside the overlap: patch weights only

houseWeight = @(g) softOverlap .* (W .^ g) + (1 - softOverlap) .* double(houseMask);
houseShare  = @(g) meanInMask(houseWeight(g), unionMask);   % mean house weight over all content pixels

% bisection on log(gamma): the house share falls monotonically with gamma
lo = log(1/20); hi = log(20);
if houseShare(exp(lo)) < 0.5 || houseShare(exp(hi)) > 0.5
    % 50:50 not reachable: take the closer end
    if abs(houseShare(exp(lo)) - 0.5) < abs(houseShare(exp(hi)) - 0.5); g = exp(lo); else; g = exp(hi); end
    warning('createFMRIStimuli:ov5050', ['catch_ov5050: 50:50 not reachable (house share %.3f with gamma %.2f). ' ...
        'The house-only and face-only areas differ too much.'], houseShare(g), g);
else
    for it = 1:60
        mid = (lo + hi) / 2;
        if houseShare(exp(mid)) > 0.5; lo = mid; else; hi = mid; end
    end
    g = exp((lo + hi) / 2);
end
gammaUsed = g;
weightHouse = houseWeight(g);

h   = double(house);
f   = double(face);
blend             = weightHouse .* h + (1 - weightHouse) .* f;
blend(~unionMask) = bgLum;

out  = matchLumRMS(uint8(max(0, min(255, round(blend)))), unionMask, bgLum, targetRMS);
wOut = cat(3, weightHouse .* unionMask, (1 - weightHouse) .* unionMask);

if ~isempty(angle)
    fprintf(['  catch_ov5050 %3g deg: gamma %.2f -> house share %.3f overall, %.3f in the overlap ' ...
        '(%d overlap, %d house-only, %d face-only px)\n'], angle, g, mean(weightHouse(unionMask)), ...
        mean(weightHouse(overlapMask)), nnz(overlapMask), nnz(houseMask & ~faceMask), nnz(faceMask & ~houseMask));
end
end


function m = meanInMask(x, mask)
% meanInMask  Mean of x over the pixels where mask is true (used by makeCatchOv5050).
m = mean(x(mask));
end


function [out, wOut] = makeCatchHalf(house, face, houseMask, faceMask, W, bgLum, targetRMS)
% makeCatchHalf  Global 50/50 patch catch: house and face each occupy ~50%
%                of ALL content pixels (overlap and non-overlap alike).
%
%   Everywhere : W*house + (1-W)*face
%
%   Since matchLumRMS sets non-mask pixels to bgLum (gray), the formula
%   naturally produces:
%     Overlap    : W*house_content + (1-W)*face_content
%     House-only : W*house_content + (1-W)*gray   (face "patch" = gray)
%     Face-only  : W*gray          + (1-W)*face_content
%
%   W is a sinusoidal mask with mean=0.5, so house and face each contribute
%   50% in expectation everywhere.  Result is re-normalised to targetRMS
%   over the union mask.

unionMask = logical(houseMask) | logical(faceMask);

h = double(house);
f = double(face);

blend            = W .* h + (1 - W) .* f;
blend(~unionMask) = bgLum;

out = matchLumRMS(uint8(max(0, min(255, round(blend)))), unionMask, bgLum, targetRMS);
wOut = cat(3, W .* unionMask, (1 - W) .* unionMask);
end


function saveWeights(w, outputDir, category, angle)
% saveWeights  Blend weights of a catch image: R = house weight, G = face
% weight (0-1 -> 0-255), B = 0.  <outputDir>/<category>/<category><angle>_weights.png
rgb   = uint8(round(255 * cat(3, min(max(w(:,:,1), 0), 1), min(max(w(:,:,2), 0), 1), zeros(size(w, 1), size(w, 2)))));
fname = stimFileName(outputDir, category, angle, '_weights.png');
imwrite(rgb, fname);
end


function fname = stimFileName(outputDir, category, angle, suffix)
% stimFileName  <outputDir>/<category>/<category><angle><suffix>, e.g. house/house45.png.
% [added 2026-11-04] A category name that ends in a digit (catch_ov5050) gets
% an underscore before the angle, so the file is catch_ov5050_45.png and not
% catch_ov505045.png. All other names are unchanged.
sep = '';
if ~isempty(category) && any(category(end) == '0123456789'); sep = '_'; end
fname = fullfile(outputDir, category, [category, sep, num2str(angle), suffix]);
end


function out = ternary(cond, a, b)
% ternary  Return a if cond is true, b otherwise.
if cond, out = a; else, out = b; end
end
