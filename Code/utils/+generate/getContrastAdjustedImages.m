function design = getContrastAdjustedImages(ptb, design, stimuliParameters, myPaths, fixTexture, dotTransparency)
% Generate contrast-adjusted stimulus images and masks.
% Creates base, single-dot, and valid two-dot variants.
% Reversed two-dot names reference the same generated image.

eyeNames = {'L','R'};
eyeContrasts = [stimuliParameters.leftEyeContrast, stimuliParameters.rightEyeContrast];
stimulusNames = {'house','face'};
stimulusContrasts = [stimuliParameters.houseContrast, stimuliParameters.faceContrast];

validPairs = unique(sort(design.fixDotValidPairs,2),'rows');
dest = design.destinationRect;
captureRect = [floor(dest(1)), floor(dest(2)), ceil(dest(3)), ceil(dest(4))];
nPositions = size(design.fixDotPositions,1);
originalTextures = zeros(1,numel(stimulusNames));

% Load source images.
for s = 1:numel(stimulusNames)
    filename = fullfile(myPaths.stimuliLocation,[stimulusNames{s} '.png']);
    assert(isfile(filename),'Stimulus file does not exist: %s',filename);
    [img,~,alpha] = imread(filename);
    if ndims(img) == 2, img = repmat(img,[1 1 3]); end
    if ~isempty(alpha), img = cat(3,img,alpha); end
    originalTextures(s) = Screen('MakeTexture',ptb.window,img);
end

try
    for e = 1:numel(eyeNames)
        selectBuffer(ptb,e);
        eyeName = eyeNames{e};

        for s = 1:numel(stimulusNames)
            baseName = [stimulusNames{s} eyeName];
            contrast = stimulusContrasts(s)*eyeContrasts(e);
            source = originalTextures(s);

            % Base image, without fixation dots.
            raw = captureStimulus(ptb,source,design,captureRect,[],fixTexture,dotTransparency);
            design.images.(baseName) = applyContrast(raw,contrast,design.defaultLuminance);
            design.masks.(baseName) = [];

            % Single-dot variants.
            for pos = 1:nPositions
                name = sprintf('%s_dot_%d',baseName,pos);
                raw = captureStimulus(ptb,source,design,captureRect,pos,fixTexture,dotTransparency);
                design.images.(name) = applyContrast(raw,contrast,design.defaultLuminance);
                design.masks.(name) = [];
            end

            % Unique two-dot variants; reversed names share the same image.
            for p = 1:size(validPairs,1)
                pos1 = validPairs(p,1);
                pos2 = validPairs(p,2);
                name = sprintf('%s_dots_%d_%d',baseName,pos1,pos2);
                reverseName = sprintf('%s_dots_%d_%d',baseName,pos2,pos1);

                raw = captureStimulus(ptb,source,design,captureRect,[pos1 pos2],fixTexture,dotTransparency);
                adjusted = applyContrast(raw,contrast,design.defaultLuminance);

                design.images.(name) = adjusted;
                design.masks.(name) = [];
                design.images.(reverseName) = design.images.(name);
                design.masks.(reverseName) = design.masks.(name);
            end
        end
    end
catch ME
    Screen('Close',originalTextures);
    Screen('SelectStereoDrawBuffer',ptb.window,ptb.leftBuffer);
    rethrow(ME);
end

Screen('Close',originalTextures);
Screen('SelectStereoDrawBuffer',ptb.window,ptb.leftBuffer);
end


function image = captureStimulus(ptb,source,design,captureRect,dotPositions,fixTexture,dotTransparency)
% Capture stimulus with zero, one, or multiple fixation dots.
Screen('DrawTexture',ptb.window,source,[],design.destinationRect);

for k = 1:numel(dotPositions)
    pos = dotPositions(k);
    Screen('DrawTexture',ptb.window,fixTexture,[],design.fixDotTextureRects(:,pos),[],[],dotTransparency);
end

Screen('DrawingFinished',ptb.window);
image = uint8(Screen('GetImage',ptb.window,captureRect,'drawBuffer'));
end


function output = applyContrast(input,contrast,targetLuminance)
pixels = double(input);
imageMean = mean(pixels(:));
output = uint8(round(min(max((pixels-imageMean).*contrast+targetLuminance,0),255)));
end


function selectBuffer(ptb,eyeIndex)
if eyeIndex == 1
    Screen('SelectStereoDrawBuffer',ptb.window,ptb.leftBuffer);
else
    Screen('SelectStereoDrawBuffer',ptb.window,ptb.rightBuffer);
end
end