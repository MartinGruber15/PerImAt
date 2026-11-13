function [participantInfo, results] = questPlusCalibration(log, ptb, design, myPaths, participantInfo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% questPlusCalibration: adaptive (QUEST+) calibration of the house/face and
% left/right-eye contrasts for onset rivalry.
%
% Goal: find contrasts for the four textures (HouseL, FaceL, HouseR, FaceR)
% with which, in a baseline without manipulation, the first percept is
% equally likely house or face, independent of the eye the house is shown
% to, i.e. P(house | HouseL+FaceR) = P(house | FaceL+HouseR) = 0.5.
%
% Trial: 2 s dynamic noise mask, 1 s blank, 3 s onset rivalry, grey screen
% until response (house / face / mixed); no fixation dots (no-report part).
%
% Model, priors, trial selection and stop rules: utils/+questplus/README.md
% Settings: settings/getQuestPlusSettings.m
%
% The final contrasts are saved via input.adaptStimuli as
% <sub>_training_<n>.mat in the subject folder, so that
% loadLatestTrainingParameters (and hence getVisualDesignSettings /
% questPlusTest / the main experiment) uses them.
%
% QUEST+: Watson, A. B. (2017). QUEST+: A general multidimensional Bayesian
%   adaptive psychometric method. Journal of Vision, 17(3):10.
% MATLAB reference implementation: P. R. Jones, QuestPlus,
%   https://github.com/petejonze/QuestPlus (see utils/+questplus/*.m for the
%   parts that follow it).
%
% input:
%   log, ptb, design, myPaths - as in main.m
%   participantInfo           - struct (language, fusion offsets)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

qpSet = getQuestPlusSettings();
timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HHmmss'));
baseName = ['sub-' log.sub '_questplus_' timeStamp];
if ~isfolder(myPaths.subjectDirectory); mkdir(myPaths.subjectDirectory); end

%% QUEST+ initialisation ---------------------------------------------------
priorCentre = struct();
if qpSet.prior.centreOnLatestTraining
    prev = loadLatestTrainingParameters(myPaths.subjectDirectory);
    priorCentre.houseFaceRatio = prev.houseContrast / prev.faceContrast;
    priorCentre.leftRightRatio = prev.leftEyeContrast / prev.rightEyeContrast;
end
if isfield(qpSet.prior, 'centreOnUnverifiedRun') && qpSet.prior.centreOnUnverifiedRun
    % latest calibration of this subject NOT verified -> start from its estimate
    prevRuns = dir(fullfile(myPaths.subjectDirectory, ['sub-' log.sub '_questplus_*.mat']));
    if ~isempty(prevRuns)
        [~, iLatest] = max([prevRuns.datenum]);
        P = load(fullfile(prevRuns(iLatest).folder, prevRuns(iLatest).name), 'results');
        if isfield(P, 'results') && isfield(P.results, 'verified') && ~P.results.verified && ...
                isfield(P.results, 'est') && P.results.nValid > 0
            priorCentre.houseFaceRatio = 2^P.results.est.final.thetaS;
            priorCentre.leftRightRatio = 2^P.results.est.final.thetaE;
            fprintf(['The latest calibration (%s) was NOT verified: the prior is centred on its estimate ' ...
                '(house/face %.3f, left/right %.3f).\n'], prevRuns(iLatest).name, ...
                priorCentre.houseFaceRatio, priorCentre.leftRightRatio);
        end
    end
end
fprintf('\nInitialising QUEST+ ...\n');
qp = questplus.initialise(qpSet, priorCentre);
fprintf(['QUEST+: %d contrast ratios per eye configuration (step %.2f log2 = x%.3f), ' ...
    '%d parameter combinations (%d x %d balance points, %d slopes, %d lapse rates)\n'], ...
    numel(qp.xDomain), qp.stepLog2, 2^qp.stepLog2, size(qp.P, 2), qp.dims(1), qp.dims(2), qp.dims(3), qp.dims(4));
