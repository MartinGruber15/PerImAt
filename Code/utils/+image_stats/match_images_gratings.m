%% create_opposite_gratings.m
%
% Creates house and face stimuli independently from the ORIGINAL images.
%
% HOUSE:
%   - Pink backgr50
% ound is replaced by a Psychtoolbox sine grating
%   - Grating orientation = 45 degrees (////)
%
% FACE:
%   - Pink background is replaced by a Psychtoolbox sine grating
%   - Grating orientation = 135 degrees (\\\\)
%
% The FOREGROUND of the house and face is matched in:
%   1. Mean luminance
%   2. RMS contrast
%
% The grating is only placed in the original pink background.
%
% This follows the grating implementation from the original code:
%   CreateProceduralSineGrating
%   freq = 0.03
%   contrastMultiplier = 0.5
%
% Input:
%   house.png
%   face.png
%
% Output:
%   grating_stimuli/house.png
%   grating_stimuli/face.png

clear;
close all;
clc;

%% ---------------- PARAMETERS ------------------------------------------

outputFolder = 'grating_stimuli';

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Pink/magenta background in original images
pinkColor = [255 0 255];

% Grating parameters -- kept the same as the original code
gratingContrast = 0.45;
gratingFrequency = 0.03;
gratingContrastMultiplier = 0.5;
gratingPhase = 0;
gratingSigma = -1;

% Stimulus size in visual degrees
sizeInDegrees = 4.5;

% Grating orientations
thetaHouse = 45;
thetaFace  = 135;

%% ---------------- INITIALIZE PSYCHTOOLBOX -----------------------------

PsychDefaultSetup(2);

% Select the screen
screenNumber = max(Screen('Screens'));

% Open screen
[window, windowRect] = PsychImaging('OpenWindow', ...
    screenNumber, 128);

% Get screen centre
[xCenter, yCenter] = RectCenter(windowRect);

% Screen resolution
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

fprintf('\nScreen resolution: %d x %d pixels\n', ...
    screenXpixels, screenYpixels);

%% ---------------- GET PIXELS PER DEGREE -------------------------------

% Ask for pixels per degree if it is not already known.
%
% This should ideally be the same value used in your experiment.

pixelsPerDegree = input( ...
    '\nEnter pixels per degree [e.g. 50]: ');

% Stimulus size in pixels
sizeInPixelsX = round(pixelsPerDegree * sizeInDegrees);
sizeInPixelsY = round(pixelsPerDegree * sizeInDegrees);

stimulusRect = [ ...
    xCenter - sizeInPixelsX/2, ...
    yCenter - sizeInPixelsY/2, ...
    xCenter + sizeInPixelsX/2, ...
    yCenter + sizeInPixelsY/2];

fprintf('Stimulus size: %.1f degrees\n', sizeInDegrees);
fprintf('Stimulus size: %d x %d pixels\n', ...
    sizeInPixelsX, sizeInPixelsY);

%% ---------------- LOAD ORIGINAL IMAGES -------------------------------

house = imread('house.png');
face  = imread('face.png');

% Make sure images are RGB
if size(house,3) == 1
    house = repmat(house, [1 1 3]);
end

if size(face,3) == 1
    face = repmat(face, [1 1 3]);
end

%% ---------------- FIND PINK BACKGROUND -------------------------------

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

houseGray = double(rgb2gray(house));
faceGray  = double(rgb2gray(face));

%% ---------------- MATCH FOREGROUND LUMINANCE --------------------------

% ONLY foreground pixels are used here.

housePixels = houseGray(houseForeground);
facePixels  = faceGray(faceForeground);

% Mean luminance
houseMean = mean(housePixels);
faceMean  = mean(facePixels);

% Standard deviation
houseSD = std(housePixels);
faceSD  = std(facePixels);

% RMS contrast
houseRMS = houseSD / houseMean;
faceRMS  = faceSD / faceMean;

fprintf('\nOriginal foreground statistics:\n');

fprintf('House:\n');
fprintf('  Mean luminance = %.2f\n', houseMean);
fprintf('  RMS contrast   = %.4f\n', houseRMS);

fprintf('Face:\n');
fprintf('  Mean luminance = %.2f\n', faceMean);
fprintf('  RMS contrast   = %.4f\n', faceRMS);

%% ---------------- DEFINE COMMON TARGET -------------------------------

% Match both foregrounds to the average of the two.

targetMean = mean([houseMean faceMean]);
targetRMS  = mean([houseRMS faceRMS]);

fprintf('\nTarget foreground values:\n');
fprintf('  Mean luminance = %.2f\n', targetMean);
fprintf('  RMS contrast   = %.4f\n', targetRMS);

%% ---------------- MATCH HOUSE FOREGROUND ------------------------------

houseMatched = houseGray - houseMean;

houseMatched = houseMatched * ...
    (targetRMS * targetMean / houseSD);

houseMatched = houseMatched + targetMean;

%% ---------------- MATCH FACE FOREGROUND -------------------------------

faceMatched = faceGray - faceMean;

faceMatched = faceMatched * ...
    (targetRMS * targetMean / faceSD);

faceMatched = faceMatched + targetMean;

%% ---------------- CLIP FOREGROUND -------------------------------------

houseMatched = max(0, min(255, houseMatched));
faceMatched  = max(0, min(255, faceMatched));

%% ---------------- CREATE PSYCHTOOLBOX GRATING -------------------------

% This is deliberately kept very close to your original code.
%
% In particular:
%
%   freq = 0.03
%   contrastMultiplier = 0.5
%   contrast = 0.45
%
% We are NOT converting 0.03 into cycles/degree.

gratingBackground = targetMean / 255;

[gratingID, gratingRect] = CreateProceduralSineGrating( ...
    window, ...
    sizeInPixelsX, ...
    sizeInPixelsY, ...
    [gratingBackground, gratingBackground, gratingBackground, 1], ...
    [], ...
    gratingContrastMultiplier);

%% ---------------- CREATE HOUSE STIMULUS -------------------------------

% Create an offscreen window with the target mean luminance.
[offscreenHouse, ~] = Screen('OpenOffscreenWindow', ...
    screenNumber, targetMean);

% Fill with target luminance
Screen('FillRect', offscreenHouse, targetMean);

% Draw the 45-degree grating.
Screen('DrawTexture', ...
    offscreenHouse, ...
    gratingID, ...
    [], ...
    stimulusRect, ...
    thetaHouse, ...
    [], ...
    [], ...
    [], ...
    [], ...
    [], ...
    [gratingPhase, gratingFrequency, ...
     gratingContrast, gratingSigma]);

%% ---------------- CREATE HOUSE FOREGROUND TEXTURE ---------------------

% Convert matched house to uint8
houseMatchedUint8 = uint8(houseMatched);

% Alpha channel:
%   foreground = 255
%   original pink background = 0

houseAlpha = uint8(houseForeground * 255);

houseRGBA = cat(3, ...
    houseMatchedUint8, ...
    houseAlpha);

% Make texture
houseTexture = Screen('MakeTexture', window, houseRGBA);

% Enable alpha blending
Screen('BlendFunction', ...
    offscreenHouse, ...
    GL_SRC_ALPHA, ...
    GL_ONE_MINUS_SRC_ALPHA);

% Draw matched house over the grating.
% Pink pixels remain transparent, so the grating shows through.

Screen('DrawTexture', ...
    offscreenHouse, ...
    houseTexture, ...
    [], ...
    stimulusRect);

%% ---------------- GET HOUSE IMAGE -------------------------------------

houseStimulus = Screen('GetImage', ...
    offscreenHouse, ...
    stimulusRect, ...
    [], ...
    [], ...
    3);

%% ---------------- CREATE FACE STIMULUS --------------------------------

[offscreenFace, ~] = Screen('OpenOffscreenWindow', ...
    screenNumber, targetMean);

Screen('FillRect', offscreenFace, targetMean);

% Draw the 135-degree grating.
Screen('DrawTexture', ...
    offscreenFace, ...
    gratingID, ...
    [], ...
    stimulusRect, ...
    thetaFace, ...
    [], ...
    [], ...
    [], ...
    [], ...
    [], ...
    [gratingPhase, gratingFrequency, ...
     gratingContrast, gratingSigma]);

%% ---------------- CREATE FACE FOREGROUND TEXTURE ----------------------

faceMatchedUint8 = uint8(faceMatched);

faceAlpha = uint8(faceForeground * 255);

faceRGBA = cat(3, ...
    faceMatchedUint8, ...
    faceAlpha);

faceTexture = Screen('MakeTexture', window, faceRGBA);

Screen('BlendFunction', ...
    offscreenFace, ...
    GL_SRC_ALPHA, ...
    GL_ONE_MINUS_SRC_ALPHA);

Screen('DrawTexture', ...
    offscreenFace, ...
    faceTexture, ...
    [], ...
    stimulusRect);

%% ---------------- GET FACE IMAGE --------------------------------------

faceStimulus = Screen('GetImage', ...
    offscreenFace, ...
    stimulusRect, ...
    [], ...
    [], ...
    3);

%% ---------------- SAVE ------------------------------------------------

imwrite(houseStimulus, ...
    fullfile(outputFolder, 'house.png'));

imwrite(faceStimulus, ...
    fullfile(outputFolder, 'face.png'));

%% ---------------- CHECK FINAL FOREGROUND ------------------------------

% The GetImage output corresponds to the stimulus rectangle, so the
% original foreground mask is used only for reporting the matched
% foreground statistics.

houseFinalPixels = double(houseMatched(houseForeground));
faceFinalPixels  = double(faceMatched(faceForeground));

houseFinalMean = mean(houseFinalPixels);
faceFinalMean  = mean(faceFinalPixels);

houseFinalRMS = std(houseFinalPixels) / houseFinalMean;
faceFinalRMS  = std(faceFinalPixels) / faceFinalMean;

fprintf('\nFinal foreground statistics:\n');

fprintf('House:\n');
fprintf('  Mean luminance = %.2f\n', houseFinalMean);
fprintf('  RMS contrast   = %.4f\n', houseFinalRMS);

fprintf('Face:\n');
fprintf('  Mean luminance = %.2f\n', faceFinalMean);
fprintf('  RMS contrast   = %.4f\n', faceFinalRMS);

%% ---------------- DISPLAY STIMULI -------------------------------------

figure('Color','white');

subplot(1,2,1);
imshow(houseStimulus);
title('House + 45% grating (////)');

subplot(1,2,2);
imshow(faceStimulus);
title('Face + 45% grating (\\\\)');

%% ---------------- CLEAN UP --------------------------------------------

Screen('Close', houseTexture);
Screen('Close', faceTexture);
Screen('Close', gratingID);

Screen('Close', offscreenHouse);
Screen('Close', offscreenFace);

sca;

fprintf('\nStimuli saved in: %s\n', outputFolder);
fprintf('Grating contrast: %.0f%%\n', gratingContrast * 100);
fprintf('Grating frequency parameter: %.2f\n', gratingFrequency);
fprintf('House orientation: %d degrees\n', thetaHouse);
fprintf('Face orientation: %d degrees\n', thetaFace);
