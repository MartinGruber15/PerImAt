function stimuliParameters = adaptStimuli(log,myPaths,presetParameters)
% adaptTrainingStimuli
%
% Ask the experimenter for contrast/luminance values and save them to a
% uniquely numbered training configuration file.
%
% adaptStimuli(log,myPaths)                   defaults = latest training file
% adaptStimuli(log,myPaths,presetParameters)  defaults = fields of the struct
%     presetParameters (e.g. the optimised contrasts from speedRunOnset) where
%     given, latest training file for all others.
%% Defaults

stimuliParameters = loadLatestTrainingParameters(myPaths.subjectDirectory);
if nargin >= 3 && ~isempty(presetParameters)
    presetNames = fieldnames(presetParameters);
    for i = 1:numel(presetNames)
        stimuliParameters.(presetNames{i}) = presetParameters.(presetNames{i});
    end
    fprintf('\nThe values in [ ] are the calibrated contrasts: press Enter to keep them.\n');
end


%% Find existing training configuration files
pattern = fullfile(myPaths.subjectDirectory,'*_training_*.mat');
existingFiles = dir(pattern);

% Determine next training number
if isempty(existingFiles)
    trainingNumber = 1;
else
    trainingNumbers = zeros(length(existingFiles), 1);
    for i = 1:length(existingFiles)
        filename = existingFiles(i).name;
        % Extract number from e.g. sub_3_training_4.mat
        tokens = regexp(filename,[regexptranslate('escape', num2str(log.sub)), '_training_(\d+)\.mat$'],'tokens');
        if ~isempty(tokens)
            trainingNumbers(i) = str2double(tokens{1}{1});
        end
    end
    trainingNumber = max(trainingNumbers) + 1;
end

%% Enter parameters
adaptParameters = true;
while adaptParameters
    fprintf('\n=================================================\n');
    fprintf('  CONTRASTS FOR THE NEXT PARTS (Enter keeps [value])\n');
    fprintf('=================================================\n');
    stimuliParameters.houseContrast = inputWithDefault('House contrast',stimuliParameters.houseContrast);
    stimuliParameters.faceContrast = inputWithDefault('Face contrast',stimuliParameters.faceContrast);
    % eye-specific contrast, multiplied onto the house/face contrast
    stimuliParameters.leftEyeContrast  = inputWithDefault('Left eye contrast (x stimulus contrast)',stimuliParameters.leftEyeContrast);
    stimuliParameters.rightEyeContrast = inputWithDefault('Right eye contrast (x stimulus contrast)',stimuliParameters.rightEyeContrast);

    %% Display the resulting texture contrasts
    fprintf('Texture contrasts (stimulus x eye): HouseL %.4f  FaceR %.4f | FaceL %.4f  HouseR %.4f\n', ...
        stimuliParameters.houseContrast * stimuliParameters.leftEyeContrast, ...
        stimuliParameters.faceContrast  * stimuliParameters.rightEyeContrast, ...
        stimuliParameters.faceContrast  * stimuliParameters.leftEyeContrast, ...
        stimuliParameters.houseContrast * stimuliParameters.rightEyeContrast);

    %% Confirm
    % [changed 2026-11-06] Enter saves (was: y); n = enter the values again
    while true
        answer = strtrim(input('Press Enter to save these contrasts (n = enter them again): ','s'));
        if isempty(answer) || strcmpi(answer, 'y')
            adaptParameters = false;
            break;
        elseif strcmpi(answer, 'n')
            break;
        else
            fprintf('Please press Enter (save) or type n.\n');
        end
    end
end

%% Save parameters

parameterFilename = sprintf('%s_training_%d.mat',log.sub, trainingNumber);
parameterFile = fullfile(myPaths.subjectDirectory, parameterFilename);
save(parameterFile, 'stimuliParameters');
stimuliParameters.parameterFile = parameterFile;
stimuliParameters.trainingNumber = trainingNumber;

fprintf('Contrasts saved to %s\n', parameterFile);

end


%% ============================================================
function value = inputWithDefault(prompt, defaultValue)

while true
    str = input(sprintf('%s [%.4f]: ', prompt, defaultValue),'s');

    % Enter = keep current value
    if isempty(str)
        value = defaultValue;
        return;
    end
    value = str2double(str);
    if ~isnan(value) && isscalar(value)
        return;
    end
    fprintf('Invalid input. Please enter a numeric value.\n');
end

end
