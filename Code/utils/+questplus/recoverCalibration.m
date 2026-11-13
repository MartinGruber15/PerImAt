function stimuliParameters = recoverCalibration(log, myPaths)
% questplus.recoverCalibration  Contrasts of an interrupted QUEST+ calibration. [added 2026-11-10]
%
%   stimuliParameters = questplus.recoverCalibration(log, myPaths)    % main.m: 'QUEST+ recover'
%
% Loads the latest checkpoint of the subject (sub-<sub>_questplusCheckpoint_<time>.mat,
% written by questplus.saveCheckpoint after every calibration trial), rebuilds
% the QUEST+ posterior exactly by replaying its trials, and shows the contrast
% sets to choose from (as at the normal end of a calibration):
%   - the estimate from all trials so far (posterior mean)
%   - the end of the calibration (if the calibration phase was finished)
%   - the contrasts tested in each validation (finished: PASSED/FAILED;
%     interrupted: with the counts so far)
% The chosen set is saved as <sub>_training_<n>.mat (input.adaptStimuli: Enter
% keeps each value), so that the next start of main.m uses it. Then either
%   'QUEST+ test'       tests these contrasts (40 house/face trials), or
%   'main experiment'   uses them directly.
% If the run has no results file (crash before its end), one is written
% (sub-<sub>_questplus_<time>.mat, results.recovered = true, not verified), so
% that the next 'QUEST+ calibration' starts with the prior centred on this run
% (qpSet.prior.centreOnUnverifiedRun) and the analysis finds it.
stimuliParameters = [];
Screen('CloseAll'); ListenChar(1);   % command-window dialogue only
files = dir(fullfile(myPaths.subjectDirectory, ['sub-' log.sub '_questplusCheckpoint_*.mat']));
if isempty(files)
    fprintf(2, 'No calibration checkpoint for subject %s in %s.\n', log.sub, myPaths.subjectDirectory);
    return
end
[~, order] = sort({files.name});
files = files(order);
if numel(files) > 1
    fprintf('Checkpoints of subject %s (the latest is used):\n', log.sub);
    fprintf('   %s\n', files.name);
end
ckFile = fullfile(files(end).folder, files(end).name);
L = load(ckFile, 'checkpoint'); ck = L.checkpoint;
qpSet = ck.qpSet;

% rebuild the posterior: prior of the run + its house/face trials in order
qp = questplus.initialise(qpSet, ck.priorCentre);
for i = 1:size(ck.history, 1)
    qp = questplus.update(qp, ck.history(i, 1), ck.history(i, 2), ck.history(i, 3) > 0.5);
end
est = questplus.estimates(qp, qpSet, false);
replayDiff = max(abs([est.uA.mean, est.uB.mean] - ck.estimateU));

fprintf('\n=================================================\n');
fprintf('  INTERRUPTED CALIBRATION: %s\n', files(end).name);
fprintf('=================================================\n');
fprintf('Status: %s (saved %s) | %d trials, %d house/face\n', ck.status, ck.savedAt, ck.nTotal, ck.nValid);
if replayDiff < 1e-9
    fprintf('Posterior rebuilt from the trials (identical to the run).\n');
else
    fprintf(2, 'Posterior rebuilt, but it differs from the run by %.2g log2 (check qpSet / prior).\n', replayDiff);
end
vs = [];
if isfield(ck, 'useVerify') && ck.useVerify; vs = ck.vs; end
if ~isempty(vs)
    fprintf('Phase at the interruption: %s; finished validations: %d\n', vs.phase, numel(vs.validations));
end
resultsFile = fullfile(myPaths.subjectDirectory, [ck.baseName '.mat']);
alreadySaved = false;
if isfile(resultsFile)
    R = load(resultsFile, 'results');
    if isfield(R.results, 'savedParameters')
        sp0 = R.results.savedParameters; where = '';
        if isfield(sp0, 'parameterFile'); where = [' as ' sp0.parameterFile]; end
        fprintf('The run ended normally and its contrasts were saved%s.\n', where);
        alreadySaved = true;
    else
        fprintf('The run ended (results in %s), but no contrasts were saved.\n', [ck.baseName '.mat']);
    end
else
    results = recoveredResults(ck, qp, qpSet, vs);
    save(resultsFile, 'results');
    fprintf('Results file written for the interrupted run: %s (not verified)\n', [ck.baseName '.mat']);
end

