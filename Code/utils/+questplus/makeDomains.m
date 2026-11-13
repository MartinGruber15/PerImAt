function qp = makeDomains(qpSet, priorCentre)
% questplus.makeDomains  Stimulus domain, parameter grid and prior of the balance model.
%
%   qp = questplus.makeDomains(qpSet)
%   qp = questplus.makeDomains(qpSet, priorCentre)
%
% Called by questplus.initialise.
%   qp.xDomain, qp.xMax, qp.stepLog2, qp.baseContrast, qp.houseEyeValues = [1 -1]
%   qp.thetaS, qp.thetaE, qp.slope, qp.lapse, qp.dims, qp.nInterest, qp.nNuisance
%   qp.P              4 x nParam (rows thetaS, thetaE, slope, lapse; thetaS varies fastest)
%   qp.uA, qp.uB      balance points of HouseL+FaceR / FaceL+HouseR per parameter combination
%   qp.prior, qp.posterior (= prior), qp.priorUsed, qp.priorMarginals (normalised, per parameter)

if nargin < 2; priorCentre = struct(); end
pr = qpSet.prior;
if isfield(priorCentre, 'houseFaceRatio'); pr.houseFaceRatio = priorCentre.houseFaceRatio; end
if isfield(priorCentre, 'leftRightRatio'); pr.leftRightRatio = priorCentre.leftRightRatio; end

%% Stimulus domain -------------------------------------------------------
% On a trial the two rivalling textures get c0*2^(+x/2) (house) and
% c0*2^(-x/2) (face). Both must lie in [minTextureContrast, maxTextureContrast].
c0 = qpSet.baseContrast;
xMax = 2 * min(log2(qpSet.maxTextureContrast / c0), log2(c0 / qpSet.minTextureContrast));
assert(xMax > 0, 'questplus:makeDomains', 'baseContrast must lie strictly inside [min,max]TextureContrast.');
nX = floor(xMax / qpSet.stepLog2 + 1e-9);
qp.xDomain   = (-nX:nX) * qpSet.stepLog2;   % integer multiples -> exact grid values
qp.xMax      = nX * qpSet.stepLog2;
qp.stepLog2  = qpSet.stepLog2;
qp.baseContrast = c0;
qp.houseEyeValues = [1 -1];

%% Parameter domain ------------------------------------------------------
thetaStep = qpSet.thetaStepLog2;
nT = round(qpSet.thetaRangeLog2 / thetaStep);
qp.thetaS = (-nT:nT) * thetaStep;
qp.thetaE = qp.thetaS;
qp.slope  = qpSet.slopeValues(:)';
qp.lapse  = qpSet.lapseValues(:)';
qp.dims   = [numel(qp.thetaS) numel(qp.thetaE) numel(qp.slope) numel(qp.lapse)];
qp.nInterest = qp.dims(1) * qp.dims(2);   % (thetaS, thetaE): parameters of interest
qp.nNuisance = prod(qp.dims(3:end));      % (slope, lapse): nuisance parameters

[TS, TE, SL, LA] = ndgrid(qp.thetaS, qp.thetaE, qp.slope, qp.lapse);
qp.P = [TS(:)'; TE(:)'; SL(:)'; LA(:)'];
clear TS TE SL LA
qp.uA = qp.P(1,:) + qp.P(2,:);   % balance point HouseL+FaceR (x at P(house)=.5)
qp.uB = qp.P(1,:) - qp.P(2,:);   % balance point FaceL+HouseR

%% Prior (independent marginals, as in QuestPlus.initialise) -------------
muS = log2(pr.houseFaceRatio);
muE = log2(pr.leftRightRatio);
pS  = exp(-0.5 * ((qp.thetaS - muS) / pr.sdStimLog2).^2);
pE  = exp(-0.5 * ((qp.thetaE - muE) / pr.sdEyeLog2).^2);
pSl = exp(-0.5 * ((log(qp.slope) - log(pr.slopeMedian)) / pr.slopeSdLn).^2);
pLa = pr.lapseWeights(:)';
assert(numel(pLa) == numel(qp.lapse), 'questplus:makeDomains', 'prior.lapseWeights needs one entry per lapseValues entry.');
[PS, PE, PSL, PLA] = ndgrid(pS, pE, pSl, pLa);
prior = PS(:)' .* PE(:)' .* PSL(:)' .* PLA(:)';
qp.prior = prior / sum(prior);
qp.posterior = qp.prior;
qp.priorUsed = pr;
qp.priorMarginals = {pS / sum(pS), pE / sum(pE), pSl / sum(pSl), pLa / sum(pLa)};   % (thetaS, thetaE, slope, lapse)
end
