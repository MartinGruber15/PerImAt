function est = estimates(qp, qpSet, withCI, uFinal)
% questplus.estimates  Posterior summaries and the recommended contrasts.
%
%   est = questplus.estimates(qp, qpSet)
%   est = questplus.estimates(qp, qpSet, false)   % faster (used every trial by
%                                                 % isFinished): no credible intervals
%                                                 % and no prediction at the final contrasts
%
% est.thetaS / est.thetaE   stimulus / eye balance point (log2 units):
%                           .mean .sd .ci95 .marginal
% est.slope, est.lapse      posterior means of the nuisance parameters
% est.uA / est.uB           balance point of HouseL+FaceR / FaceL+HouseR (.mean .sd)
% est.pAtEstimate           posterior mean/SD of P(house) for both eye
%                           configurations at the (unrounded) posterior-mean
%                           balance point -> used by the 'balance' stop rule and
%                           verify.preCriterion. Computed with the slope of every
%                           grid point raised to at least qpSet.stopSlopeFloor
%                           (0/absent = posterior slope as is), see getQuestPlusSettings
% est.final                 recommended solution (posterior means, or the
%                           validated balance points uFinal), its four contrast factors,
%                           the four texture contrasts and the predicted P(house)
% est.entropyBits           entropy of the marginal (thetaS,thetaE) and the joint posterior
%
% Point estimates are posterior means, which (unlike the posterior mode)
% are not quantised to the parameter grid (cf. QuestPlus.getParamEsts with
% thresholdingRule 'mean', petejonze/QuestPlus).

if nargin < 3; withCI = true; end
if nargin < 4; uFinal = []; end   % [uA uB]: use these (validated) balance points as the final solution
w = qp.posterior;
Pn = reshape(w, [qp.dims 1]);

%% Marginals of interest ---------------------------------------------------
mS = marginal(Pn, 1);                             % 1 x nThetaS
mE = marginal(Pn, 2);                             % 1 x nThetaE
est.thetaS = summarise(qp.thetaS, mS);
est.thetaE = summarise(qp.thetaE, mE);
mSl = marginal(Pn, 3);
mLa = marginal(Pn, 4);
est.slope = summarise(qp.slope, mSl);
est.lapse = summarise(qp.lapse, mLa);

est.uA.mean = w * qp.uA';
est.uB.mean = w * qp.uB';
est.uA.sd = sqrt(w * ((qp.uA - est.uA.mean).^2)');
est.uB.sd = sqrt(w * ((qp.uB - est.uB.mean).^2)');

%% Uncertainty of P(house) at the current balance estimate -----------------
uHat = [est.uA.mean, est.uB.mean];
slopeFloor = 0;
if isfield(qpSet, 'stopSlopeFloor') && ~isempty(qpSet.stopSlopeFloor); slopeFloor = qpSet.stopSlopeFloor; end
est.pAtEstimate = predictP(qp, uHat, withCI, slopeFloor);
est.pAtEstimate.slopeFloor = slopeFloor;

%% Recommended solution ----------------------------------------------------
uRec = uHat;
if ~isempty(uFinal) && all(isfinite(uFinal))
    uRec = uFinal;
end
est.final.outOfRange = abs(uHat) > qp.xMax + 1e-9;   % [HouseL/FaceR, FaceL/HouseR]
uRec = min(max(uRec, -qp.xMax), qp.xMax);
est.final.uA = uRec(1);
est.final.uB = uRec(2);
est.final.thetaS = (uRec(1) + uRec(2)) / 2;   % log2 house/face
est.final.thetaE = (uRec(1) - uRec(2)) / 2;   % log2 left/right
est.final.contrasts = questplus.contrastsFromBalance(est.final.thetaS, est.final.thetaE, qp.baseContrast);
if withCI
    est.final.pHouse = predictP(qp, uRec, true);
else
    est.final.pHouse = struct('x', uRec, 'mean', [NaN NaN], 'sd', [NaN NaN], 'ci95', nan(2, 2));
end
% probability that the stimulus in the LEFT eye is perceived first (50:50 design)
pA = est.final.pHouse.mean(1); pB = est.final.pHouse.mean(2);
est.final.pHouseOverall = (pA + pB) / 2;
est.final.pLeftEyeWins  = (pA + (1 - pB)) / 2;

%% Entropy -----------------------------------------------------------------
mInt = sum(reshape(w, qp.nInterest, qp.nNuisance), 2);
est.entropyBits.marginal = entropyBits(mInt);
est.entropyBits.joint    = entropyBits(w);
est.nUpdates = qp.nUpdates;
end


function m = marginal(Pn, k)
% marginal distribution of grid dimension k (row vector)
nd = max(ndims(Pn), k);
m = sum(reshape(permute(Pn, [k, setdiff(1:nd, k)]), size(Pn, k), []), 2)';
end


function s = summarise(values, pmf)
pmf = pmf / sum(pmf);
s.mean = pmf * values(:);
s.sd   = sqrt(max(pmf * ((values(:) - s.mean).^2), 0));
c = cumsum(pmf);
s.ci95 = [values(find(c >= 0.025, 1, 'first')), values(find(c >= 0.975, 1, 'first'))];
s.values = values;
s.marginal = pmf;
end


function out = predictP(qp, u, withCI, slopeFloor)
% posterior distribution of P(house) for both configurations at x = u(c)
% slopeFloor > 0: slope of every grid point raised to at least slopeFloor
% (only for the stop criterion; predictions use the posterior slope)
if nargin < 4 || isempty(slopeFloor); slopeFloor = 0; end
out.x = u;
out.mean = zeros(1, 2); out.sd = zeros(1, 2); out.ci95 = nan(2, 2);
w = qp.posterior;
slope = qp.P(3,:);
if slopeFloor > 0; slope = max(slope, slopeFloor); end
for c = 1:2
    p = questplus.model(u(c), qp.houseEyeValues(c), qp.P(1,:), qp.P(2,:), slope, qp.P(4,:));
    m = w * p';
    out.mean(c) = m;
    out.sd(c)   = sqrt(max(w * ((p - m).^2)', 0));
    if withCI
        [ps, order] = sort(p);
        cw = cumsum(w(order));
        out.ci95(c, :) = [ps(find(cw >= 0.025, 1, 'first')), ps(find(cw >= 0.975, 1, 'first'))];
    end
end
end


function H = entropyBits(p)
p = p(p > 0);
p = p / sum(p);
H = -sum(p .* log2(p));
end
