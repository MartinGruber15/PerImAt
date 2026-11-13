function design = getContrastAdjustedImages(ptb, design, stimuliParameters, myPaths, fixTexture, dotTransparency)
% Generate contrast-adjusted stimulus images and masks.
%
% [changed 2026-11-10] The contrast c of a texture is applied around the mean
% of its VISIBLE CONTENT (design.contrastReference = 'visible', default):
% out = (raw - m) * c + 128 with m = mean of the stimulus pixels (not the grey
% background) inside the frame aperture (generate.contrastReferenceMask), so
% the visible part of every texture has mean 128 at every contrast. Before,
% m was the mean of the whole captured square ('image'), which made the
% visible house ~1 grey level brighter and the face ~1 darker than 128.
% questplus.applyContrast (calibration) uses the same reference.
% Creates base, single-dot, and valid two-dot variants.
% Reversed two-dot names reference the same generated image.
%
% Fixation dots (no-report): the dot texture is captured once per position
% as an opacity map A and premultiplied colour A*C (drawn over black and
% over white). Each dot image is then the contrast-adjusted base image with
% the dot composited on top:
%   out = (1 - A) .* base + A .* ((C - m) * dotContrast + defaultLuminance)
% (m = mean of the raw base image). The dot's contrast is set by
% design.fixDotContrastMode:
%   'weakest' (default): the same for all four textures, equal to the lowest
%             texture contrast (min over house/face x left/right), so no dot is
%             stronger relative to its image than on the weakest texture
%   'texture': dotContrast = contrast of its own texture (previous behaviour;
%             identical to drawing the dot before applyContrast)
%   'fixed'  : dotContrast = design.fixDotContrast
%   'local'  : [added 2026-11-05] between textures as 'texture' (dot contrast
%             proportional to the texture contrast), but per dot the grey level
%             is set from the image under it, so that its step over the local
%             mean grey is the same fraction of that mean at every position
%             (bright cheek -> brighter dot, dark parts -> weaker dot);
%             optionally stronger on busy texture (design.fixDotLocalMaskGain,
%             radius design.fixDotLocalRadiusInDegrees). With
%             design.fixDotLocalWeber set to a number, the same step/local mean
%             in all four textures instead of scaling with the texture contrast
%             (equal visibility in both eyes and for house and face). See
%             generate.localDotTargets; the values per texture and position
%             are saved as design.fixDotLocal.
%
% Catch images of the report condition (catch_houseface.png,
% catch_facehouse.png) are captured the same way (same on-screen resolution,
% pink-noise background at the same resolution as the rivalry textures) and
% built from the rivalry textures: per catch file one image with the houseL
% and faceR textures and one with faceL and houseR
% (design.images.<houseface|facehouse><HouseLFaceR|FaceLHouseR>), see
% addCatchImages below.

eyeNames = {'L','R'};
eyeContrasts = [stimuliParameters.leftEyeContrast, stimuliParameters.rightEyeContrast];
stimulusNames = {'house','face'};
stimulusContrasts = [stimuliParameters.houseContrast, stimuliParameters.faceContrast];

allContrasts = stimulusContrasts(:) * eyeContrasts(:)';   % HouseL HouseR; FaceL FaceR
dotMode = 'texture';
if design.hasField('fixDotContrastMode'); dotMode = design.fixDotContrastMode; end
useLocal = false;   % [added 2026-11-05] 'local' mode
switch lower(dotMode)
    case 'weakest'
        dotContrast = min(allContrasts(:));
    case 'texture'
        dotContrast = [];                        % per texture, set below
    case 'fixed'
        dotContrast = design.fixDotContrast;
    case 'local'                                 % [added 2026-11-05]
        dotContrast = [];                        % per texture and position, set below
        useLocal = true;
    otherwise
        error('Unknown design.fixDotContrastMode "%s".', dotMode);
end
if useLocal
    fprintf('Fixation dots: ''local'' (step over the local mean grey under each dot)\n');
elseif isempty(dotContrast)
    fprintf('Fixation dots: contrast of their own texture\n');
else
    fprintf('Fixation dots: contrast %.4f in all four textures (mode ''%s'')\n', dotContrast, dotMode);
end
design.fixDotContrastUsed = dotContrast;

