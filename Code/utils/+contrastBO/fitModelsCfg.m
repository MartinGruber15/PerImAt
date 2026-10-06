function model = fitModelsCfg(X, houseLeft, resp, cfg)
% fitModelsCfg  'perConfig' model: update the balance and mixed models with all trials.
%
%   X          n x 4   contrasts [g s e i] of each trial
%   houseLeft  n x 1   true: pair A shown (house left + face right)
%   resp       n x 1   1 = house reported, 0 = face reported, -1 = mixed/none
%
% model.bal : posterior of the house-vs-face model per pair (answered trials only)
% model.mix : posterior of the mixed-percept model per pair (all trials)
%
% Both are Bayesian logistic regressions in the level and house-face
% difference of the pair that was shown (see defaultSettings for the
% parameters and priors).  The pair-specific parameters share one common part
% plus a deviation with a tight prior (partial pooling): with little data the
% two pairs behave alike (like model 'shared'), with more data they separate.

n = size(X, 1);
if n == 0
    X = zeros(0, 4);  houseLeft = false(0, 1);  resp = zeros(0, 1);
end
resp = resp(:);  houseLeft = logical(houseLeft(:));
[ell, d] = contrastBO.configFeatures(X, houseLeft);
[PhiB, PhiM] = contrastBO.cfgDesign(ell, d, houseLeft, cfg);

isAns = resp >= 0;
[model.bal.theta, model.bal.Sigma] = contrastBO.fitLogistic( ...
    PhiB(isAns, :), resp(isAns), cfg.cfgBalPriorMean, cfg.cfgBalPriorSD);
[model.mix.theta, model.mix.Sigma] = contrastBO.fitLogistic( ...
    PhiM, double(resp < 0), cfg.cfgMixPriorMean, cfg.cfgMixPriorSD);

model.nTrials   = n;
model.nAnswered = sum(isAns);
end
