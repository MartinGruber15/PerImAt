function log = waitForTrigger(ptb, log, design)
% mri.waitForTrigger  Wait for the scanner: skip design.nDummies volumes, return at the next one.
%
%   log = mri.waitForTrigger(ptb, log, design)
%
% The scanner sends one key press ptb.Keys.trg ('w') per volume on the
% subject keyboard (ptb.Keyboard2; the key must be in its KbQueue list, see
% getPTBSettings). Only with ptb.debugTrigger (main.m) is 'w' typed on the
% experimenter keyboard (ptb.Keyboard1) accepted as well. The first design.nDummies triggers are counted as dummy
% volumes; the experiment starts at trigger nDummies + 1:
%   log.trigger.times              all trigger times until the start (GetSecs clock)
%   log.trigger.firstTrigger       the first trigger
%   log.trigger.firstExperimentTR  trigger nDummies + 1 = start of the experiment
%   log.trigger.nDummies
% NOTE: whether the scanner sends triggers during its own dummy scans depends
% on the sequence; nDummies counts the triggers that ARRIVE before the start.
% [change 2026-11-03] (this function was not called before, see perImAtOnline):
%   - ESC added: before, the loop only ended with a trigger, so without
%     triggers the only way out was Ctrl+C behind the full-screen window;
%   - typed 'w' on the experimenter keyboard only with ptb.debugTrigger;
%   - terminal output: plan, each dummy, start (otherwise the same logic).
% ESCAPE on the experimenter keyboard stops the waiting with an error (e.g. no
% triggers arrive); main.m's onCleanup (save_utils.closeAll) then closes the
% screen, eye tracker and DataPixx and saves the log, as after any error.
log.trigger.times = [];
log.trigger.nDummies = design.nDummies;
log.trigger.firstTrigger = [];
log.trigger.firstExperimentTR = [];
nTrg = 0;
debugTrg = isa(ptb, 'DataContainer') && ptb.hasField('debugTrigger') && ptb.debugTrigger;
fprintf('\nWaiting for the scanner: %d dummy volume(s), the run starts with trigger %d (key "%s"; ESC aborts) ...\n', ...
    design.nDummies, design.nDummies + 1, KbName(ptb.Keys.trg));
% clear old key presses
KbQueueFlush(ptb.Keyboard1); KbQueueFlush(ptb.Keyboard2);
KbQueueStart(ptb.Keyboard1); KbQueueStart(ptb.Keyboard2);
while true
    [~, firstPress] = KbQueueCheck(ptb.Keyboard2);      % subject keyboard: scanner triggers
    [~, firstPressExp] = KbQueueCheck(ptb.Keyboard1);   % experimenter keyboard: ESC (+ 'w' in debug)
    if firstPressExp(ptb.Keys.escape)
        error('waitForTrigger:aborted', 'Aborted by the experimenter (ESC) while waiting for the scanner.');
    end
    triggerTime = firstPress(ptb.Keys.trg);
    if debugTrg && ~triggerTime; triggerTime = firstPressExp(ptb.Keys.trg); end
    if triggerTime
        nTrg = nTrg + 1;
        log.trigger.times(nTrg) = triggerTime;
        if nTrg == 1
            log.trigger.firstTrigger = triggerTime;
        end
        if nTrg <= design.nDummies
            fprintf('  dummy volume %d of %d\n', nTrg, design.nDummies);
        else
            log.trigger.firstExperimentTR = triggerTime;
            fprintf('  trigger %d: start.\n', nTrg);
            break
        end
    end
    WaitSecs(0.001);
end
end