validPairs = unique(sort(design.fixDotValidPairs,2),'rows');
dest = design.destinationRect;
captureRect = [floor(dest(1)), floor(dest(2)), ceil(dest(3)), ceil(dest(4))];
nPositions = size(design.fixDotPositions,1);
originalTextures = zeros(1,numel(stimulusNames));
rawImages = cell(1,numel(stimulusNames));   % captured, not contrast-adjusted (identical for both eyes)

% Load source images.
for s = 1:numel(stimulusNames)
    filename = fullfile(myPaths.stimuliLocation,[stimulusNames{s} '.png']);
    assert(isfile(filename),'Stimulus file does not exist: %s',filename);
    [img,~,alpha] = imread(filename);
    if ndims(img) == 2, img = repmat(img,[1 1 3]); end
    if ~isempty(alpha), img = cat(3,img,alpha); end
    originalTextures(s) = Screen('MakeTexture',ptb.window,img);
end

% All drawing for the captures happens in an OFFSCREEN window, never in the
% on-screen stereo buffers: drawing there (plus DrawingFinished) made the last
% capture - e.g. the dot over a black square - appear in the left eye at the
% next Flip (seen on the consent screen).
cap = Screen('OpenOffscreenWindow', ptb.window, ptb.grey, ptb.windowRect);
Screen('BlendFunction', cap, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');   % as the on-screen window
try
    % opacity and colour of the dot texture at every position (stimulus independent)
    [dotA, dotAC] = captureDotLayers(ptb,cap,design,captureRect,nPositions,fixTexture,dotTransparency);

    for s = 1:numel(stimulusNames)
        rawImages{s} = captureStimulus(cap,originalTextures(s),design,captureRect,[],fixTexture,dotTransparency,ptb.grey);
    end
    % [added 2026-11-10] centre of the contrast scaling per stimulus (visible content)
    refMasks = cell(1,numel(stimulusNames)); refMeans = zeros(1,numel(stimulusNames));
    for s = 1:numel(stimulusNames)
        [refMasks{s}, refMeans(s), refInfo(s)] = generate.contrastReferenceMask(rawImages{s}, design); %#ok<AGROW>
        fprintf('Contrast reference %s: %s, %d px, mean %.2f, SD %.2f (raw image)\n', stimulusNames{s}, ...
            refInfo(s).mode, refInfo(s).nPixels, refInfo(s).refMean, refInfo(s).refSD);
    end
    design.contrastReferenceInfo = refInfo;   % saved with design.mat

    % [added 2026-11-05] 'local' mode: grey level of every dot in every texture
    % from the image under it (generate.localDotTargets), same texture order as
    % the loop below (houseL, faceL, houseR, faceR)
    if useLocal
        radiusDeg = 0.15; if design.hasField('fixDotLocalRadiusInDegrees'); radiusDeg = design.fixDotLocalRadiusInDegrees; end
        maskGain  = 0;    if design.hasField('fixDotLocalMaskGain');        maskGain  = design.fixDotLocalMaskGain;        end
        weberFixed = [];  if design.hasField('fixDotLocalWeber');           weberFixed = design.fixDotLocalWeber;          end
        lumExponent = 1;  if design.hasField('fixDotLocalLumExponent');     lumExponent = design.fixDotLocalLumExponent;   end
        bases = {}; texNames = {}; texContrasts = []; texRawMeans = [];
        for e = 1:numel(eyeNames)
            for s = 1:numel(stimulusNames)
                c = stimulusContrasts(s)*eyeContrasts(e);
                bases{end+1} = applyContrast(rawImages{s},c,design.defaultLuminance,refMasks{s}); %#ok<AGROW>
                texNames{end+1} = [stimulusNames{s} eyeNames{e}]; %#ok<AGROW>
                texContrasts(end+1) = c; %#ok<AGROW>
                texRawMeans(end+1) = refMeans(s); %#ok<AGROW>   [changed 2026-11-10] centre of the scaling
            end
        end
        [localT, localInfo] = generate.localDotTargets(bases, dotA, dotAC, texContrasts, texRawMeans, ...
            design.defaultLuminance, radiusDeg * ptb.PixPerDegWidth, maskGain, texNames, weberFixed, lumExponent);
        fprintf('  reference: %s, clutter gain %.2f, luminance exponent %.2f\n', localInfo.reference, maskGain, lumExponent);
        design.fixDotLocal = localInfo;   % saved with design.mat
        for k = 1:numel(texNames)
            fprintf('  %-7s dot step %.0f-%.0f grey levels = %.2f-%.2f of the local mean (local mean grey %.0f-%.0f)\n', texNames{k}, ...
                min(localInfo.step(k,:)), max(localInfo.step(k,:)), ...
                min(localInfo.weber(k,:)), max(localInfo.weber(k,:)), ...
                min(localInfo.Lloc(k,:)), max(localInfo.Lloc(k,:)));
        end
        nClipped = 0; nDarker = 0;
    end

    k = 0;   % texture index (localT row)
    for e = 1:numel(eyeNames)
        eyeName = eyeNames{e};

        for s = 1:numel(stimulusNames)
            k = k + 1;
            baseName = [stimulusNames{s} eyeName];
            contrast = stimulusContrasts(s)*eyeContrasts(e);

            % Base image, without fixation dots.
            raw = rawImages{s};
            base = applyContrast(raw,contrast,design.defaultLuminance,refMasks{s});   % [changed 2026-11-10] visible content
            design.images.(baseName) = base;
            design.masks.(baseName) = [];
            rawMean = refMeans(s);   % [changed 2026-11-10] the same centre as applyContrast (dot = part of the image)
            if isempty(dotContrast); thisDotContrast = contrast; else; thisDotContrast = dotContrast; end

            % Single-dot variants.
            for pos = 1:nPositions
                name = sprintf('%s_dot_%d',baseName,pos);
                if useLocal
                    [dotImage, nc, nd] = addDotsLocal(base,dotA(pos),localT(k,pos));
                    design.images.(name) = dotImage;
                    nClipped = nClipped + nc; nDarker = nDarker + nd;
                else
                    design.images.(name) = addDots(base,dotA{pos},dotAC{pos},thisDotContrast,rawMean,design.defaultLuminance);
                end
                design.masks.(name) = [];
            end

            % Unique two-dot variants; reversed names share the same image.
            for p = 1:size(validPairs,1)
                pos1 = validPairs(p,1);
                pos2 = validPairs(p,2);
                name = sprintf('%s_dots_%d_%d',baseName,pos1,pos2);
                reverseName = sprintf('%s_dots_%d_%d',baseName,pos2,pos1);

                if useLocal
                    [adjusted, nc, nd] = addDotsLocal(base,dotA([pos1 pos2]),localT(k,[pos1 pos2]));
                    nClipped = nClipped + nc; nDarker = nDarker + nd;
                else
                    [A,AC] = combineDots(dotA{pos1},dotAC{pos1},dotA{pos2},dotAC{pos2});
                    adjusted = addDots(base,A,AC,thisDotContrast,rawMean,design.defaultLuminance);
                end

                design.images.(name) = adjusted;
                design.masks.(name) = [];
                design.images.(reverseName) = design.images.(name);
                design.masks.(reverseName) = design.masks.(name);
            end
        end
    end

    % [changed 2026-11-06] a negative fixDotLocalWeber gives dark dots: clipping at 0 / 255 is
    % counted both ways, and "against the dot" = got darker (light dot) or brighter (dark dot)
    if useLocal && nClipped > 0
        warning('getContrastAdjustedImages:localDotClipped', ...
            '''local'' fixation dots: %d pixels clipped at 0 or 255 (smaller |fixDotLocalWeber| or fixDotLocalMaskGain).', nClipped);
    end
    if useLocal && nDarker > 0
        warning('getContrastAdjustedImages:localDotDarker', ...
            ['''local'' fixation dots: %d pixels under a dot changed against the dot''s direction (light dot: got ' ...
            'darker, dark dot: got brighter), i.e. |Weber value| too low for that spot.'], nDarker);
    end

    % Catch images (report condition), contrast-calibrated per eye
    design = addCatchImages(ptb,design,myPaths,cap,captureRect,rawImages, ...
        stimulusContrasts,eyeContrasts,eyeNames);
catch ME
    Screen('Close',[originalTextures cap]);
    rethrow(ME);
end

Screen('Close',[originalTextures cap]);
end


function image = captureStimulus(win,source,design,captureRect,dotPositions,fixTexture,dotTransparency,bgColor)
% Capture stimulus with zero, one, or multiple fixation dots (win: offscreen window).
% bgColor in the window's colour range (0-1 with PsychDefaultSetup(2), i.e.
% ptb.grey = 0.5 = 128 of 255; a value of 128 would be clamped to white).
Screen('FillRect',win,bgColor);
Screen('DrawTexture',win,source,[],design.destinationRect);

