function action = askExperimenter(vs, qp, qpSet, nValid, nTotal)
% questplus.askExperimenter  Decision point of the calibration (verify.askExperimenter). [added 2026-11-06]
%
%   action = questplus.askExperimenter(vs, qp, qpSet, nValid, nTotal)
%
% Called by questPlusCalibration at the end of the calibration and after every
% validation (questplus.verifyControl sets vs.phase = 'decide'). Shows where the
% run stands - the current contrasts (house, face, left eye, right eye, as they
% are entered in the settings), those tested in each validation and the
% predicted P(house) / P(left eye first) - and asks the experimenter in the
% command window:
%   Enter = the suggested step (vs.suggest: what the automatic procedure would do)
%   v     = (next) validation at the current estimate
%   r     = [added 2026-11-06] (next) validation at exactly the contrasts of the
%           previous validation (only after a validation): stability check
%   s     = stop; the contrasts to save are chosen afterwards (questplus.chooseContrasts)
% Returns 'validate', 'repeat' or 'stop'. The subject sees a "short break" screen
% meanwhile (questplus.breakText 'wait').

v = qpSet.verify;
maxValAsk = v.maxValidations;
if isfield(v, 'maxValidationsAsk') && ~isempty(v.maxValidationsAsk); maxValAsk = max(v.maxValidationsAsk, v.maxValidations); end
nextVal = vs.validation + 1;
budgetOK = nValid + v.validationValidTrials <= qpSet.maxValidTrials && ...
    nTotal + v.validationValidTrials <= qpSet.maxTotalTrials;
canValidate = nextVal <= maxValAsk && budgetOK;

fprintf('\n=================================================\n');
switch vs.decision
    case 'afterCalibration'
        fprintf('  END OF THE CALIBRATION (%d house/face trials, %d incl. mixed)\n', nValid, nTotal);
    otherwise
        b = vs.validations(end);
        res = 'FAILED'; if b.passed; res = 'PASSED'; end
        % [changed 2026-11-11] + percentages and how often each texture was seen first
        fprintf('  END OF VALIDATION %d: %s (house %d/%d = %.0f%%, p = %.3f | left eye %d/%d = %.0f%%, p = %.3f)\n', ...
            b.validation, res, b.house.k, b.house.n, 100 * b.house.p, b.house.pValue, ...
            b.leftEye.k, b.leftEye.n, 100 * b.leftEye.p, b.leftEye.pValue);
        fprintf('  seen first: HouseL %d/%d, FaceR %d/%d (HouseL+FaceR) | FaceL %d/%d, HouseR %d/%d (FaceL+HouseR)\n', ...
            b.nHouse(1), b.nValid(1), b.nValid(1) - b.nHouse(1), b.nValid(1), ...
            b.nValid(2) - b.nHouse(2), b.nValid(2), b.nHouse(2), b.nValid(2));
end
fprintf('=================================================\n');
[cand, iDef] = questplus.contrastCandidates(vs, qp, qpSet);
questplus.printCandidates(cand, iDef);
fprintf('  (* = the contrasts that would be proposed for saving now)\n');

fprintf('\nNext step:\n');
canRepeat = canValidate && vs.validation >= 1;
if canValidate
    if vs.validation >= 1
        fprintf('  v      validation %d at contrasts 1 (updated estimate from all trials, incl. the validation trials)\n', nextVal);
    else
        fprintf('  v      validation %d at contrasts 1 (current estimate)\n', nextVal);
    end
end
if canRepeat
    fprintf('  r      validation %d at the SAME contrasts as validation %d (stability check)\n', nextVal, vs.validation);
end
if ~canValidate && nextVal > maxValAsk
    fprintf('  (no further validation: at most %d, verify.maxValidationsAsk)\n', maxValAsk);
elseif ~canValidate
    fprintf('  (no further validation: trial limit maxValidTrials/maxTotalTrials would be exceeded)\n');
end
fprintf('  s      stop here and choose the contrasts to save (next: list as above, then confirm with Enter)\n');
suggest = vs.suggest;
if strcmp(suggest, 'validate') && ~canValidate; suggest = 'stop'; end
if strcmp(suggest, 'validate')
    sugText = sprintf('v (validation %d)', nextVal);
else
    sugText = 's (stop)';
end
fprintf('  Enter  = %s\n', sugText);

try FlushEvents('keyDown'); catch; end   % keys the subject pressed during the trials
while true
    a = lower(strtrim(input('Your choice: ', 's')));
    if isempty(a); a = suggest(1); end
    if strcmp(a, 'v') && canValidate
        action = 'validate'; break
    elseif strcmp(a, 'r') && canRepeat
        action = 'repeat'; break
    elseif strcmp(a, 's')
        action = 'stop'; break
    elseif any(strcmp(a, {'v', 'r'}))
        fprintf('Not possible here (see above). Type s or press Enter.\n');
    else
        fprintf('Please type v, r or s, or press Enter.\n');
    end
end
if any(strcmp(action, {'validate', 'repeat'}))
    fprintf('-> validation %d. The subject continues with any key after the break screen.\n', nextVal);
else
    fprintf('-> stop.\n');
end
end
