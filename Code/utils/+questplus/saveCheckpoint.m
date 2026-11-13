function saveCheckpoint(ckFile, csvFile, status, info, qp, vs, trials, decisions, fusionOffsets, nValid, nTotal, estNow, extra)
% questplus.saveCheckpoint  Running record of a QUEST+ calibration. [added 2026-11-10]
%
% Called by questPlusCalibration after every trial (and at decision points and
% at the end), so that an interrupted calibration (crash, MATLAB closed,
% ESC without saving) can be continued with questplus.recoverCalibration
% ('QUEST+ recover' in main.m): its contrasts can be saved as a training file
% and then validated ('QUEST+ test') or used directly.
%
% ckFile  : sub-<sub>_questplusCheckpoint_<time>.mat (overwritten every call;
%           variable 'checkpoint'). The name does not match sub-<sub>_questplus_*,
%           so the prior of the next calibration and the analysis are not affected.
% csvFile : sub-<sub>_questplus_<time>.csv, the trial table so far (overwritten
%           every call; the final version is written at the end as before)
% status  : 'running' | 'ended: <stop reason>' | 'contrasts saved'
% info    : sub, timeStamp, baseName, qpSet, priorCentre, useVerify (constant)
% qp      : current QUEST+ state; only qp.history is saved (with qpSet and
%           priorCentre the posterior is rebuilt exactly by replaying it)
% estNow  : questplus.estimates after the last trial ([] = computed here)
% extra   : optional struct, its fields are added (e.g. resultsFile, savedParameters)
% A failing save only gives a warning; the calibration goes on.
if nargin < 13; extra = struct(); end
try
    if nargin < 12 || isempty(estNow); estNow = questplus.estimates(qp, info.qpSet, false); end
    ck = info;
    ck.status = status;
    ck.savedAt = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    ck.nValid = nValid;
    ck.nTotal = nTotal;
    ck.history = qp.history;                 % [houseEye, x, isHouse] of every house/face trial
    ck.vs = vs;                              % calibrate/validate state (questplus.verifyControl)
    ck.trials = trials;
    ck.decisions = decisions;
    ck.fusionOffsets = fusionOffsets;
    ck.estimate = estNow.final.contrasts;    % posterior mean after the last trial (as entered in the settings)
    ck.estimateU = [estNow.uA.mean, estNow.uB.mean];
    ck.estimateSD = [estNow.uA.sd, estNow.uB.sd];
    f = fieldnames(extra);
    for i = 1:numel(f); ck.(f{i}) = extra.(f{i}); end
    checkpoint = ck; %#ok<NASGU>
    save(ckFile, 'checkpoint');
    if ~isempty(trials)
        writetable(struct2table(trials, 'AsArray', true), csvFile, 'Delimiter', ';');
    end
catch ME
    warning('questplus:saveCheckpoint', 'Checkpoint not saved (%s); the calibration continues.', ME.message);
end
end