for k = 1:numel(dotPositions)
    pos = dotPositions(k);
    Screen('DrawTexture',win,fixTexture,[],design.fixDotTextureRects(:,pos),[],[],dotTransparency);
end

image = uint8(Screen('GetImage',win,captureRect));
end


function [dotA, dotAC] = captureDotLayers(ptb,win,design,captureRect,nPositions,fixTexture,dotTransparency)
% Draw the dot texture over black and over white and read back:
%   over black: A*C          over white: (1-A)*255 + A*C
% -> opacity A (0-1) and premultiplied colour A*C (0-255), single channel.
dotA = cell(1,nPositions); dotAC = cell(1,nPositions);
for pos = 1:nPositions
    Screen('FillRect',win,ptb.black,captureRect);
    Screen('DrawTexture',win,fixTexture,[],design.fixDotTextureRects(:,pos),[],[],dotTransparency);
    cap0 = double(Screen('GetImage',win,captureRect));
    Screen('FillRect',win,ptb.white,captureRect);
    Screen('DrawTexture',win,fixTexture,[],design.fixDotTextureRects(:,pos),[],[],dotTransparency);
    cap1 = double(Screen('GetImage',win,captureRect));
    dotA{pos}  = min(max(1 - (cap1(:,:,1) - cap0(:,:,1)) / 255, 0), 1);
    dotAC{pos} = cap0(:,:,1);
