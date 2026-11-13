function action = askExperimenter(vs, qp, qpSet, nValid, nTotal) %#ok<INUSL>
% MOCK of questplus.askExperimenter (tests/dryRunCalibration): takes the
% suggested step without asking (= the automatic procedure). [added 2026-11-06]
v = qpSet.verify;
maxValAsk = v.maxValidations;
if isfield(v, 'maxValidationsAsk') && ~isempty(v.maxValidationsAsk); maxValAsk = max(v.maxValidationsAsk, v.maxValidations); end
canValidate = vs.validation + 1 <= maxValAsk && nValid + v.validationValidTrials <= qpSet.maxValidTrials && ...
    nTotal + v.validationValidTrials <= qpSet.maxTotalTrials;
action = vs.suggest;
if strcmp(action, 'validate') && ~canValidate; action = 'stop'; end
end
