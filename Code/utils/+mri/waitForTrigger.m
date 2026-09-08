function log = waitForTrigger(ptb, log, design)
    log.trigger.times = [];
    log.trigger.nDummies = design.nDummies;
    log.trigger.firstTrigger = [];
    log.trigger.firstExperimentTR = [];
    scannerTrg = 1;
    dummyScanned = 0;
    fprintf('\nWaiting for triggers...\n');
    % Clear old keyboard events
    KbQueueFlush(ptb.Keyboard1);if ptb.Keyboard2;KbQueueFlush(ptb.Keyboard2);end
    KbQueueStart(ptb.Keyboard1);if ptb.Keyboard2KbQueueStart(ptb.Keyboard2);end

    while true
        [~, firstPress] = KbQueueCheck(ptb.Keyboard2);
        if firstPress(ptb.Keys.trg)
            triggerTime = firstPress(ptb.Keys.trg);
            log.trigger.times(scannerTrg) = triggerTime;
            if scannerTrg == 1
                log.trigger.firstTrigger = triggerTime;
            end
            if dummyScanned < design.nDummies
                dummyScanned = dummyScanned + 1;
                fprintf('\nGot Dummy %d of %d', ...
                    dummyScanned, design.nDummies);
                scannerTrg = scannerTrg + 1;
            else
                log.trigger.firstExperimentTR = triggerTime;
                fprintf('\nStarting Experiment!\n');
                break;
            end
        end
    end

end
