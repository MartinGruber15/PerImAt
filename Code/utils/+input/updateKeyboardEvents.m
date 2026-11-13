function events = updateKeyboardEvents(keyboard, events)
while true
    [event, nremaining] = KbEventGet(keyboard);
    if isempty(event)
        break;
    end
    % Only store key-down events
    if event.Pressed
        newEvent.Time    = event.Time;
        newEvent.Keycode = event.Keycode;
        events(end+1) = newEvent;
    end
    if nremaining == 0
        break;
    end
end
end