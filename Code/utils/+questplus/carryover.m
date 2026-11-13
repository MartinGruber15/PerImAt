function co = carryover(trials, doPrint)
% questplus.carryover  Trial-to-trial carry-over of the winning EYE.
%
%   co = questplus.carryover(trials)        % struct only
%   questplus.carryover(trials, true)       % also prints a short report
%
% QUEST+ assumes independent trials. In the pilot data (sub-43, sub-45) the
% first percept followed the EYE that won on the previous trial far more
% often than chance (P(same eye) 0.63-0.87; the stimulus itself repeated
% less than chance because the eye configuration alternates), with runs of
% up to 21-25 trials in which one eye won regardless of contrast. Such runs
% make the data much less informative than their number suggests and make
% the estimates depend on which eye "state" the run happened to be in.
%
% Uses the house/face trials only (mixed and warm-up trials removed).
% Fields of co:
%   n              number of trials used
%   eyeSequence    'L'/'R' = eye whose stimulus was reported, in trial order
%   pLeftWins      proportion left-eye stimulus reported
%   pSameEye       P(same eye wins as on the previous trial)
%   pSameEyeIndep  same, expected for independent trials (p^2 + (1-p)^2)
%   pSameStim      P(same stimulus reported as on the previous trial)
%   longestEyeRun  longest run of one eye
%   rho            lag-1 autocorrelation of "left eye won"
%   nEff           effective number of independent trials, n*(1-rho)/(1+rho)
%                  (AR(1) approximation, rho >= 0)
%   flag           true if longestEyeRun >= 10 or pSameEye exceeds the
%                  independent expectation by >= 0.2 (with n >= 20)

if nargin < 2; doPrint = false; end
if isempty(trials) || ~isstruct(trials)
    co = struct('n', 0, 'eyeSequence', '', 'pLeftWins', NaN, 'pSameEye', NaN, 'pSameEyeIndep', NaN, ...
        'pSameStim', NaN, 'longestEyeRun', 0, 'rho', NaN, 'nEff', 0, 'flag', false);
    return
end
if isfield(trials, 'isWarmup')   % runs saved with warm-up trials
    trials = trials(~[trials.isWarmup]);
end
resp = {trials.response};
isH = strcmp(resp, 'house'); isF = strcmp(resp, 'face');
valid = isH | isF;
houseLeft = [trials.houseEye] == 1;
leftWins = (houseLeft(valid) & isH(valid)) | (~houseLeft(valid) & isF(valid));
house = isH(valid);
n = numel(leftWins);

co = struct('n', n, 'eyeSequence', char('R' + ('L' - 'R') * leftWins), ...
    'pLeftWins', NaN, 'pSameEye', NaN, 'pSameEyeIndep', NaN, 'pSameStim', NaN, ...
    'longestEyeRun', 0, 'rho', NaN, 'nEff', n, 'flag', false);
if n == 0; return; end
p = mean(leftWins);
co.pLeftWins = p;
co.longestEyeRun = max(diff([find([true, diff(leftWins) ~= 0]), n + 1]));
if n >= 2
    co.pSameEye = mean(leftWins(2:end) == leftWins(1:end-1));
    co.pSameEyeIndep = p^2 + (1 - p)^2;
    co.pSameStim = mean(house(2:end) == house(1:end-1));
    a = double(leftWins(1:end-1)); b = double(leftWins(2:end));
    if std(a) > 0 && std(b) > 0
        r = corrcoef(a, b); co.rho = r(1, 2);
    else
        co.rho = 1;                      % one eye won every trial
    end
    rhoPos = min(max(co.rho, 0), 0.99);
    co.nEff = n * (1 - rhoPos) / (1 + rhoPos);
end
co.flag = co.longestEyeRun >= 10 || (n >= 20 && co.pSameEye - co.pSameEyeIndep >= 0.2);

if doPrint
    fprintf('Eye carry-over (house/face trials):\n');
    fprintf('  winning eye per trial: %s\n', co.eyeSequence);
    fprintf('  P(same eye as previous trial) %.2f (independent trials: %.2f), P(same stimulus) %.2f\n', ...
        co.pSameEye, co.pSameEyeIndep, co.pSameStim);
    fprintf('  longest run of one eye %d, lag-1 autocorrelation %.2f -> ~%.0f effective of %d trials\n', ...
        co.longestEyeRun, co.rho, co.nEff, n);
    if co.flag
        fprintf(2, ['WARNING: one eye won up to %d trials in a row (eye carry-over or a strong eye\n' ...
            'imbalance). Results from such a run reflect the eye state(s) it happened to be in and\n' ...
            'are less reliable than the trial count suggests. Check head/chin rest and fusion\n' ...
            '(re-align), give a short break and re-run before relying on these contrasts.\n'], co.longestEyeRun);
    end
end
end
