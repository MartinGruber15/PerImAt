function catchTable = createCatchTrialOrder(outputDirectory, nRuns, outputname, seed)

if nargin < 2 || isempty(nRuns), nRuns = 10; end
if nargin < 3 || isempty(outputname), outputname = "catchTrialOrder.csv"; end
if nargin < 4, seed = []; end
if ~isempty(seed), rng(seed); end

conditions = ["imagery"; "perception"; "attention"; "baseline"];
cues      = ["face"; "house"];
stimuli   = ["face"; "house"; "facehouse"; "houseface"];

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

% Randomly draw cue and stimulus for every trial
cue = cues(randi(numel(cues), numel(conditionPool), 1));
stimulus = stimuli(randi(numel(stimuli), numel(conditionPool), 1));

catchTable = table(run,conditionPool,cue,stimulus, ...
    'VariableNames', {'run', 'condition', 'cue', 'stimulus'});

writetable(catchTable, fullfile(outputDirectory, outputname));
end
