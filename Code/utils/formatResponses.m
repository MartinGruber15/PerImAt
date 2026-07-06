function [sortedResultsTable, success] = formatResponses(log,ptb)
%formatResponses: transforms key presses and releases into a table that can
%be written into a csv file for further analyses
%   input:
%       log - strucutre containing button presses and releases with
%       corresponding key IDs 
%       ptb - strucutre containing the meaning of key IDs (i.e., which key
%       ID corresponds to which percept)
%   output:
%       sortedResultsTable - a table sorted along the percep onset. The
%       columns are: Onset, duration, percept, eye the "true color" image
%       was presented to and a column that indicates whether or not we
%       added an artificial key press
%       success - a boolean whether or not everything worked fine
%
%   The function turns key presses and releases into a time series with a
%   temporal resolution of 1ms. From there we transform back into onsets
%   and durations for percepts
%   In case of differing number of key presses than releases, we add an
%   artificial key release at the end

try
    % get rid of keys that are not response keys for the task
    log.data.timeDown   (find(~ismember(log.data.idDown,[ptb.Keys.house ptb.Keys.face]))) = [];
    log.data.timeUp     (find(~ismember(log.data.idUp,  [ptb.Keys.house ptb.Keys.face]))) = [];
    log.data.idDown     (find(~ismember(log.data.idDown,[ptb.Keys.house ptb.Keys.face]))) = [];
    log.data.idUp       (find(~ismember(log.data.idUp,  [ptb.Keys.house ptb.Keys.face]))) = [];

        
    % stuff to save onset, duration and percept in
    percepts        = {};   % which stimulus was perceived
    durations       = [];   % how long was a percept
    onsets          = [];   % when did the percept start
    keyAdded        = [];   % a column of zeros that only has a one in the end if we artificially added a key release


    % for each trial
    for trl = 1:length(log.data.stimOnset)
        % do we add an artificial key release at the end?
        artificialKeyreleases   = false;
        % was there any button pressed during the trial?
        anyButtonPressed        = true;
        %% get key presses during trial
        stimOnset   = log.data.stimOnset(trl);
        stimOffset  = log.data.stimOffset(trl);

        trialKeyTimeDown    = intersect(find(log.data.timeDown >= stimOnset), ...
            find(log.data.timeDown <= stimOffset));
        trialKeyTimeUp      = intersect(find(log.data.timeUp >= stimOnset), ...
            find(log.data.timeUp <= stimOffset));

        % get the actual time and id key presses and releases
        trialTimeDown   = log.data.timeDown(trialKeyTimeDown);
        trialTimeUp     = log.data.timeUp(trialKeyTimeUp);
        trialIdDown     = log.data.idDown(trialKeyTimeDown);
        trialIdUp       = log.data.idUp(trialKeyTimeUp);

        % check if button presses is empty 
        if isempty(trialTimeDown)
            trialIdUp = [];
            trialTimeUp = [];
            anyButtonPressed = false;
        end

        if anyButtonPressed
            %% separate into true color and false color key presses
            % true color
            houseDown   = trialTimeDown(trialIdDown==ptb.Keys.house);
            houseUp     = trialTimeUp(trialIdUp==ptb.Keys.house);
            
            % false color
            faceDown  = trialTimeDown(trialIdDown==ptb.Keys.face);
            faceUp    = trialTimeUp(trialIdUp==ptb.Keys.face);
            % check for inconsisten key presses
            %% first for true color
            % no press, but a release - subject pressed before trial
            % started
            if isempty(houseDown) && ~isempty(houseUp)
                houseUp = [];
            % there are presses and releases - normal case
            elseif ~isempty(houseDown) && ~isempty(houseUp)
                % first release happened before the first press - as in
                % upper condition
                if houseUp(1)<houseDown(1)
                    houseUp(1) = [];
                end
                % more presses than releases - subject kept pressing until
                % the end of the trial
                if length(houseDown)>length(houseUp)
                    houseUp(end+1) = stimOffset;
                    artificialKeyreleases = true;
                end
            % there is a press, but no release - as in upper condition
            elseif ~isempty(houseDown) && isempty(houseUp)
                houseUp(end+1) = stimOffset;
                artificialKeyreleases = true;
            end

            %% second for false color
            % no press, but a release - subject pressed before trial
            % started
            if isempty(faceDown) && ~isempty(faceUp)
                faceUp = [];
            % there are presses and releases - normal case
            elseif ~isempty(faceDown) && ~isempty(faceUp)
                % first release happened before the first press - as in
                % upper condition
                if faceUp(1)<faceDown(1)
                    faceUp(1) = [];
                end
                % more presses than releases - subject kept pressing until
                % the end of the trial
                if length(faceDown)>length(faceUp)
                    faceUp(end+1) = stimOffset;
                    artificialKeyreleases = true;
                end
            % there is a press, but no release - as in upper condition
            elseif ~isempty(faceDown) && isempty(faceUp)
                faceUp(end+1) = stimOffset;
                artificialKeyreleases = true;
            end
            
            % last check: if key presses and key releases are not the same
            % length, something has been gone wrong. However, this should not
            % happen
            if length(houseDown) ~= length(houseUp) || length(faceDown) ~= length(faceUp)
                error('You have a different amount of key releases and presses')
            end
    
            timeVector = stimOnset:0.001:stimOffset;
            houseTimeSeries = zeros(size(timeVector));
            faceTimeSeries = zeros(size(timeVector));
            mixedColorTimeSeries = zeros(size(timeVector));
    
            for i = 1:length(houseDown)
                startIdx = round((houseDown(i) - stimOnset) * 1000);
                endIdx = round((houseUp(i) - stimOnset) * 1000);
    
                houseTimeSeries(startIdx:endIdx) = 1;
            end
    
            for i = 1:length(faceDown)
                startIdx = round((faceDown(i) - stimOnset) * 1000);
                endIdx = round((faceUp(i) - stimOnset) * 1000);
    
                faceTimeSeries(startIdx:endIdx) = 1;
            end
    
            % We separated the two button presses into two time serieses
            % with a resolution of 1ms. It is true for when a corresponding
            % button is pressed and false if it is not pressed.
            % We get the indices where both buttons are pressed AND where
            % no button was pressed and associate them as mixed
            % Here an example:
            % 1111111111111111111100000000000000000000111111111111111111111
            % 0000000000000000000000222222222222222222222000000000000000000
            % 0000000000000000000033000000000000000000333000000000000000000
            % ==
            % 1111111111111111111100000000000000000000000111111111111111111
            % 0000000000000000000000222222222222222222000000000000000000000
            % 0000000000000000000033000000000000000000333000000000000000000

            bothPressed = intersect(find(faceTimeSeries==1),find(houseTimeSeries==1));
            nonePressed = intersect(find(faceTimeSeries==0),find(houseTimeSeries==0));
            mixedColorTimeSeries(bothPressed) = 1;
            mixedColorTimeSeries(nonePressed) = 1;
    
            houseTimeSeries(bothPressed)    = 0;
            faceTimeSeries(bothPressed)   = 0;
    
            % go back from time series to onset - offset arrays
            trueTransitions = diff(houseTimeSeries>0);
            trueOnsetIndices = find(trueTransitions == 1);
            trueOffsetIndices = find(trueTransitions == -1);
            % check if first or last entry in time series is true
            if houseTimeSeries(1)
                trueOnsetIndices = [1 trueOnsetIndices];
            end
            if houseTimeSeries(end)
                trueOffsetIndices = [trueOffsetIndices length(houseTimeSeries)];
            end
            trueOnsets = timeVector(trueOnsetIndices) - log.data.stimOnset(1);
            trueOffsets = timeVector(trueOffsetIndices) - log.data.stimOnset(1);
            trueDurations = trueOffsets - trueOnsets;
    
            falseTransitions = diff(faceTimeSeries>0);
            falseOnsetIndices = find(falseTransitions == 1);
            falseOffsetIndices = find(falseTransitions == -1);
            % check if first or last entry in time series is true
            if faceTimeSeries(1)
                falseOnsetIndices = [1 falseOnsetIndices];
            end
            if faceTimeSeries(end)
                falseOffsetIndices = [falseOffsetIndices length(faceTimeSeries)];
            end
            falseOnsets = timeVector(falseOnsetIndices) - log.data.stimOnset(1);
            falseOffsets = timeVector(falseOffsetIndices) - log.data.stimOnset(1);
            falseDurations = falseOffsets - falseOnsets;
    
            mixedTransitions = diff(mixedColorTimeSeries>0);
            mixedOnsetIndices = find(mixedTransitions == 1);
            mixedOffsetIndices = find(mixedTransitions == -1);
            % check if first or last entry in time series is true
            if mixedColorTimeSeries(1)
                mixedOnsetIndices = [1 mixedOnsetIndices];
            end
            if mixedColorTimeSeries(end)
                mixedOffsetIndices = [mixedOffsetIndices length(mixedColorTimeSeries)];
            end
            mixedOnsets = timeVector(mixedOnsetIndices) - log.data.stimOnset(1);
            mixedOffsets = timeVector(mixedOffsetIndices) - log.data.stimOnset(1);
            mixedDurations = mixedOffsets - mixedOnsets;

            % store in arrays
            % first true color 
            onsets      = [onsets; trueOnsets'];
            durations   = [durations; trueDurations'];
            percepts    = [percepts; repmat({'house'},length(trueDurations),1)];
            % now false color
            onsets      = [onsets; falseOnsets'];
            durations   = [durations; falseDurations'];
            percepts    = [percepts; repmat({'face'},length(falseDurations),1)];
            % now mixed percepts
            onsets      = [onsets; mixedOnsets'];
            durations   = [durations; mixedDurations'];
            percepts    = [percepts; repmat({'mixed'},length(mixedDurations),1)];
    
    
            numSwitches = length(trueDurations) + length(falseDurations) + length(mixedDurations);
        else
            % apparently no button has been pressed during this trial
            % i.e., only mixed percept here
            mixedOnset = stimOnset;
            mixedDurations = stimOffset-stimOnset;

            onsets = [onsets; mixedOnset];
            durations = [durations; mixedDurations];
            percepts = [percepts; {'mixed'}];

            numSwitches = 1;
            warning('No key was pressed in trial %u\n', trl);
        end
        
        % was an artificial key press added?
        addedRelease = zeros(numSwitches,1);
        if artificialKeyreleases
            addedRelease(end) = 1;
        end
        keyAdded = [keyAdded; addedRelease];

    end
    resultsTable = table(percepts, onsets, durations);
    sortedResultsTable = sortrows(resultsTable, 3);
    % add the information whether or not an artificial key release was
    % added here, so that it does not get mixed by the sorting process
    sortedResultsTable.keyAdded = keyAdded;
    success = true;

catch READINGERROR
    fprintf('Something went wrong in trial %u\n', trl);
    rethrow(READINGERROR);
end