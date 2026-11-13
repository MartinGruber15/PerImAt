function [stimuliParameters, latestFile] = loadLatestTrainingParameters(path, askIfMissing)
% loadLatestTrainingParameters  Contrasts of the latest <sub>_training_<n>.mat.
%
%   [stimuliParameters, latestFile] = loadLatestTrainingParameters(path)
%   [stimuliParameters, latestFile] = loadLatestTrainingParameters(path, true)
%
% latestFile: training file the parameters were loaded from ('' = defaults or
% values entered by hand).
% [changed 2026-11-11] askIfMissing = true is now only used by main.m
% (confirmUncalibratedContrasts: main experiment, training, fixDot practice or
% QUEST+ test chosen without a training file, key m); getVisualDesignSettings
% calls it with false. [2026-11-06] askIfMissing = true: if the subject has no training file yet, the experimenter is
% asked to enter the four contrasts (house, face, left eye, right eye; Enter keeps
% [1.0000]) and confirms them with Enter; they can be saved as
% <sub>_training_<n>.mat. Default false: defaults (all 1) without asking, as before
% (input.adaptStimuli, questPlusCalibration, tests).
if nargin < 2 || isempty(askIfMissing); askIfMissing = false; end
latestFile = '';
% Find all training parameter files
pattern = fullfile(path, '*_training_*.mat');
files = dir(pattern);
if isempty(files)
    stimuliParameters.houseContrast  = 1;
    stimuliParameters.faceContrast  = 1;
    stimuliParameters.leftEyeContrast  = 1;
    stimuliParameters.rightEyeContrast = 1;
    if askIfMissing
        [stimuliParameters, latestFile] = askContrasts(path, stimuliParameters);
    else
        fprintf('Contrasts: no training file yet -> defaults (house, face, left eye, right eye = 1).\n');
    end
    return;
end
trainingNumbers = zeros(length(files), 1);
for i = 1:length(files)
    parts = split(files(i).name, '_');
    trainingNumbers(i) = str2double(erase(parts{end}, '.mat'));
end
% Find newest training file
[~, index] = max(trainingNumbers);
latestFile = fullfile(path, files(index).name);
loaded = load(latestFile, 'stimuliParameters');
stimuliParameters = loaded.stimuliParameters;
% Files saved before eye-specific contrast existed: neutral default
if ~isfield(stimuliParameters,'leftEyeContrast');  stimuliParameters.leftEyeContrast  = 1; end
if ~isfield(stimuliParameters,'rightEyeContrast'); stimuliParameters.rightEyeContrast = 1; end
% Files saved while a configuration contrast existed: that field is no longer used
if isfield(stimuliParameters,'configContrast')
    if abs(stimuliParameters.configContrast - 1) > 0.005
        fprintf(2, 'NOTE: this training file contains configContrast = %.4f; it is no longer used and is ignored.\n', stimuliParameters.configContrast);
    end
    stimuliParameters = rmfield(stimuliParameters, 'configContrast');
end
[~, fName, fExt] = fileparts(latestFile);
fprintf('Contrasts from %s: house %.4f, face %.4f | left eye %.4f, right eye %.4f\n', [fName fExt], ...
    stimuliParameters.houseContrast, stimuliParameters.faceContrast, ...
    stimuliParameters.leftEyeContrast, stimuliParameters.rightEyeContrast);
end


function [sp, savedFile] = askContrasts(path, sp)
% [added 2026-11-06] no training file: the experimenter enters the contrasts
savedFile = '';
fprintf(2, '\nNo training file (<sub>_training_<n>.mat) in %s.\n', path);
fprintf('Enter the contrasts by hand (texture contrast = stimulus x eye; Enter keeps [value]).\n');   % [changed 2026-11-11]
while true
    sp.houseContrast    = inputWithDefault('House contrast', sp.houseContrast);
    sp.faceContrast     = inputWithDefault('Face contrast', sp.faceContrast);
    sp.leftEyeContrast  = inputWithDefault('Left eye contrast (x stimulus contrast)', sp.leftEyeContrast);
    sp.rightEyeContrast = inputWithDefault('Right eye contrast (x stimulus contrast)', sp.rightEyeContrast);
    fprintf('-> house %.4f  face %.4f | left eye %.4f  right eye %.4f\n', ...
        sp.houseContrast, sp.faceContrast, sp.leftEyeContrast, sp.rightEyeContrast);
    fprintf('   textures HouseL %.4f  FaceR %.4f | FaceL %.4f  HouseR %.4f\n', ...
        sp.houseContrast * sp.leftEyeContrast, sp.faceContrast * sp.rightEyeContrast, ...
        sp.faceContrast * sp.leftEyeContrast, sp.houseContrast * sp.rightEyeContrast);
    a = strtrim(input('Press Enter to use these contrasts (n = enter them again): ', 's'));
    if isempty(a) || strcmpi(a, 'y'); break; end
    if ~strcmpi(a, 'n'); fprintf('Please press Enter or type n.\n'); end
end
sp.manualEntry = true;
% save as training file so that the next start (and the QUEST+ test) uses them
[~, folder] = fileparts(path);
tok = regexp(folder, '^sub-(.+)$', 'tokens', 'once');
if isempty(tok)
    fprintf('Contrasts used for this start only (folder name is not sub-<ID>, not saved).\n');
    return
end
a = strtrim(lower(input(sprintf('Save them as %s_training_1.mat for the next starts? (y / Enter = no): ', tok{1}), 's')));
if strcmp(a, 'y')
    stimuliParameters = sp; %#ok<NASGU>
    % [fixed 2026-11-06] a new subject has no folder yet at this point (main.m creates
    % it later, in getParticipantInfo): create it here, otherwise save fails
    if ~isfolder(path); mkdir(path); end
    savedFile = fullfile(path, sprintf('%s_training_1.mat', tok{1}));
    save(savedFile, 'stimuliParameters');
    fprintf('Contrasts saved to %s\n', savedFile);
else
    fprintf('Contrasts used for this start only (not saved).\n');
end
end


function value = inputWithDefault(prompt, defaultValue)
while true
    str = strtrim(input(sprintf('%s [%.4f]: ', prompt, defaultValue), 's'));
    if isempty(str); value = defaultValue; return; end
    value = str2double(str);
    if ~isnan(value) && isscalar(value) && value > 0; return; end
    fprintf('Invalid input. Please enter a positive number.\n');
end
end