end
% leave the capture region as background grey for the stimulus captures
Screen('FillRect',win,ptb.grey,captureRect);
end


function [A, AC] = combineDots(A1,AC1,A2,AC2)
% dot 2 composited over dot 1 (premultiplied alpha)
A  = A1 + A2 - A1.*A2;
AC = AC2 + (1 - A2).*AC1;
end


function out = addDots(base,A,AC,dotContrast,rawMean,targetLuminance)
% (1-A).*base + A.*((C - rawMean)*dotContrast + targetLuminance), with A.*C = AC
S = double(base);
A = repmat(A,[1 1 size(S,3)]); AC = repmat(AC,[1 1 size(S,3)]);
out = (1 - A).*S + dotContrast*(AC - A*rawMean) + A*targetLuminance;
out = uint8(round(min(max(out,0),255)));
end


function [out, nClipped, nDarker] = addDotsLocal(base,As,Ts)
% [added 2026-11-05] 'local' mode: each dot blended towards its own grey level
% T (generate.localDotTargets): out = (1-A).*image + A.*T, dots one after the
% other (premultiplied 'over', as combineDots for two dots of one colour)
S = double(base);
for i = 1:numel(As)
    A = repmat(As{i},[1 1 size(S,3)]);
    S = (1 - A).*S + A.*Ts(i);
end
nClipped = sum(S(:) > 255.5 | S(:) < -0.5) / size(S,3);   % [changed 2026-11-06] also at 0 (dark dots)
out = uint8(round(min(max(S,0),255)));
d = double(out(:)) - double(base(:));
dotSign = sign(sum(d));                                     % +1 light dot, -1 dark dot
nDarker = sum(sign(d) == -dotSign & d ~= 0) / size(S,3);    % pixels changed against the dot's direction
end


function output = applyContrast(input,contrast,targetLuminance,refMask)
% (input - m) * contrast + targetLuminance, m = mean over refMask
% (generate.contrastReferenceMask; whole image without refMask). Identical
% to questplus.applyContrast. [changed 2026-11-10: refMask]
pixels = double(input);
if nargin < 4 || isempty(refMask)
    imageMean = mean(pixels(:));
else
    p1 = pixels(:,:,1);
    imageMean = mean(p1(refMask));
end
output = uint8(round(min(max((pixels-imageMean).*contrast+targetLuminance,0),255)));
end