fprintf('Prior: house/face ratio %.3f (SD %.2f log2), left/right ratio %.3f (SD %.2f log2)\n', ...
    qp.priorUsed.houseFaceRatio, qp.priorUsed.sdStimLog2, qp.priorUsed.leftRightRatio, qp.priorUsed.sdEyeLog2);

%% Keyboard queues -----------------------------------------------------------
KbQueueStop(ptb.Keyboard2); KbEventFlush(ptb.Keyboard2);
KbQueueStop(ptb.Keyboard1); KbEventFlush(ptb.Keyboard1);
KbQueueStart(ptb.Keyboard2); KbQueueStart(ptb.Keyboard1);

%% Fusion, stimuli, instructions ----------------------------------------------
participantInfo = display.stereo.alignFusion(ptb, participantInfo);
fusionOffsets = questplus.saveFusionOffsets(participantInfo, myPaths);   % keep + log the offsets
raw      = questplus.captureRawStimuli(ptb, design, myPaths);
% [changed 2026-11-10] figure (screens, eyes, keys incl. the 2-s answer window); text if it is missing
calFig = '';
if isobject(myPaths) && myPaths.hasField('instructionFigurePath') && design.hasField('instructionFigure')
    calFig = fullfile(myPaths.instructionFigurePath, design.instructionFigure.calibration);
end
if ~display.stereo.figureInstruction(ptb, design, calFig, design.figureContinue, qpSet.instructionWaitDuration)
    display.stereo.instruction(ptb, design, questplus.instructionText(ptb, participantInfo, 'report', design), qpSet.instructionWaitDuration, false);
end
% [added 2026-11-11] key reminder (any key), then the start countdown
display.stereo.instruction(ptb, design, design.calibrationReminder, qpSet.instructionWaitDuration, false);
KbReleaseWait(-1);
display.stereo.instruction(ptb, design, design.waitTillStart, design.waitTillStartDuration, true);

%% Trials --------------------------------------------------------------------
trials = struct([]);
aborted = false;
sch = questplus.schedule('init', qpSet.blockSize);
nValid = 0; nTotal = 0; isFin = false; stopReason = '';
decisions = struct('afterTrial', {}, 'decision', {}, 'suggested', {}, 'action', {});   % [added 2026-11-06] experimenter decisions
useVerify = isfield(qpSet, 'verify') && qpSet.verify.enabled;
vs = questplus.verifyControl([], qp, qpSet);   % calibrate-verify loop state (qpSet.verify)
printPlan(qpSet, useVerify);
% [added 2026-11-10] checkpoint after every trial (questplus.saveCheckpoint), so
% that an interrupted run can be continued with 'QUEST+ recover'
% (questplus.recoverCalibration); the trial CSV is also written after every trial
ckFile  = fullfile(myPaths.subjectDirectory, ['sub-' log.sub '_questplusCheckpoint_' timeStamp '.mat']);
csvFile = fullfile(myPaths.subjectDirectory, [baseName '.csv']);
refMode = 'image'; if isfield(raw, 'refMode'); refMode = raw.refMode; end   % [added 2026-11-10] contrast reference used
ckInfo  = struct('sub', log.sub, 'timeStamp', timeStamp, 'baseName', baseName, 'qpSet', qpSet, 'contrastReference', refMode, ...
    'priorCentre', priorCentre, 'useVerify', useVerify);
fprintf('Checkpoint after every trial: %s\n', ckFile);
showPHouseSD = ~useVerify || strcmpi(qpSet.verify.calibrationRule, 'balance');   % SD P(house) drives the stop rule

