function [x, xIdx, houseEye, EH] = selectStimulus(qp, qpSet, houseEye, exclude)
% questplus.selectStimulus  Minimum-expected-entropy contrast ratio for the next trial.
%
%   [x, xIdx, houseEye, EH] = questplus.selectStimulus(qp, qpSet, houseEye, exclude)
%
% houseEye  +1 / -1: eye configuration fixed by the trial schedule
%           (questplus.schedule); QUEST+ chooses the contrast ratio x.
% exclude   (optional) logical [numel(qp.xDomain) x 2]: stimuli (x, column =
%           index in qp.houseEyeValues) that must not be chosen, e.g. those
%           that just got a 'mixed' response (questplus.chooseNextTrial).
%           Ignored if it would exclude every admissible stimulus.
% Returns the chosen x (log2 house/face ratio of the shown textures), its
% index in qp.xDomain, the eye configuration and the expected entropies.
%
% QUEST+ placement rule (Watson, 2017, J Vis 17(3):10, Eq. 4-7):
%   p_k(r|x)   = sum_s P_k(s) p(r|x,s)                      (Eq. 4)
%   H_k(r,x)   = -sum_s P_k(s|r,x) log P_k(s|r,x)            (Eq. 5/6)
%   EH_k(x)    = sum_r p_k(r|x) H_k(r,x)                     (Eq. 7)
%   x_{k+1}    = argmin_x EH_k(x)
% Vectorised as in petejonze/QuestPlus (QuestPlus.getTargetStim).
%
% The entropy is computed on the posterior of the two parameters of interest
% (stimulus and eye balance), marginalised over the nuisance parameters
% (slope, lapse), so that trials are placed to learn the two
% balance points rather than the slope ("psi-marginal" method: Prins, 2013,
% J Vis 13(7):3).

if nargin < 4; exclude = []; end
c = find(qp.houseEyeValues == houseEye);
assert(~isempty(c), 'questplus:selectStimulus', 'houseEye must be +1 or -1.');

nX = numel(qp.xDomain);
EHall = inf(nX, 2);
EHall(:, c) = expectedEntropy(qp, questplus.stimLikelihood(qp, c));

% ---- choose: the minimum (ties broken at random) ---------------------------
if ~isempty(exclude)
    EHx = EHall; EHx(exclude) = Inf;
    if any(isfinite(EHx(:))); EHall = EHx; end
end
EHvec = EHall(:);
minEH = min(EHvec);
tol   = 1e-9 * max(1, abs(minEH));
candidates = find(EHvec <= minEH + tol);   % minimum expected entropy; ties -> random choice
pick = candidates(randi(numel(candidates)));
[xIdx, c] = ind2sub([nX 2], pick);
x = qp.xDomain(xIdx);
houseEye = qp.houseEyeValues(c);
EH = EHall(:, c);
end


function EH = expectedEntropy(qp, L)
% L: nX x nParam likelihood of 'house'
post = qp.posterior;
jointH = L .* post;              % unnormalised posterior after 'house'  [nX x nParam]
jointF = post - jointH;          % ... after 'face'  ((1-L).*post)
pkH = sum(jointH, 2);            % Eq. 4: predictive probability of 'house' at each x
pkF = sum(jointF, 2);
% marginalise over the nuisance parameters: the parameter index is ordered
% with (thetaS, thetaE) varying fastest
jointH = sum(reshape(jointH, [], qp.nInterest, qp.nNuisance), 3);
jointF = sum(reshape(jointF, [], qp.nInterest, qp.nNuisance), 3);

HH = rowEntropy(jointH, pkH);
HF = rowEntropy(jointF, pkF);
EH = pkH .* HH + pkF .* HF;      % Eq. 7
end


function H = rowEntropy(J, rowSum)
% entropy (nats) of each row of J after normalisation by rowSum; 0*log(0) = 0
Pn = J ./ rowSum;
T = Pn .* log(Pn);
T(~(Pn > 0)) = 0;
H = -sum(T, 2);
H(~(rowSum > 0)) = 0;            % outcome impossible -> weight 0 anyway
end
