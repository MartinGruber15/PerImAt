function model = fitModels(logContrastShown, houseLeft, report, cfg)
% fitModels  Update the two Bayesian models with all trials so far.
%
%   logContrastShown  n x 3   [logLevel logHouseFace logLeftRight] shown in each trial
%   houseLeft         n x 1   true if the house was shown to the left eye
%   report            n x 1   1 = house reported, 0 = face reported, -1 = mixed/none
%
% model.stim : posterior of the house-vs-face / left-vs-right model
%              (.params = [stimBias stimSlope eyeBias eyeSlope], .paramCov).
%              Only ANSWERED trials enter it; mixed trials carry no information
%              about which stimulus is stronger.
% model.mix  : posterior of the mixed-percept rate (all trials), one constant
%              logit (.mixedLogit, .mixedLogitVar).  It is only reported, it
%              never changes the contrasts.

n = size(logContrastShown, 1);
if n == 0
    logContrastShown = zeros(0, 3);  houseLeft = false(0, 1);  report = zeros(0, 1);
end
report = report(:);
isAnswered = report >= 0;

designMatrix = contrastBO.stimFeatures(logContrastShown(isAnswered, :), houseLeft(isAnswered), cfg);
[model.stim.params, model.stim.paramCov] = contrastBO.fitLogistic( ...
    designMatrix, report(isAnswered), cfg.paramPriorMean, cfg.paramPriorSD);

[model.mix.mixedLogit, model.mix.mixedLogitVar] = contrastBO.fitLogistic( ...
    ones(n, 1), double(report < 0), cfg.mixedPriorMean, cfg.mixedPriorSD);

model.nTrials   = n;
model.nAnswered = sum(isAnswered);
end