% QUEST+ trials (calibration, then validation)
while ~isFin && ~aborted
    phase = 'adaptive'; block = 0;
    if useVerify; phase = vs.phase; end   % 'adaptive' | 'verify'
    if useVerify && strcmp(vs.phase, 'verify')
        [houseEye, x, sch] = questplus.verifyNextTrial(vs, qp, sch);
        phase = 'verify'; block = vs.validation;
    else
        [houseEye, x, sch] = questplus.chooseNextTrial(qp, qpSet, sch);
    end
    [res, aborted] = questplus.presentTrial(ptb, design, qpSet, raw, houseEye, x, qp.baseContrast);
    if aborted; break; end
    [qp, sch, isValid] = questplus.processResponse(qp, qpSet, sch, houseEye, x, res.response);
    nTotal = nTotal + 1;
    nValid = nValid + isValid;
    % one line per trial for the experimenter
    % [changed 2026-11-06] + the current best contrasts (posterior mean after this
    % trial) as they are entered in the settings: house, face, left eye, right eye
    estLine = questplus.estimates(qp, qpSet, false);   % estimate after this trial
    cNow = questplus.contrastText(estLine.final.contrasts);
    respLabel = res.response;
    if isfield(res, 'missed') && res.missed; respLabel = 'none'; end   % [added 2026-11-10] no key by the deadline
    if strcmp(phase, 'verify')
        % validation k (fixed contrasts): running counts of this validation
        cv = questplus.textureCounts(qp.history(vs.valStartHist + 1:end, :));
        % [changed 2026-11-11] + how often each texture was seen first and the percentages
        nH = cv.HouseL + cv.HouseR;
        fprintf(['%3d  V%d %2d/%d     %-12s x=%+.2f  %-5s | HouseL %2d FaceR %2d | FaceL %2d HouseR %2d | ' ...
            'house %2d/%-2d (%3.0f%%)  left eye %2d/%-2d (%3.0f%%) | estimate now: %s\n'], ...
            nTotal, block, cv.n, qpSet.verify.validationValidTrials, questplus.eyeConfigName(houseEye), x, respLabel, ...
            cv.HouseL, cv.FaceR, cv.FaceL, cv.HouseR, nH, cv.n, 100 * nH / cv.n, cv.left, cv.n, 100 * cv.left / cv.n, cNow);
    else
        sdP = '';
        if showPHouseSD
            sdP = sprintf(' | SD P(house) %.3f / %.3f', estLine.pAtEstimate.sd(1), estLine.pAtEstimate.sd(2));
        end
        fprintf('%3d (%3d valid)  %-12s x=%+.2f  %-5s | thetaS %+.2f+-%.2f  thetaE %+.2f+-%.2f | SD balance points %.3f / %.3f%s | %s\n', ...
            nTotal, nValid, questplus.eyeConfigName(houseEye), x, respLabel, ...
            estLine.thetaS.mean, estLine.thetaS.sd, estLine.thetaE.mean, estLine.thetaE.sd, ...
            estLine.uA.sd, estLine.uB.sd, sdP, cNow);
    end
    if useVerify
        [vs, qp, isFin, stopReason, estNow] = questplus.verifyControl(vs, qp, qpSet, nValid, nTotal);
    else
        [isFin, stopReason, estNow] = questplus.isFinished(qp, qpSet, nValid, nTotal);
    end
    trials = questplus.appendTrial(trials, res, houseEye, x, isValid, nValid, estNow, ...
        struct('phase', phase, 'validation', block));
    questplus.saveCheckpoint(ckFile, csvFile, 'running', ckInfo, qp, vs, trials, decisions, ...
        fusionOffsets, nValid, nTotal, estLine);   % [added 2026-11-10]
    if useVerify && strcmp(vs.phase, 'decide') && ~isFin
        % [added 2026-11-06] decision point (verify.askExperimenter): end of the
        % calibration or of a validation. The subject sees a break screen without
        % key instruction; the experimenter sees the contrasts and chooses in the
        % command window: next validation or stop (questplus.askExperimenter).
        display.stereo.instruction(ptb, design, questplus.breakText(participantInfo, 'wait'), 0, true);
        vs.action = questplus.askExperimenter(vs, qp, qpSet, nValid, nTotal);
        decisions(end+1) = struct('afterTrial', nTotal, 'decision', vs.decision, ...
            'suggested', vs.suggest, 'action', vs.action); %#ok<AGROW>
        [vs, qp, isFin, stopReason] = questplus.verifyControl(vs, qp, qpSet, nValid, nTotal);
        questplus.saveCheckpoint(ckFile, csvFile, 'running', ckInfo, qp, vs, trials, decisions, ...
            fusionOffsets, nValid, nTotal, estLine);   % [added 2026-11-10] after the decision
    end
    if useVerify && vs.needBreak && ~isFin
        % break (+ fusion check) before every validation (questplus.verifyControl)
        vs.needBreak = false;
        display.stereo.instruction(ptb, design, questplus.breakText(participantInfo), qpSet.instructionWaitDuration, false);
        if qpSet.verify.fusionCheckAfterBreak
            participantInfo = display.stereo.alignFusion(ptb, participantInfo);
            fusionOffsets(end+1) = questplus.saveFusionOffsets(participantInfo, myPaths); %#ok<AGROW>
        end
        display.stereo.instruction(ptb, design, design.waitTillStart, design.waitTillStartDuration, true);
    end
    % mixed-rate warning for the experimenter
    recent = trials(max(1, end - qpSet.mixedWindow + 1):end);
    if numel(recent) >= qpSet.mixedWindow && mean(strcmp({recent.response}, 'mixed')) > qpSet.mixedWarnRate
        fprintf(2, 'WARNING: %.0f%% of the last %d trials were "mixed".\n', ...
            100 * mean(strcmp({recent.response}, 'mixed')), qpSet.mixedWindow);
    end
