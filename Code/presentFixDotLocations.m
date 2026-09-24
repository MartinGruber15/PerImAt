function presentFixDotLocations(ptb, design, imagePath)

image1 = loadImage(imagePath, 'house');
image2 = loadImage(imagePath, 'face');

% Randomly determine which image is shown first
if rand < 0.5
    images = {image1, image2};
else
    images = {image2, image1};
end

% Loop over both images
for imgIdx = 1:2
    image = images{imgIdx};
    % Present the image at every valid fixation-dot position
    for i = 1:size(design.fixDotPositions, 1)
        selectedPair = [i i];
        draw.stereo.imagesNoReport(ptb,design,image,image,selectedPair,design.fixDotTransparency);
        % Keep this presentation for 3 seconds
        Screen('Flip',ptb.window);
        WaitSecs(3);
    end
end
Screen('CloseAll')
end

function img = loadImage(folder, name)
filename = fullfile(folder, name + ".png");
info = imfinfo(filename);
img = imread(filename);
if isfield(info, 'Transparency')
    alpha = info.Transparency;
else
    alpha = [];
end
end