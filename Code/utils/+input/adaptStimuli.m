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
    fprintf('\nThe values below are the OPTIMISED parameters (press Enter to keep them).\n');
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
    fprintf('\n');
    fprintf('=================================================\n');
    fprintf('        ADAPT TRAINING STIMULUS PARAMETERS\n');
    fprintf('=================================================\n');
    fprintf('\nStimuli\n')
    stimuliParameters.houseContrast = inputWithDefault('House contrast',stimuliParameters.houseContrast);
    stimuliParameters.faceContrast = inputWithDefault('Face contrast',stimuliParameters.faceContrast);

    % Eye-specific contrast (multiplied onto the house/face contrast above)
    fprintf('\nEye-specific contrast (multiplies stimulus contrast):\n');
    stimuliParameters.leftEyeContrast  = inputWithDefault('Left eye contrast',stimuliParameters.leftEyeContrast);
    stimuliParameters.rightEyeContrast = inputWithDefault('Right eye contrast',stimuliParameters.rightEyeContrast);


    %% Display selected parameters
    fprintf('\n---------------------------------------------\n');
    fprintf('Selected parameters:\n');
    fprintf('\nStimuli\n')
    fprintf('  House contrast:  %.4f\n',stimuliParameters.houseContrast);
    fprintf('  Face contrast:  %.4f\n',stimuliParameters.faceContrast);
    fprintf('\nEye (multiplied onto stimulus contrast):\n');
    fprintf('  Left eye contrast:  %.4f\n',stimuliParameters.leftEyeContrast);
    fprintf('  Right eye contrast: %.4f\n',stimuliParameters.rightEyeContrast);
    fprintf('---------------------------------------------\n');
    fprintf('\nResulting contrast per texture (stimulus x eye):\n');
    fprintf('  FaceLeft:   %.4f\n',stimuliParameters.faceContrast  * stimuliParameters.leftEyeContrast);
    fprintf('  FaceRight:  %.4f\n',stimuliParameters.faceContrast  * stimuliParameters.rightEyeContrast);
    fprintf('  HouseLeft:  %.4f\n',stimuliParameters.houseContrast * stimuliParameters.leftEyeContrast);
    fprintf('  HouseRight: %.4f\n',stimuliParameters.houseContrast * stimuliParameters.rightEyeContrast);
    fprintf('---------------------------------------------\n');


    %% Confirm
    while true
        answer = input('\nStart training with these parameters? Y/N: ','s');
        if strcmpi(answer, 'y')
            adaptParameters = false;
            break;
        elseif strcmpi(answer, 'n')
            break;
        else
            fprintf('Invalid input. Please enter Y or N.\n');
        end
    end
end

%% Save parameters

parameterFilename = sprintf('%s_training_%d.mat',log.sub, trainingNumber);
parameterFile = fullfile(myPaths.subjectDirectory, parameterFilename);
save(parameterFile, 'stimuliParameters');
stimuliParameters.parameterFile = parameterFile;
stimuliParameters.trainingNumber = trainingNumber;

fprintf('\nTraining parameters saved to:\n%s\n\n', ...
    parameterFile);

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