end
if aborted
    stopReason = 'aborted by experimenter (ESC)';
end

%% End of run ------------------------------------------------------------------
if ~aborted
    display.stereo.instruction(ptb, design, design.RunIsOver, qpSet.instructionWaitDuration, false);
end
Screen('CloseAll');
ListenChar(1);

%% Estimates, ML cross-check, saving ------------------------------------------
if useVerify && vs.verified
    est = questplus.estimates(qp, qpSet, true, vs.validatedU);   % propose the VALIDATED contrasts (last passed validation)
else
    est = questplus.estimates(qp, qpSet);
end
if ~isempty(qp.history)
    fit = questplus.fitML(qp.history, est.lapse.mean, [est.thetaS.mean, est.thetaE.mean, est.slope.mean]);   % ML cross-check
else
    fit = questplus.fitML([], est.lapse.mean);
end

results.sub        = log.sub;
results.timeStamp  = timeStamp;
results.qpSet      = qpSet;
results.trials     = trials;
results.nValid     = nValid;
results.nTotal     = nTotal;
results.stopReason = stopReason;
results.aborted    = aborted;
results.est        = est;
results.mlFit      = fit;
if useVerify
    results.verification = vs.validations;   % per validation: contrasts, counts, binomial tests (questplus.verifyControl)
    results.verified     = vs.verified;      % at least one validation passed
    results.calibrationEnd = vs.calibrationEnd;   % [added 2026-11-06] estimate at the end of the calibration
    results.decisions    = decisions;        % [added 2026-11-06] experimenter decisions (verify.askExperimenter)
end
results.qp         = rmfield(qp, 'likelihood');   % prior, posterior, grids, history
results.fusionOffsets = fusionOffsets;
results.carryover  = questplus.carryover(trials);   % diagnostic: runs of the same winning eye
results.stability  = questplus.stability(qp.history, qp.thetaS, est.slope.mean, est.lapse.mean);   % diagnostic: change over the run
matFile = fullfile(myPaths.subjectDirectory, [baseName '.mat']);
save(matFile, 'results');
if ~isempty(trials)
    T = struct2table(trials, 'AsArray', true);
    writetable(T, fullfile(myPaths.subjectDirectory, [baseName '.csv']), 'Delimiter', ';');
end
fprintf('\nQUEST+ data saved to\n%s\n', matFile);
questplus.saveCheckpoint(ckFile, csvFile, ['ended: ' stopReason], ckInfo, qp, vs, trials, decisions, ...
    fusionOffsets, nValid, nTotal, [], struct('resultsFile', matFile));   % [added 2026-11-10]

questplus.printSummary(results);
if useVerify && ~results.verified && ~aborted
    fprintf(2, ['Not verified: re-check fusion/head position and run ''QUEST+ calibration'' again - the next run ' ...
        'starts with the prior centred on this run''s estimate (qpSet.prior.centreOnUnverifiedRun).\n']);