function design = addCatchImages(ptb,design,myPaths,cap,captureRect,rawImages,stimulusContrasts,eyeContrasts,eyeNames) %#ok<INUSD>
% Report-condition catch images built from the subject's rivalry textures.
% For each catch file (catch_houseface.png, catch_facehouse.png; e.g. the 45
% and 135 deg patch versions) two images are made, one per texture pairing of
% a rivalry trial:
%   <label>HouseLFaceR : house parts = houseL texture, face parts = faceR texture
%   <label>FaceLHouseR : face parts  = faceL texture,  house parts = houseR texture
% (label = 'houseface' / 'facehouse'), so 4 catch images in total. The same
% image is shown to both eyes (mock rivalry). With <file>_weights.png
% (createFMRIStimuli: R = house weight, G = face weight) the catch is
%   lum + wHouse .* (houseTexture - lum) + wFace .* (faceTexture - lum),
% i.e. pixel-identical to the texture wherever the weight is 1. Without a
% (matching) weights file: the whole catch image gets one contrast, the
% geometric mean of the two textures' contrasts (warning).
catchList = {'houseface','catch_houseface'; 'facehouse','catch_facehouse'};
% {suffix, house texture, face texture, house contrast index (eye), face contrast index (eye)}
pairings  = {'HouseLFaceR','houseL','faceR',1,2; 'FaceLHouseR','houseR','faceL',2,1};
lum = design.defaultLuminance;
cHouse = stimulusContrasts(1); cFace = stimulusContrasts(2);
for k = 1:size(catchList,1)
    catchFile = fullfile(myPaths.stimuliLocation,[catchList{k,2} '.png']);
    if ~isfile(catchFile); continue; end
    tex = makeTextureFromFile(ptb,catchFile);
    rawCatch = captureStimulus(cap,tex,design,captureRect,[],[],[],ptb.grey);
    Screen('Close',tex);

    useWeights = false;
    weightFile = fullfile(myPaths.stimuliLocation,[catchList{k,2} '_weights.png']);
    if isfile(weightFile)
        wImg = imread(weightFile);
        if ndims(wImg) == 2, wImg = repmat(wImg,[1 1 3]); end
        tex = Screen('MakeTexture',ptb.window,wImg(:,:,1:3));
        wCap = captureStimulus(cap,tex,design,captureRect,[],[],[],ptb.black);   % weight 0 outside the image
        Screen('Close',tex);
        wH = double(wCap(:,:,1)) / 255;
        wF = double(wCap(:,:,2)) / 255;
        % check that the weights belong to this catch image and house.png/face.png:
        % catch - lum ~ gain * (wH*dH + wF*dF) + offset * (wH + wF)
        dH = double(rawImages{1}(:,:,1)) - mean(double(rawImages{1}(:)));
        dF = double(rawImages{2}(:,:,1)) - mean(double(rawImages{2}(:)));
        c = double(rawCatch(:,:,1)) - lum;
        X = [reshape(wH.*dH + wF.*dF,[],1), reshape(wH + wF,[],1)];
        beta = X \ c(:);
        R2 = 1 - sum((c(:) - X*beta).^2) / max(sum((c(:) - mean(c(:))).^2), eps);
        if R2 >= 0.9
            useWeights = true;
            fprintf('Catch image %s: built from the rivalry textures (weights match the catch PNG, R^2 %.3f)\n', catchList{k,2}, R2);
        else
            warning('getContrastAdjustedImages:catchWeights', ...
                ['%s does not match %s and house.png/face.png (R^2 = %.2f); ' ...
                'using one contrast for the whole catch image.'], weightFile, catchFile, R2);
        end
    else
        warning('getContrastAdjustedImages:noCatchWeights', ...
            ['No %s: the catch image gets one contrast (geometric mean of the two textures) instead of ' ...
            'house/face parts identical to the textures (re-run createFMRIStimuli for the weights file).'], weightFile);
    end

    for p = 1:size(pairings,1)
        name = [catchList{k,1} pairings{p,1}];
        if useWeights
            houseTex = double(design.images.(pairings{p,2})(:,:,1));
            faceTex  = double(design.images.(pairings{p,3})(:,:,1));
            img = lum + wH .* (houseTex - lum) + wF .* (faceTex - lum);
            img = uint8(round(min(max(img,0),255)));
            design.images.(name) = repmat(img,[1 1 3]);
        else
            cH = cHouse * eyeContrasts(pairings{p,4});
            cF = cFace  * eyeContrasts(pairings{p,5});
            design.images.(name) = applyContrast(rawCatch,sqrt(cH*cF),lum,generate.contrastReferenceMask(rawCatch,design));
        end
        design.masks.(name) = [];
    end
end
end


function tex = makeTextureFromFile(ptb,filename)
[img,~,alpha] = imread(filename);
if ndims(img) == 2, img = repmat(img,[1 1 3]); end
if ~isempty(alpha), img = cat(3,img,alpha); end
tex = Screen('MakeTexture',ptb.window,img);
end
