function catchTable = createCatchTrialOrder(outputDirectory, nRuns, outputname, report, seed)

if nargin < 2 || isempty(nRuns), nRuns = 10; end
if nargin < 3 || isempty(outputname), outputname = "catchTrialOrder.csv"; end
if nargin < 4 || isempty(report), report = false; end
if nargin < 5, seed = []; end
if ~isempty(seed), rng(seed); end

conditions = ["imagery"; "perception"; "attention"; "baseline"];
cues      = ["face"; "house"];

% Number of trials contributed by each condition
nTrials = [6; 6; 6; 2];

% Create the condition pool
conditionPool = repelem(conditions, nTrials);

% Randomly distribute conditions across runs.
% Each run contains exactly two different conditions.
while true
    conditionPool = conditionPool(randperm(numel(conditionPool)));
    if all(conditionPool(1:2:end) ~= conditionPool(2:2:end))
        break
    end
end

% Assign runs
run = repelem((1:nRuns)', 2);

% Number of trials
nTrialsTotal = numel(conditionPool);

if ~report
    % noReport variant
    %
    % Each trial gets:
    %   - a cue (face/house), except baseline -> "-"
    %   - a left eye stimulus (face/house)
    %   - a right eye stimulus (face/house)
    %   - a catch type (single/double)
    %
    % leftEye and rightEye are always opposite:
    %   face  / house
    %   house / face

    % Initialize cue with "-" so baseline is automatically handled
    cue = repmat("-", nTrialsTotal, 1);

    % Non-baseline trials get a random cue
    nonBaseline = conditionPool ~= "baseline";
    cue(nonBaseline) = cues(randi(numel(cues), sum(nonBaseline), 1));

    % Randomly choose one of the two possible eye configurations
    % 1 = left face, right house
    % 2 = left house, right face
    eyeConfiguration = randi(2, nTrialsTotal, 1);
    leftEye  = strings(nTrialsTotal, 1);
    rightEye = strings(nTrialsTotal, 1);
    leftEye(eyeConfiguration == 1)  = "face";
    rightEye(eyeConfiguration == 1) = "house";
    leftEye(eyeConfiguration == 2)  = "house";
    rightEye(eyeConfiguration == 2) = "face";
    % Randomly choose catch type
    catchType = strings(nTrialsTotal, 1);
    catchType(randi(2, nTrialsTotal, 1) == 1) = "single";
    catchType(catchType == "") = "double";
    % Create table
    catchTable = table(run, conditionPool, cue, leftEye, rightEye, catchType, ...
        'VariableNames', {'run', 'condition', 'cue', ...
                          'leftEye', 'rightEye', 'catchType'});

else
    % Original variant
    stimuli = ["face"; "house"; "facehouse"; "houseface"];
    % Randomly draw cue and stimulus for every trial
    cue = cues(randi(numel(cues), nTrialsTotal, 1));
    stimulus = stimuli(randi(numel(stimuli), nTrialsTotal, 1));
    % Create table
    catchTable = table(run, conditionPool, cue, stimulus, ...
        'VariableNames', {'run', 'condition', 'cue', 'stimulus'});
end

writetable(catchTable, fullfile(outputDirectory, outputname));
end