end
if qpSet.showPlots && nValid > 0
    try
        questplus.plotRun(qp, trials, est, baseName);
    catch ME
        warning('Could not plot QUEST+ run: %s', ME.message);
    end
end

%% Save contrasts for loadLatestTrainingParameters ------------------------------
saveParams = ~aborted && nValid > 0;
if aborted && nValid > 0
    fprintf('\nThe run was aborted. Save the (preliminary) contrasts anyway?\n');
    saveParams = input.chooseOption(["yes", "no"]) == "yes";
end
if saveParams
    % [added 2026-11-06] the experimenter chooses which contrasts to save: estimate
    % from all trials, end of the calibration, or those tested in a validation
    % (questplus.chooseContrasts; Enter = last passed validation, otherwise the
    % estimate from all trials). They are shown again in input.adaptStimuli
    % (Enter keeps each value, Enter again saves).
    if useVerify && isfield(qpSet.verify, 'askExperimenter') && isequal(qpSet.verify.askExperimenter, true)
        choice = questplus.chooseContrasts(vs, qp, qpSet);
        results.savedChoice = choice;
        est = questplus.estimates(qp, qpSet, true, choice.u);
        results.est = est;
        save(matFile, 'results');
    end
    c = est.final.contrasts;
    preset.houseContrast    = c.houseContrast;
    preset.faceContrast     = c.faceContrast;
    preset.leftEyeContrast  = c.leftEyeContrast;
    preset.rightEyeContrast = c.rightEyeContrast;
    preset.questPlus = struct('file', matFile, 'suggested', c, ...
        'predictedPHouse', est.final.pHouse.mean, 'stopReason', stopReason, 'nValid', nValid);
    if isfield(results, 'savedChoice'); preset.questPlus.choice = results.savedChoice.label; end   % [added 2026-11-06]
    preset.questPlus.contrastReference = refMode;   % [added 2026-11-10] checked by getVisualDesignSettings
    % lets the experimenter confirm (Enter) or overwrite the values, then
    % saves <sub>_training_<n>.mat (read by loadLatestTrainingParameters)
    stimuliParameters = input.adaptStimuli(log, myPaths, preset);
    results.savedParameters = stimuliParameters;
    save(matFile, 'results');
    questplus.saveCheckpoint(ckFile, csvFile, 'contrasts saved', ckInfo, qp, vs, trials, decisions, ...
        fusionOffsets, nValid, nTotal, [], struct('resultsFile', matFile, 'savedParameters', stimuliParameters));   % [added 2026-11-10]
end
end


function printPlan(qpSet, useVerify)
% stop rule and columns of the trial lines, printed once before the first trial
if useVerify
    v = qpSet.verify;
    if strcmpi(v.calibrationRule, 'sd')
        crit = sprintf('the SD of both balance points is <= %.2f log2', v.sdCriterion);
    else
        crit = sprintf('the SD of P(house) at the estimate is <= %.2f (slope floor %.1f)', v.preCriterion, qpSet.stopSlopeFloor);
    end
    fprintf(['\nPlan: calibration until %s (at least %d house/face trials, at most %d trials incl. mixed),\n' ...
        '      then a break and a validation: %d house/face trials at fixed contrasts. Passed if neither house\n' ...
        '      nor the left eye differs from 50%% (binomial p >= %.2f); otherwise up to %d validations.\n'], ...
        crit, qpSet.minValidTrials, v.maxCalibrationTrials, v.validationValidTrials, v.alpha, v.maxValidations);
else
    fprintf('\nPlan: no validation; stop rule ''%s'' (questplus.isFinished).\n', qpSet.stopRule);
end
fprintf(['Trial lines: trial (house/face trials) | eye configuration | x = log2(house/face contrast) | response |\n' ...
    '             estimate +- SD (log2): thetaS > 0 face stronger, thetaE > 0 right eye stronger | SD balance points\n' ...
    '             (validation: V<k> trials/target | how often house and the left-eye image were seen first)\n\n']);
end
