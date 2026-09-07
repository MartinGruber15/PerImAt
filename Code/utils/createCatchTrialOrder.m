function catchTable = createCatchTrialOrder(outputDirectory, nRuns, outputname, seed)

if nargin < 2 || isempty(nRuns), nRuns = 10; end
if nargin < 3 || isempty(outputname), outputname = "catchTrialOrder.csv"; end
if nargin < 4, seed = []; end
if ~isempty(seed), rng(seed); end

conditions = ["imagery"; "perception"; "attention"];
cues      = ["face"; "house"];
stimuli   = ["face"; "house"; "facehouse"; "houseface"];

% Desired cue/stimulus combinations
pairs = [
    1 1    % face  + face
    1 2    % face  + house
    2 1    % house + face
    2 2    % house + house
    1 3    % face  + facehouse
    2 4    % house + houseface
];

% Construct six catches for each main condition
main = table();

for c = 1:numel(conditions)
    % Randomly decide which composite stimulus goes with which cue
    if rand < 0.5
        pairsThisCondition = pairs;
    else
        pairsThisCondition = pairs;
        pairsThisCondition(5:6,2) = pairsThisCondition([6 5],2);
    end
    T = table( ...
        repmat(conditions(c), size(pairsThisCondition,1), 1), ...
        cues(pairsThisCondition(:,1)), ...
        stimuli(pairsThisCondition(:,2)), ...
        'VariableNames', {'condition','cue','stimulus'});
    main = [main; T];
end

% Baseline
baseline = table( ...
    repmat("baseline", 2, 1), ...
    cues, ...
    cues, ...
    'VariableNames', {'condition','cue','stimulus'});

% Combine, shuffle, assign runs
catchTable = [main; baseline];
catchTable = catchTable(randperm(height(catchTable)), :);

catchTable.run = repelem((1:nRuns)', 2);
catchTable = movevars(catchTable, 'run', 'Before', 1);

writetable(catchTable, fullfile(outputDirectory, outputname));
end
