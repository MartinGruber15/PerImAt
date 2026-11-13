function [cand, iDefault] = contrastCandidates(vs, qp, qpSet)
% questplus.contrastCandidates  Contrast sets the experimenter can choose from. [added 2026-11-06]
%
%   [cand, iDefault] = questplus.contrastCandidates(vs, qp, qpSet)
%
% cand(k): label, u ([uA uB] balance points, log2 house/face of HouseL+FaceR /
% FaceL+HouseR), contrasts (questplus.contrastsFromBalance: the four values of
% the settings), pHouse (predicted P(house) for both eye configurations,
% posterior incl. ALL trials so far), pLeft (predicted P(left-eye stimulus first)).
%   1   current estimate from all trials (posterior mean)
%   2.. contrasts tested in validation 1, 2, ... (+ result); validation 1 tests
%       the estimate at the end of the calibration
% iDefault: the contrasts of the last PASSED validation, otherwise 1.
% vs = state of questplus.verifyControl ([] -> only the current estimate).

est = questplus.estimates(qp, qpSet, true);
cand = makeCand('estimate from all trials so far (posterior mean)', [est.uA.mean, est.uB.mean], qp, qpSet);
iDefault = 1;
if isempty(vs); return; end
nVal = numel(vs.validations);
for k = 1:nVal
    b = vs.validations(k);
    res = 'FAILED'; if b.passed; res = 'PASSED'; end
    lab = sprintf('tested in validation %d: %s (house %d/%d, left eye %d/%d)', ...
        b.validation, res, b.house.k, b.house.n, b.leftEye.k, b.leftEye.n);
    if k == 1; lab = [lab ' = end of the calibration']; end
    cand(end+1) = makeCand(lab, b.xVerify, qp, qpSet); %#ok<AGROW>
    if b.passed; iDefault = numel(cand); end
end
end


function c = makeCand(label, u, qp, qpSet)
u = min(max(u, -qp.xMax), qp.xMax);
e = questplus.estimates(qp, qpSet, true, u);
c.label = label;
c.u = u;
c.contrasts = questplus.contrastsFromBalance((u(1) + u(2)) / 2, (u(1) - u(2)) / 2, qp.baseContrast);
c.pHouse = e.final.pHouse.mean;
c.pLeft = e.final.pLeftEyeWins;
end
