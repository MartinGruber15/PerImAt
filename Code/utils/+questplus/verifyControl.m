function [vs, qp, isFin, reason, est] = verifyControl(vs, qp, qpSet, nValid, nTotal, verbose)
% questplus.verifyControl  Calibrate -> validate procedure (qpSet.verify): phase control.
%
%   vs = questplus.verifyControl([], qp, qpSet)                 % initialise
%   [vs, qp, isFin, reason, est] = questplus.verifyControl(vs, qp, qpSet, nValid, nTotal, verbose)
%                                                               % after every trial
%
% 1. CALIBRATION ('adaptive'): QUEST+ trials (questplus.chooseNextTrial) until
%    the precision rule verify.calibrationRule is met (at least
%    qpSet.minValidTrials house/face trials), or after verify.maxCalibrationTrials
%    trials incl. mixed:
%      'sd'      : posterior SD of both balance points <= verify.sdCriterion (log2)
%      'balance' : SD of P(house) at the estimate <= verify.preCriterion in both
%                  eye configurations (with the slope floor qpSet.stopSlopeFloor)
% 2. VALIDATION ('verify'): vs.needBreak = true (the calibration script shows a
%    short break + fusion check), then verify.validationValidTrials house/face
%    trials at FIXED contrasts = the current posterior-mean balance points
%    (questplus.verifyNextTrial; eye configurations balanced, mixed trials
%    re-queued). Judged once on all its trials with exact two-sided binomial
%    tests against 0.5 of P(house) and of P(left-eye stimulus first)
%    (questplus.binomialSummary). Passed if both p >= verify.alpha.
%
% [changed 2026-11-06] With verify.askExperimenter = true, the end of the
% calibration and the end of every validation are DECISION POINTS: the phase
% becomes 'decide', vs.suggest says what the automatic procedure would do
% ('validate' | 'stop'), and nothing else happens until the calling script sets
% vs.action ('validate' | 'repeat' | 'stop', questplus.askExperimenter) and
% calls this function again:
%      'validate' -> break + (next) validation at the current estimate
%                    (at most verify.maxValidationsAsk validations)
%      'repeat'   -> [added 2026-11-06] break + (next) validation at exactly the
%                    contrasts of the previous validation (stability check)
%      'stop'     -> STOP; the experimenter chooses the contrasts to save
%                    (questplus.chooseContrasts)
% Without askExperimenter (automatic, as before):
%      passed -> STOP, "verified"; the tested contrasts are saved (vs.validatedU)
%      failed, fewer than verify.maxValidations -> break + new validation at
%        the updated estimate (posterior incl. all trials so far)
%      otherwise -> STOP, "NOT verified" (the estimate from all trials is saved)
% vs.verified: at least one validation passed; vs.validatedU: the contrasts
% tested in the LAST passed validation.
% All trials update the posterior. maxValidTrials / maxTotalTrials still stop
% the run ("NOT verified").
%
% vs.validations(k): xVerify, nHouse / nValid per eye configuration
% (HouseL+FaceR, FaceL+HouseR), nLeft, house / leftEye (binomialSummary:
% proportion, Wilson 95% CI, p value), passed, nValidAtEnd.
% vs.calibrationEnd: [uA uB], SD, nValid, nTotal at the end of the calibration.

if isempty(vs)
    vs = struct('phase', 'adaptive', 'validation', 0, 'valStartHist', NaN, 'valStartValid', NaN, ...
        'xVerify', [NaN NaN], 'needBreak', false, 'verified', false, 'validatedU', [NaN NaN], ...
        'validations', struct([]), 'calibrationPrecise', false, ...
        'decision', '', 'suggest', '', 'action', '', 'lastReason', '', ...   % [added 2026-11-06]
        'calibrationEnd', struct('u', [NaN NaN], 'sd', [NaN NaN], 'nValid', NaN, 'nTotal', NaN));
    isFin = false; reason = ''; est = [];
    return
end
if nargin < 6; verbose = true; end
v = qpSet.verify;
maxCal = Inf; if isfield(v, 'maxCalibrationTrials') && ~isempty(v.maxCalibrationTrials); maxCal = v.maxCalibrationTrials; end
alpha  = 0.05; if isfield(v, 'alpha') && ~isempty(v.alpha); alpha = v.alpha; end
ask = isfield(v, 'askExperimenter') && isequal(v.askExperimenter, true);
maxValAsk = v.maxValidations;
if isfield(v, 'maxValidationsAsk') && ~isempty(v.maxValidationsAsk); maxValAsk = max(v.maxValidationsAsk, v.maxValidations); end
isFin = false; reason = '';
est = questplus.estimates(qp, qpSet, false);

