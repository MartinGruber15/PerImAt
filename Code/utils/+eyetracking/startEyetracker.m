function ptb = startEyetracker(ptb, eyeRun)
% Initialize EyeLink, calibrate, and start recording for one run.
% eyeRun.subjectNr, eyeRun.runNr, eyeRun.report

if ~ptb.eyelink.track
    return;
end

% EyeLink calibration requires 60 Hz on this system.
unix('xrandr --screen 1 --output DP-0 --mode 1920x1080 --rate 60');

% Temporary window for EyeLink calibration.
[ptb.et.window, ptb.et.windowRect] = PsychImaging('OpenWindow', ...
    ptb.screenNumber, ptb.BackgroundColor, [], [], [], 1);

if ptb.eyelink.track == -1
    dummymode = 1;
else
    dummymode = 0;
end

el = EyelinkInitDefaults(ptb.et.window);
if ~EyelinkInit(dummymode, 1)
    Screen('Close', ptb.et.window);
    error('Eyelink initialization failed.');
end

[~, vs] = Eyelink('GetTrackerVersion');
fprintf('Running experiment on a ''%s'' tracker.\n', vs);

% Downsize area used for calibration, so all calibration points are
% visible to the subject but the stimuli are still inside the recorded
% area
el.targetbeep = 0;
el.feedbackbeep = 0;
el.cal_target_beep = 0;
el.winInfo.IsFullscreen = 1;
EyelinkUpdateDefaults(el);

% This ensures that the calibration dots mainly shown in the center of the
% screen.
Eyelink('command', 'calibration_area_proportion = 0.25 0.25');
Eyelink('command', 'validation_area_proportion = 0.25 0.25');

% Setting the proper recording resolution, and calibration type
Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, ptb.et.windowRect(3)-1, ptb.et.windowRect(4)-1);
Eyelink('command', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, ptb.et.windowRect(3)-1, ptb.et.windowRect(4)-1);
Eyelink('command', 'calibration_type = HV13');

Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE');
Eyelink('command', 'file_sample_data = LEFT,RIGHT,GAZE,AREA');

% Set link data (used for gaze cursor)
Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
Eyelink('command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');

% Make sure that we get gaze data from the Eyelink
Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');

if eyeRun.report
    suffix = 'r';
else
    suffix = 'nr';
end
ptb.eyelink.edfFile = sprintf('s%02dr%02d%s', eyeRun.subjectNr, eyeRun.runNr, suffix);

status = Eyelink('OpenFile', [ptb.eyelink.edfFile '.edf']);
if status ~= 0
    Screen('Close', ptb.et.window);
    error('Could not open EyeLink file.');
end

% Stop experiment if 'escape' or 'q'is being pressed
[KeyIsDown, ~, keyCode, ~] = KbCheck;
if KeyIsDown
    if (find(keyCode)==ptb.Keys.escape || find(keyCode)==ptb.Keys.quit)
        fprintf('\n=> pressed ESCAPE\n');
        return;
    end
end

if ptb.stereomode == 4
    Screen('SelectStereoDrawBuffer', ptb.et.window, 0);
end
EyelinkDoTrackerSetup(el);
EyelinkDoDriftCorrection(el);

Eyelink('StartRecording');
Eyelink('Message', 'SYNCTIME');

Screen('Close', ptb.et.window);
unix('xrandr --screen 1 --output DP-0 --mode 1920x1080 --rate 120');

fprintf('EyeLink recording started: %s.edf\n', ptb.eyelink.edfFile);
end
