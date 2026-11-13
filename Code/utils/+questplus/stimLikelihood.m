function L = stimLikelihood(qp, c, xIdx)
% questplus.stimLikelihood  P(house | stimulus, parameters) for the next trial.
%
%   L = questplus.stimLikelihood(qp, c)          % nX x nParam, all x of configuration c
%   L = questplus.stimLikelihood(qp, c, xIdx)    % numel(xIdx) x nParam
%
% c = index in qp.houseEyeValues (1: HouseL+FaceR, 2: FaceL+HouseR). The
% likelihoods are precomputed once by questplus.initialise (single precision).

if nargin < 3 || isempty(xIdx)
    L = qp.likelihood{c};
else
    L = qp.likelihood{c}(xIdx, :);
end
end
