function [resp, rt, events] = getFirstKeyEvent(keyboard,events, tStart, tEnd, validKeys) %restrictedKeyList
resp = 0;
rt   = NaN;
while GetSecs < tEnd
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
            return;
        end
    end
    WaitSecs(0.001);
end
end