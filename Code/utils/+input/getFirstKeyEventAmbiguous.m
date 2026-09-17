function [resp, rt, events, ambiguous] = getFirstKeyEventAmbiguous(keyboard, events, tStart, tEnd, validKeys)
resp  = 0;
rt    = NaN;
ambiguous = false;
while GetSecs < tEnd
    events = input.updateKeyboardEvents(keyboard, events);
    WaitSecs(0.001);
end
fprintf('tStart = %.15f\n', tStart);
fprintf('tEnd   = %.15f\n', tEnd);

if ~isempty(events)
    fprintf('event times:\n');
    fprintf('%.15f\n', [events.Time]);
end

% Get events occurring during the response window
if ~isempty(events)
    times = [events.Time];
    valid = times >= tStart & times <= tEnd;

    % Restrict to valid keys
    if nargin >= 5 && ~isempty(validKeys)
        valid = valid & ismember([events.Keycode], validKeys);
    end
    if any(valid)
        candidateTimes  = times(valid);
        candidateEvents = events(valid);

        % First keypress determines the response and RT
        [tPress, ~] = min(candidateTimes);
        rt = tPress - tStart;
        fprintf('rt   = %.15f\n', rt);

        % Get unique keycodes in order of first occurrence
        keycodes = [candidateEvents.Keycode];
        uniqueKeys = unique(keycodes, 'stable');

        if isscalar(uniqueKeys)
            % Only one distinct key was pressed
            resp  = uniqueKeys(1);
            ambiguous = false;
        else
            % Multiple distinct keys were pressed
            resp  = uniqueKeys;
            ambiguous = true;
        end
    end
end
end
