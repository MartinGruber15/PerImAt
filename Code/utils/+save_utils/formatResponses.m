function [sortedResultsTable, success] = formatResponses(log,ptb)
%formatResponses: transforms key presses and releases into a table that can
%be written into a csv file for further analyses (sustained rivalry,
%binocularRivalryTraining).
%   input:
%       log - structure containing button presses and releases with
%       corresponding key IDs (save_utils.savedata)
%       ptb - structure containing the meaning of key IDs: ptb.Keys.house,
%       ptb.Keys.face and ptb.Keys.accept (the "lower key" = mixture)
%   output:
%       sortedResultsTable - table sorted by percept onset: percepts,
%       onsets (s from stimulus onset), durations (s), keyAdded (1 on the
%       period whose key release was added at stimulus offset)
%       success - a boolean whether or not everything worked fine
%
%   [changed 2026-11-10] The lower key (ptb.Keys.accept) is now the mixture
%   key, as in the rest of the experiment ("If you see a mixture, press the
%   lower key"). Each 1-ms sample is coded from the keys held down:
%       exactly one key held: house / face / mixed (lower key)
%       two or more keys held: mixed (overlap during a key change)
%       no key held:           none  (was: mixed)
%   Old version: _removed/Code/utils/+save_utils/formatResponses_before_mixedKey.m
%   In analysis/perimat_analysis.py every percept other than house/face
%   (mixed and none) is still labelled "mixed".

trl = 1;
try
    keys  = [ptb.Keys.house, ptb.Keys.face, ptb.Keys.accept];
    names = {'house', 'face', 'mixed'};

    % keep only the response keys
    keepDown = ismember(log.data.idDown, keys);
    keepUp   = ismember(log.data.idUp,   keys);
    timeDown = log.data.timeDown(keepDown); idDown = log.data.idDown(keepDown);
    timeUp   = log.data.timeUp(keepUp);     idUp   = log.data.idUp(keepUp);

    percepts  = {};
    durations = [];
    onsets    = [];
    keyAdded  = [];

    for trl = 1:length(log.data.stimOnset)
        stimOnset  = log.data.stimOnset(trl);
        stimOffset = log.data.stimOffset(trl);
        inTrialDown = timeDown >= stimOnset & timeDown <= stimOffset;
        inTrialUp   = timeUp   >= stimOnset & timeUp   <= stimOffset;

        timeVector = stimOnset:0.001:stimOffset;
        nT = numel(timeVector);
        toIdx = @(t) min(max(round((t - stimOnset) * 1000) + 1, 1), nT);   % time -> index (1 = stimOnset)

        held = zeros(numel(keys), nT);   % 1 where the key is held
        artificialKeyreleases = false;
        for k = 1:numel(keys)
            down = timeDown(inTrialDown & idDown == keys(k));
            up   = timeUp(inTrialUp & idUp == keys(k));
            [down, up, added] = pairPresses(down(:)', up(:)', stimOffset);
            artificialKeyreleases = artificialKeyreleases || added;
            for i = 1:numel(down)
                held(k, toIdx(down(i)):toIdx(up(i))) = 1;
            end
        end

        % code every sample: 0 none, 1 house, 2 face, 3 mixed
        nHeld = sum(held, 1);
        code = zeros(1, nT);
        for k = 1:numel(keys)
            code(nHeld == 1 & held(k, :) == 1) = k;
        end
        code(nHeld >= 2) = 3;
        if all(nHeld == 0)
            warning('No key was pressed in trial %u\n', trl);
        end

        % run-length encode
        change = [1, find(diff(code) ~= 0) + 1];
        stops  = [change(2:end) - 1, nT];
        for i = 1:numel(change)
            c = code(change(i));
            if c == 0; p = 'none'; else; p = names{c}; end
            on  = timeVector(change(i)) - log.data.stimOnset(1);
            off = timeVector(stops(i))  - log.data.stimOnset(1);
            if i < numel(change)
                off = timeVector(change(i + 1)) - log.data.stimOnset(1);   % periods touch
            end
            onsets    = [onsets; on];         %#ok<AGROW>
            durations = [durations; off - on]; %#ok<AGROW>
            percepts  = [percepts; {p}];       %#ok<AGROW>
        end
        addedRelease = zeros(numel(change), 1);
        if artificialKeyreleases
            addedRelease(end) = 1;
        end
        keyAdded = [keyAdded; addedRelease]; %#ok<AGROW>
    end
    resultsTable = table(percepts, onsets, durations, keyAdded);
    sortedResultsTable = sortrows(resultsTable, 'onsets');
    success = true;

catch READINGERROR
    fprintf('Something went wrong in trial %u\n', trl);
    rethrow(READINGERROR);
end
end


function [down, up, added] = pairPresses(down, up, stimOffset)
% Pair the presses and releases of one key within a trial.
%   - releases before the first press (key held from before the onset): dropped
%   - presses without a release (key held at the offset): released at stimOffset
added = false;
if isempty(down)
    up = [];
    return
end
up(up < down(1)) = [];
if numel(down) > numel(up)
    up(end + 1:numel(down)) = stimOffset;
    added = true;
end
if numel(down) ~= numel(up)
    error('You have a different amount of key releases and presses')
end
end
