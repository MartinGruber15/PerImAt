function model = fitModels(X, houseLeft, resp, cfg)
% fitModels  Update the two Bayesian models with all trials so far.
%
%   X          n x 3   contrasts [g s e] shown in each trial
%   houseLeft  n x 1   true if the house was shown to the left eye
%   resp       n x 1   1 = house reported, 0 = face reported, -1 = mixed/none
%
% model.stim : posterior of the house-vs-face model (answered trials only)
% model.mix  : posterior of the mixed-percept model (all trials)

if isfield(cfg, 'mode') && strcmpi(cfg.mode, 'perConfig')
    model = contrastBO.fitModelsCfg(X, houseLeft, resp, cfg);   % per-pair model
    return
end

n = size(X, 1);
if n == 0
    X = zeros(0, 3);  houseLeft = false(0, 1);  resp = zeros(0, 1);
end
resp = resp(:);
isAnswered = resp >= 0;

Phi = contrastBO.stimFeatures(X(isAnswered, :), houseLeft(isAnswered), cfg);
[model.stim.theta, model.stim.Sigma] = contrastBO.fitLogistic( ...
    Phi, resp(isAnswered), cfg.stimPriorMean, cfg.stimPriorSD);

Psi = contrastBO.mixFeatures(X(:, 1), cfg);
[model.mix.theta, model.mix.Sigma] = contrastBO.fitLogistic( ...
    Psi, double(resp < 0), cfg.mixPriorMean, cfg.mixPriorSD);

model.nTrials   = n;
model.nAnswered = sum(isAnswered);
end
