function stimuliParameters = adaptStimuli(log, myPaths, presetParameters)
% MOCK of input.adaptStimuli (tests/dryRunCalibration): accepts the preset
% without asking and saves <sub>_training_<n>.mat like the real function.
stimuliParameters = loadLatestTrainingParameters(myPaths.subjectDirectory);
f = fieldnames(presetParameters);
for i = 1:numel(f); stimuliParameters.(f{i}) = presetParameters.(f{i}); end
n = numel(dir(fullfile(myPaths.subjectDirectory, '*_training_*.mat'))) + 1;
save(fullfile(myPaths.subjectDirectory, sprintf('%s_training_%d.mat', log.sub, n)), 'stimuliParameters');
stimuliParameters.trainingNumber = n;
end
