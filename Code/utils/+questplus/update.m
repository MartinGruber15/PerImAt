function qp = update(qp, houseEye, x, isHouse)
% questplus.update  Bayesian update of the posterior after a house/face response.
%
%   qp = questplus.update(qp, houseEye, x, isHouse)
%
% houseEye  +1 (HouseL+FaceR) or -1 (FaceL+HouseR)
% x         presented log2 house/face contrast ratio (grid value, or any value
%           for validation trials)
% isHouse   true = first percept house, false = first percept face
%
% Mixed percepts must NOT be passed here (they are not part of the model).
%
% Posterior after trial k+1 = posterior after trial k times the likelihood
% of the new outcome, renormalised (Watson, 2017, Eq. 3; petejonze/QuestPlus,
% QuestPlus.update).

c = find(qp.houseEyeValues == houseEye, 1);
assert(~isempty(c), 'questplus:update', 'houseEye must be +1 or -1.');
[d, xIdx] = min(abs(qp.xDomain - x));
if d < 1e-9
    x = qp.xDomain(xIdx);
    lik = double(questplus.stimLikelihood(qp, c, xIdx));
else
    % x off the grid (validation trials at the current estimate): computed directly
    P = qp.P;
    lik = questplus.model(x, houseEye, P(1,:), P(2,:), P(3,:), P(4,:));
end
if ~isHouse
    lik = 1 - lik;
end
post = qp.posterior .* lik;
qp.posterior = post / sum(post);
qp.nUpdates = qp.nUpdates + 1;
qp.history(end+1, :) = [houseEye, x, double(isHouse)];
end
