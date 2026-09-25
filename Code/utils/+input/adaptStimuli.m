function stimuliParameters = adaptStimuli(log,myPaths)
% adaptTrainingStimuli
%
% Ask the experimenter for contrast/luminance values and save them to a
% uniquely numbered training configuration file.
%% Defaults

stimuliParameters = loadLatestTrainingParameters(myPaths.subjectDirectory);

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
    % House
    fprintf('\nHouse stimulus:\n');
    stimuliParameters.houseLuminance = inputWithDefault('Luminance',stimuliParameters.houseLuminance);
    stimuliParameters.houseContrast = inputWithDefault('Contrast',stimuliParameters.houseContrast);

    % Face
    fprintf('\nFace stimulus:\n');
    stimuliParameters.faceLuminance = inputWithDefault('Luminance',stimuliParameters.faceLuminance);
    stimuliParameters.faceContrast = inputWithDefault('Contrast',stimuliParameters.faceContrast);

    %% Display selected parameters
    fprintf('\n---------------------------------------------\n');
    fprintf('Selected parameters:\n');
    fprintf('\nHouse:\n');
    fprintf('  Luminance: %.4f\n',stimuliParameters.houseLuminance);
    fprintf('  Contrast:  %.4f\n',stimuliParameters.houseContrast);
    fprintf('\nFace:\n');
    fprintf('  Luminance: %.4f\n',stimuliParameters.faceLuminance);
    fprintf('  Contrast:  %.4f\n',stimuliParameters.faceContrast);
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
