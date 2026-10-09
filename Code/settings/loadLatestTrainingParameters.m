function stimuliParameters = loadLatestTrainingParameters(path)
% Find all training parameter files
pattern = fullfile(path, '*_training_*.mat');
files = dir(pattern);
if isempty(files)
    stimuliParameters.houseLuminance = 128;
    stimuliParameters.houseContrast  = 1;
    stimuliParameters.faceLuminance = 128;
    stimuliParameters.faceContrast  = 1;
    stimuliParameters.leftEyeContrast  = 1;
    stimuliParameters.rightEyeContrast = 1;
    fprintf('\nNo previous training parameters found.\n');
    fprintf('Using default stimulus parameters.\n');
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
fprintf('\nLoaded training parameters from:\n%s\n',latestFile);
fprintf('\n---------------------------------------------\n');
fprintf('Selected parameters:\n');
fprintf('\nHouse:\n');
fprintf('  Luminance: %.4f\n',stimuliParameters.houseLuminance);
fprintf('  Contrast:  %.4f\n',stimuliParameters.houseContrast);
fprintf('\nFace:\n');
fprintf('  Luminance: %.4f\n',stimuliParameters.faceLuminance);
fprintf('  Contrast:  %.4f\n',stimuliParameters.faceContrast);
fprintf('\nEye (multiplied onto stimulus contrast):\n');
fprintf('  Left eye contrast:  %.4f\n',stimuliParameters.leftEyeContrast);
fprintf('  Right eye contrast: %.4f\n',stimuliParameters.rightEyeContrast);
fprintf('---------------------------------------------\n');
end



