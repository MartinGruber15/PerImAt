function trials = appendTrial(trials, res, houseEye, x, isValid, nValid, est, extra)
% questplus.appendTrial  Append one calibration trial (with running estimates) to the trial log.
% est: questplus.estimates output or [] (no estimate yet).
% extra (optional): struct with additional fields (same fields on every call),
% e.g. phase ('adaptive' | 'verify') and validation number.
t.trial            = numel(trials) + 1;
t.houseEye         = houseEye;
t.eyeConfig        = questplus.eyeConfigName(houseEye);
if houseEye == 1; t.leftEye = 'house'; t.rightEye = 'face'; else; t.leftEye = 'face'; t.rightEye = 'house'; end
t.x                = x;
t.houseTextureContrast = res.cHouse;
t.faceTextureContrast  = res.cFace;
t.response         = res.response;
t.missed           = isfield(res, 'missed') && res.missed;   % [added 2026-11-10] no key by qpSet.responseDeadline (response = 'mixed')
t.rt               = res.rt;
t.respondedDuringRivalry = res.respondedDuringRivalry;
t.ambiguous        = res.ambiguous;
t.keySequence      = strjoin(string(res.keySequence), ',');
t.usedByQuest      = isValid;
t.nValid           = nValid;
if isempty(est)
    t.thetaS_mean = NaN; t.thetaS_sd = NaN; t.thetaE_mean = NaN; t.thetaE_sd = NaN;
    t.sdPHouse_HouseL = NaN; t.sdPHouse_HouseR = NaN;
else
    t.thetaS_mean = est.thetaS.mean; t.thetaS_sd = est.thetaS.sd;
    t.thetaE_mean = est.thetaE.mean; t.thetaE_sd = est.thetaE.sd;
    t.sdPHouse_HouseL = est.pAtEstimate.sd(1); t.sdPHouse_HouseR = est.pAtEstimate.sd(2);
end
t.maskOnset        = res.maskOnset;
t.blankOnset       = res.blankOnset;
t.rivalryOnset     = res.rivalryOnset;
t.rivalryOffset    = res.rivalryOffset;
t.responseTime     = res.responseTime;
if nargin >= 8 && ~isempty(extra)
    fn = fieldnames(extra);
    for i = 1:numel(fn); t.(fn{i}) = extra.(fn{i}); end
end
if isempty(trials); trials = t; else; trials(end+1) = t; end
end
