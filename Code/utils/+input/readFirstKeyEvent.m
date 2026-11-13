function [resp, rt, events] = readFirstKeyEvent(keyboard,events, tStart, tEnd, validKeys) %restrictedKeyList
resp = 0;
rt   = NaN;
events = input.updateKeyboardEvents(keyboard, events);
if ~isempty(events)
    times = [events.Time];
    valid = times >= tStart & times <= tEnd;
    if nargin >= 5 && ~isempty(validKeys)
        valid = valid & ismember([events.Keycode], validKeys);
    end
    if any(valid)
        candidateTimes  = times(valid);
        candidateEvents = events(valid);
        [tPress, idx] = min(candidateTimes);
        resp = candidateEvents(idx).Keycode;
        rt   = tPress - tStart;
    end
end
end