function choice = chooseContrasts(vs, qp, qpSet)
% MOCK of questplus.chooseContrasts (tests/dryRunCalibration): takes the
% default (last passed validation, otherwise the estimate from all trials)
% without asking. [added 2026-11-06]
[cand, iDef] = questplus.contrastCandidates(vs, qp, qpSet);
choice = cand(iDef);
choice.index = iDef;
end
