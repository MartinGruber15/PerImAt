function showDotPositions(ptb, design, imagePath)

image1 = loadImage(imagePath, 'house');
image2 = loadImage(imagePath, 'face');

% Loop over both images
draw.stereo.imagesNoReport(ptb,design,image1,image2,design.fixDotValidPairs,design.fixDotTransparency);
% Keep this presentation for 3 seconds
Screen('Flip',ptb.window);

KbWait;
Screen('CLoseAll')
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