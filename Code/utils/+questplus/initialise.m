function qp = initialise(qpSet, priorCentre)
% questplus.initialise  Build stimulus/parameter domains, prior and likelihoods.
%
%   qp = questplus.initialise(qpSet)
%   qp = questplus.initialise(qpSet, priorCentre)
%
% qpSet        settings from getQuestPlusSettings
% priorCentre  optional struct with fields houseFaceRatio / leftRightRatio
%              that overrides qpSet.prior (e.g. from the latest training file)
%
% Returns the QUEST+ state struct qp:
%   qp.xDomain        stimulus domain (log2 house/face ratio of the shown pair)
%   qp.houseEyeValues [+1 -1] (HouseL+FaceR, FaceL+HouseR)
%   qp.thetaS, qp.thetaE, qp.slope, qp.lapse   parameter grids
%   qp.P              4 x nParam matrix with all parameter combinations
%                     (rows: thetaS, thetaE, slope, lapse; thetaS varies fastest)
%   qp.likelihood{c}  nX x nParam, P(house | x, houseEye(c), params)
%   qp.prior, qp.posterior   1 x nParam
%
% Implementation follows Watson (2017) QUEST+, J Vis 17(3):10 (the
% likelihood array of "each outcome at each stimulus value for each
% parameter value", computed once at the start) and the MATLAB port by
% P. R. Jones (https://github.com/petejonze/QuestPlus, QuestPlus.initialise),
% re-implemented here without the Deep Learning / Statistics Toolbox
% dependencies of that port (combvec, nansum, randsample).

if nargin < 2; priorCentre = struct(); end
qp = questplus.makeDomains(qpSet, priorCentre);

%% Likelihoods -----------------------------------------------------------
% Binary outcome: P(house) is stored, P(face) = 1 - P(house).
% (Mixed responses are not modelled: they carry no information about the
% balance and are never passed to questplus.update.)
% Stored in single precision to halve the memory (~15 MB per eye
% configuration with the default grids); the posterior itself is double.
qp.likelihood = cell(1, 2);
for c = 1:2
    qp.likelihood{c} = single(questplus.model(qp.xDomain(:), qp.houseEyeValues(c), ...
        qp.P(1,:), qp.P(2,:), qp.P(3,:), qp.P(4,:)));
end

%% Book-keeping ----------------------------------------------------------
qp.nUpdates = 0;
qp.history  = zeros(0, 3);   % [houseEye, x, response (1 house / 0 face)] of every house/face trial
end
