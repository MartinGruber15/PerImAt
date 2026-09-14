%% create_superimposed_stimulus.m
%
% Creates a high-precision 50/50 superposition of the final:
%
%   grating_stimuli/house.png
%   grating_stimuli/face.png
%
% Each image contributes exactly 50% to every pixel.
%
% Output:
%   grating_stimuli/house_face_superimposed.png
%
% The images are combined in floating-point precision before being
% converted back to uint8 for saving.

clear;
close all;
clc;

%% ---------------- PARAMETERS ------------------------------------------

inputFolder = 'grating_stimuli';

houseFile = fullfile(inputFolder, 'house.png');
faceFile  = fullfile(inputFolder, 'face.png');

outputFile = fullfile(inputFolder, ...
    'house_face_superimposed.png');

% Equal contribution
weightHouse = 0.5;
weightFace  = 0.5;

%% ---------------- LOAD IMAGES -----------------------------------------

house = imread(houseFile);
face  = imread(faceFile);

%% ---------------- CHECK IMAGE SIZES -----------------------------------

if ~isequal(size(house), size(face))
    error(['House and face images must have identical dimensions. ' ...
           'House is %dx%d, face is %dx%d.'], ...
           size(house,2), size(house,1), ...
           size(face,2), size(face,1));
end

%% ---------------- CHECK IMAGE CHANNELS --------------------------------

if size(house,3) ~= size(face,3)
    error('House and face images must have the same number of channels.');
end

%% ---------------- CONVERT TO DOUBLE -----------------------------------

% Convert before combining.
% For uint8 images this gives values in [0,1].

houseDouble = im2double(house);
faceDouble  = im2double(face);

%% ---------------- 50/50 SUPERPOSITION -------------------------------

% Every pixel receives exactly 50% of the house and 50% of the face.

superimposedDouble = ...
    weightHouse .* houseDouble + ...
    weightFace  .* faceDouble;

%% ---------------- CHECK RANGE -----------------------------------------

% This should already be in [0,1], but keep the check explicit.

if any(superimposedDouble(:) < 0) || ...
   any(superimposedDouble(:) > 1)

    error('Superimposed image contains values outside [0,1].');
end

%% ---------------- CONVERT TO UINT8 ------------------------------------

% Convert only after the floating-point calculation is complete.

superimposed = im2uint8(superimposedDouble);

%% ---------------- SAVE ------------------------------------------------

imwrite(superimposed, outputFile);

%% ---------------- DISPLAY ---------------------------------------------

figure('Color','white');

subplot(1,3,1);
imshow(house);
title('House');

subplot(1,3,2);
imshow(face);
title('Face');

subplot(1,3,3);
imshow(superimposed);
title('50/50 Superposition');

%% ---------------- REPORT ----------------------------------------------

fprintf('\nSuperposition created successfully.\n');
fprintf('House contribution: %.0f%%\n', weightHouse * 100);
fprintf('Face contribution:  %.0f%%\n', weightFace * 100);
fprintf('Output:\n%s\n', outputFile);