switch vs.phase
    case 'adaptive'
        rule = 'balance';
        if isfield(v, 'calibrationRule') && ~isempty(v.calibrationRule); rule = lower(v.calibrationRule); end
        switch rule
            case 'balance'   % SD of P(house) at the estimate (slope floor qpSet.stopSlopeFloor)
                precise = all(est.pAtEstimate.sd <= v.preCriterion);
                state = sprintf('SD of P(house) %.3f / %.3f, criterion %.2f', est.pAtEstimate.sd, v.preCriterion);
            case 'sd'        % posterior SD of both balance points (log2 contrast ratio)
                precise = max(est.uA.sd, est.uB.sd) <= v.sdCriterion;
                state = sprintf('SD of the balance points %.3f / %.3f log2, criterion %.2f', est.uA.sd, est.uB.sd, v.sdCriterion);
            otherwise
                error('questplus:verifyControl', 'Unknown verify.calibrationRule "%s".', rule);
        end
        precise = precise && nValid >= qpSet.minValidTrials;
        if precise || nTotal >= maxCal      % nTotal: calibration trials incl. mixed (first phase)
            vs.calibrationPrecise = precise;
            vs.calibrationEnd = struct('u', [est.uA.mean, est.uB.mean], 'sd', [est.uA.sd, est.uB.sd], ...
                'nValid', nValid, 'nTotal', nTotal);
            if verbose
                if precise
                    fprintf('\n=== Calibration done after %d house/face trials (%s).\n', nValid, state);
                else
                    fprintf(2, '\n=== Calibration limit of %d trials reached (%d house/face; %s).\n', nTotal, nValid, state);
                end
            end
            if ask
                vs = toDecision(vs, 'afterCalibration', 'validate', ...
                    'stopped by the experimenter after the calibration (no validation)');
            else
                vs = startValidation(vs, qp, est, nValid, verbose);
            end
        end
    case 'verify'
        nIn = nValid - vs.valStartValid;
        if nIn >= v.validationValidTrials
            [vs, b] = evaluateValidation(vs, qp, alpha, nValid);
            if verbose
                [~, cs] = questplus.textureCounts(qp.history(vs.valStartHist + 1:end, :));
                fprintf(['\n=== Validation %d (x = %+.3f / %+.3f): %s\n' ...
                    '    house %d/%d = %.0f%% (p = %.3f), left eye %d/%d = %.0f%% (p = %.3f), binomial vs 0.5, alpha %.2f -> %s\n'], ...
                    b.validation, b.xVerify, cs, b.house.k, b.house.n, 100 * b.house.p, b.house.pValue, ...
                    b.leftEye.k, b.leftEye.n, 100 * b.leftEye.p, b.leftEye.pValue, alpha, ternary(b.passed, 'PASSED', 'FAILED'));   % [changed 2026-11-11] + %
            end
            if b.passed
                vs.verified = true;
                vs.validatedU = vs.xVerify;                       % exactly the tested contrasts
                passReason = sprintf('verified: validation %d passed (house %d/%d, left eye %d/%d)', ...
                    b.validation, b.house.k, b.house.n, b.leftEye.k, b.leftEye.n);
            else
                passReason = sprintf('NOT verified: validation %d failed (house %d/%d, left eye %d/%d)', ...
                    b.validation, b.house.k, b.house.n, b.leftEye.k, b.leftEye.n);
                if vs.verified
                    passReason = sprintf('%s; an earlier validation passed', passReason);
                end
            end
            if ask
                if ~b.passed && vs.validation < v.maxValidations
                    sug = 'validate';
                else
                    sug = 'stop';
                end
                if vs.validation >= maxValAsk; sug = 'stop'; end
                vs = toDecision(vs, 'afterValidation', sug, passReason);
            elseif b.passed
                isFin = true; reason = passReason;
            elseif vs.validation < v.maxValidations
                if verbose
                    fprintf(2, '=== Validation failed: break, then a new validation at the updated estimate.\n');
                end
                vs = startValidation(vs, qp, est, nValid, verbose);
            else
                isFin = true;
                reason = sprintf('NOT verified: %d validation(s) failed', vs.validation);
            end
        end
    case 'decide'   % [added 2026-11-06] the experimenter's choice (vs.action)
        switch vs.action
            case {'validate', 'repeat'}
                if vs.validation >= maxValAsk
                    error('questplus:verifyControl', 'At most %d validations (verify.maxValidationsAsk).', maxValAsk);
                end
                if strcmp(vs.action, 'repeat')
                    if vs.validation < 1
                        error('questplus:verifyControl', '''repeat'' needs a previous validation.');
                    end
                    vs = startValidation(vs, qp, est, nValid, verbose, vs.xVerify);   % same contrasts again
                else
                    vs = startValidation(vs, qp, est, nValid, verbose);
                end
            case 'stop'
                isFin = true; reason = vs.lastReason;
            otherwise
                error('questplus:verifyControl', 'vs.action must be ''validate'', ''repeat'' or ''stop'' in the decide phase.');
        end
        vs.action = ''; vs.decision = ''; vs.suggest = '';
end
if ~isFin
    if nTotal >= qpSet.maxTotalTrials
        isFin = true; reason = sprintf('maxTotalTrials (%d) reached - %s', qpSet.maxTotalTrials, ...
            ternary(vs.verified, 'an earlier validation passed', 'NOT verified'));
    elseif nValid >= qpSet.maxValidTrials
        isFin = true; reason = sprintf('maxValidTrials (%d) reached - %s', qpSet.maxValidTrials, ...
            ternary(vs.verified, 'an earlier validation passed', 'NOT verified'));
    end
end
end


function vs = toDecision(vs, decision, suggest, lastReason)
% [added 2026-11-06] wait for the experimenter (questplus.askExperimenter)
vs.phase = 'decide';
vs.decision = decision;
vs.suggest = suggest;
vs.action = '';
vs.lastReason = lastReason;
end


function vs = startValidation(vs, qp, est, nValid, verbose, uFixed)
% fixed contrasts = current posterior-mean balance points (clipped to the range),
% or uFixed (= the contrasts of the previous validation, action 'repeat')
vs.validation = vs.validation + 1;
vs.phase = 'verify';
if nargin >= 6 && ~isempty(uFixed)
    vs.xVerify = uFixed;
    src = sprintf('same contrasts as validation %d', vs.validation - 1);
else
    vs.xVerify = min(max([est.uA.mean, est.uB.mean], -qp.xMax), qp.xMax);
    src = sprintf('estimate after %d house/face trials', nValid);
end
vs.valStartHist = size(qp.history, 1);
vs.valStartValid = nValid;
vs.needBreak = true;   % break (+ fusion check) before the validation, handled by the calling script
if verbose
    c = questplus.contrastsFromBalance((vs.xVerify(1) + vs.xVerify(2)) / 2, (vs.xVerify(1) - vs.xVerify(2)) / 2, qp.baseContrast);
    fprintf(['=== Break, then validation %d: fixed contrasts x = %+.3f (HouseL+FaceR), %+.3f (FaceL+HouseR)\n' ...
        '    = %s\n' ...
        '    (%s; SD of the current estimate %.3f / %.3f log2). The subject continues with any key.\n\n'], ...
        vs.validation, vs.xVerify, questplus.contrastText(c), src, est.uA.sd, est.uB.sd);
end
end


function [vs, b] = evaluateValidation(vs, qp, alpha, nValid)
H = qp.history(vs.valStartHist + 1:end, :);           % [houseEye x isHouse ...] of this validation
c = questplus.textureCounts(H);
nHouse = c.HouseL + c.HouseR;
b = struct('validation', vs.validation, 'xVerify', vs.xVerify, ...
    'nHouse', [c.HouseL, c.HouseR], 'nValid', [c.nA, c.nB], 'nLeft', c.left, ...
    'house', questplus.binomialSummary(nHouse, c.n), ...
    'leftEye', questplus.binomialSummary(c.left, c.n), ...
    'alpha', alpha, 'passed', false, 'nValidAtEnd', nValid);
b.passed = b.house.pValue >= alpha && b.leftEye.pValue >= alpha;
if isempty(vs.validations); vs.validations = b; else; vs.validations(end+1) = b; end
end


function out = ternary(c, a, b)
if c; out = a; else; out = b; end
end
