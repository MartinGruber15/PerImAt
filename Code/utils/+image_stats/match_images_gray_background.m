%% match_images_gray_background.m
%
% Removes magenta/pink background from house and face images,
% replaces it with 50% gray, and matches the foreground images
% in luminance and RMS contrast.
%
% Output:
%   house_matched.png
%   face_matched.png

clear;
close all;
clc;

%% ---------------- PARAMETERS ------------------------------------------

backgroundGray = 128;       % 50% gray on 0-255 scale
pinkColor = [255 0 255];    % Magenta background

outputFolder = 'matched_images';

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% ---------------- LOAD IMAGES -----------------------------------------

house = imread(fullfile('house.png'));
face  = imread(fullfile('face.png'));

% Convert to RGB if necessary
if size(house,3) == 1
    house = repmat(house, [1 1 3]);
end

if size(face,3) == 1
    face = repmat(face, [1 1 3]);
end

%% ---------------- FIND BACKGROUND -------------------------------------

houseBackground = ...
    house(:,:,1) == pinkColor(1) & ...
    house(:,:,2) == pinkColor(2) & ...
    house(:,:,3) == pinkColor(3);

faceBackground = ...
    face(:,:,1) == pinkColor(1) & ...
    face(:,:,2) == pinkColor(2) & ...
    face(:,:,3) == pinkColor(3);

% Foreground masks
houseForeground = ~houseBackground;
faceForeground  = ~faceBackground;

%% ---------------- CONVERT TO GRAYSCALE -------------------------------

houseGray = rgb2gray(house);
faceGray  = rgb2gray(face);

houseGray = double(houseGray);
faceGray  = double(faceGray);

%% ---------------- CALCULATE ORIGINAL STATS ----------------------------

housePixels = houseGray(houseForeground);
facePixels  = faceGray(faceForeground);

houseMean = mean(housePixels);
faceMean  = mean(facePixels);

% RMS contrast = standard deviation / mean
% Here we calculate Michelson-independent RMS contrast in the
% conventional Weber-normalized form.
houseRMS = std(housePixels) / houseMean;
faceRMS  = std(facePixels) / faceMean;

fprintf('\nOriginal image statistics:\n');
fprintf('House: mean = %.2f, RMS contrast = %.4f\n', ...
    houseMean, houseRMS);
fprintf('Face : mean = %.2f, RMS contrast = %.4f\n', ...
    faceMean, faceRMS);

%% ---------------- CHOOSE MATCHING VALUES ------------------------------

% Use the average of house and face.
targetMean = mean([houseMean faceMean]);
targetRMS  = mean([houseRMS faceRMS]);

fprintf('\nTarget values:\n');
fprintf('Mean luminance = %.2f\n', targetMean);
fprintf('RMS contrast   = %.4f\n', targetRMS);

%% ---------------- MATCH HOUSE -----------------------------------------

houseMatched = (houseGray - houseMean);

% First scale the standard deviation to obtain target RMS contrast.
houseMatched = houseMatched * ...
    (targetRMS * targetMean / std(housePixels));

% Then shift the mean to the target luminance.
houseMatched = houseMatched + targetMean;

%% ---------------- MATCH FACE -------------------------------------------

faceMatched = (faceGray - faceMean);

faceMatched = faceMatched * ...
    (targetRMS * targetMean / std(facePixels));

faceMatched = faceMatched + targetMean;

%% ---------------- CLIP VALUES -----------------------------------------

houseMatched = max(0, min(255, houseMatched));
faceMatched  = max(0, min(255, faceMatched));

%% ---------------- ADD GRAY BACKGROUND ---------------------------------

houseOutput = uint8(houseMatched);
faceOutput  = uint8(faceMatched);

% Replace background with 50% gray
houseOutput(~houseForeground) = backgroundGray;
faceOutput(~faceForeground)   = backgroundGray;

%% ---------------- SAVE ------------------------------------------------

imwrite(houseOutput, ...
    fullfile(outputFolder, 'house_matched.png'));

imwrite(faceOutput, ...
    fullfile(outputFolder, 'face_matched.png'));

%% ---------------- CHECK FINAL STATS -----------------------------------

houseFinalPixels = double(houseOutput(houseForeground));
faceFinalPixels  = double(faceOutput(faceForeground));

houseFinalMean = mean(houseFinalPixels);
faceFinalMean  = mean(faceFinalPixels);

houseFinalRMS = std(houseFinalPixels) / houseFinalMean;
faceFinalRMS  = std(faceFinalPixels) / faceFinalMean;

fprintf('\nFinal image statistics:\n');
fprintf('House: mean = %.2f, RMS contrast = %.4f\n', ...
    houseFinalMean, houseFinalRMS);
fprintf('Face : mean = %.2f, RMS contrast = %.4f\n', ...
    faceFinalMean, faceFinalRMS);

fprintf('\nImages saved in: %s\n', outputFolder);
