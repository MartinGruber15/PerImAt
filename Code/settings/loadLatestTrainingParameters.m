function stimuliParameters = loadLatestTrainingParameters(path)
% Find all training parameter files
pattern = fullfile(path, '*_training_*.mat');
files = dir(pattern);
if isempty(files)
    stimuliParameters.houseLuminance = 128;
    stimuliParameters.houseContrast  = 1;
    stimuliParameters.faceLuminance = 128;
    stimuliParameters.faceContrast  = 1;
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
fprintf('\nLoaded training parameters from:\n%s\n',latestFile);
fprintf('\n---------------------------------------------\n');
fprintf('Selected parameters:\n');
fprintf('\nHouse:\n');
fprintf('  Luminance: %.4f\n',stimuliParameters.houseLuminance);
fprintf('  Contrast:  %.4f\n',stimuliParameters.houseContrast);
fprintf('\nFace:\n');
fprintf('  Luminance: %.4f\n',stimuliParameters.faceLuminance);
fprintf('  Contrast:  %.4f\n',stimuliParameters.faceContrast);
fprintf('---------------------------------------------\n');
end



