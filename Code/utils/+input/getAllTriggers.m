function triggerTimes = getAllTriggers(keyboard,events, triggerKey)
events = input.updateKeyboardEvents(keyboard, events);
triggerTimes = [];
if isempty(events)
    return;
end
times = [events.Time];
codes = [events.Keycode];
valid = codes == triggerKey;
triggerTimes = times(valid);
end