% contrast sets to choose from
[cand, iDef] = questplus.contrastCandidates(vs, qp, qpSet);
if ~isempty(vs)
    inValidation = strcmp(vs.phase, 'verify') && vs.validation > numel(vs.validations);
    if numel(vs.validations) == 0 && ~inValidation && all(isfinite(vs.calibrationEnd.u))
        cand(end+1) = makeCand('end of the calibration (no validation yet)', vs.calibrationEnd.u, qp, qpSet);
    end
    if inValidation
        c = questplus.textureCounts(ck.history(vs.valStartHist + 1:end, :));
        lab = sprintf('tested in validation %d: INTERRUPTED after %d of %d trials (house %d/%d, left eye %d/%d)', ...
            vs.validation, c.n, qpSet.verify.validationValidTrials, c.HouseL + c.HouseR, c.n, c.left, c.n);
        if vs.validation == 1; lab = [lab ' = end of the calibration']; end
        cand(end+1) = makeCand(lab, vs.xVerify, qp, qpSet);
    end
end
if alreadySaved
    iDef = 0;   % nothing new by default (Enter); a number saves another training file
    fprintf('Enter = save nothing new; a number saves these contrasts as a NEW training file.\n');
end
fprintf('\n');
questplus.printCandidates(cand, iDef);
try FlushEvents('keyDown'); catch; end
while true
    s = strtrim(input(sprintf('Number of the contrasts to save as training file (Enter = %d, 0 = none): ', iDef), 's'));
    if isempty(s); k = iDef; break; end
    k = str2double(s);
    if isscalar(k) && ~isnan(k) && k == round(k) && k >= 0 && k <= numel(cand); break; end
    fprintf('Please type a number between 0 and %d, or press Enter.\n', numel(cand));
end
if k == 0
    fprintf('Nothing saved.\n');
    return
end
choice = cand(k);
estC = questplus.estimates(qp, qpSet, true, choice.u);
c = choice.contrasts;
preset.houseContrast    = c.houseContrast;
preset.faceContrast     = c.faceContrast;
preset.leftEyeContrast  = c.leftEyeContrast;
preset.rightEyeContrast = c.rightEyeContrast;
preset.questPlus = struct('file', resultsFile, 'suggested', c, 'predictedPHouse', estC.final.pHouse.mean, ...
    'stopReason', ['recovered from checkpoint: ' ck.status], 'nValid', ck.nValid, 'choice', choice.label, ...
    'checkpoint', ckFile);
if isfield(ck, 'contrastReference'); preset.questPlus.contrastReference = ck.contrastReference; end   % [added 2026-11-10]
stimuliParameters = input.adaptStimuli(log, myPaths, preset);
R = load(resultsFile, 'results'); results = R.results;
results.savedParameters = stimuliParameters;
results.savedChoice = choice;
save(resultsFile, 'results');
ck.status = 'contrasts saved (recovered)'; ck.savedParameters = stimuliParameters;
checkpoint = ck; %#ok<NASGU>
save(ckFile, 'checkpoint');
fprintf(['\nNext: ''QUEST+ test'' tests these contrasts (40 house/face trials), or ''main experiment'' ' ...
    'uses them directly.\n']);
end


function results = recoveredResults(ck, qp, qpSet, vs)
% results file of an interrupted run (fields as questPlusCalibration writes them)
verified = ~isempty(vs) && vs.verified;
if verified
    est = questplus.estimates(qp, qpSet, true, vs.validatedU);
else
    est = questplus.estimates(qp, qpSet);
end
results.sub        = ck.sub;
results.timeStamp  = ck.timeStamp;
results.qpSet      = qpSet;
results.trials     = ck.trials;
results.nValid     = ck.nValid;
results.nTotal     = ck.nTotal;
results.stopReason = ['interrupted, recovered from checkpoint (' ck.status ')'];
results.aborted    = true;
results.recovered  = true;
results.est        = est;
if ~isempty(vs)
    results.verification   = vs.validations;
    results.verified       = verified;
    results.calibrationEnd = vs.calibrationEnd;
    results.decisions      = ck.decisions;
else
    results.verified = false;
end
results.qp            = rmfield(qp, 'likelihood');
results.fusionOffsets = ck.fusionOffsets;
end


function c = makeCand(label, u, qp, qpSet)
% as in questplus.contrastCandidates
u = min(max(u, -qp.xMax), qp.xMax);
e = questplus.estimates(qp, qpSet, true, u);
c.label = label;
c.u = u;
c.contrasts = questplus.contrastsFromBalance((u(1) + u(2)) / 2, (u(1) - u(2)) / 2, qp.baseContrast);
c.pHouse = e.final.pHouse.mean;
c.pLeft = e.final.pLeftEyeWins;
end
