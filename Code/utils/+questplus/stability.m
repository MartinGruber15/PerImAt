function S = stability(history, thetaGrid, slope, lapse, nParts)
% questplus.stability  Did the balance points change during the run?
%
%   S = questplus.stability(qp.history, qp.thetaS, est.slope.mean, est.lapse.mean)
%   S = questplus.stability(history, thetaGrid, slope, lapse, nParts)
%
% The house/face trials of the run (calibration + validation, in order) are
% split into nParts consecutive parts of equal size (default: parts of
% about 30 trials, at least 2 parts; shorter parts are too imprecise,
% longer ones average out fluctuations like those of sub-01). For each part, thetaS
% and thetaE are estimated from that part alone (flat prior on the QUEST+
% grid, slope and lapse fixed at the values of the whole run). A
% chi-square test (df = nParts-1) asks whether the parts differ more than
% expected by chance.
%
% Diagnostic only - the saved contrasts always use all trials, i.e. they
% match the AVERAGE state over the run, which is what the main experiment
% needs if the balance fluctuates. A changing eye balance (drift,
% adaptation, head position) shows up as a small pThetaE: the estimate is
% then an average over different states, and the validation at the end
% only tells you about the last part.
%
% S.parts(k): trials (first/last index in history), n, thetaS/thetaE .mean .sd
% S.pThetaS, S.pThetaE: p of the chi-square test; S.maxDiffThetaE: largest
% difference between two parts (log2).

n = size(history, 1);
if nargin < 5 || isempty(nParts); nParts = max(2, floor(n / 30)); end
S = struct('nParts', nParts, 'parts', struct([]), 'pThetaS', NaN, 'pThetaE', NaN, 'maxDiffThetaE', NaN);
if n < 15 * nParts; return; end   % too few trials for a meaningful split
[TS, TE] = ndgrid(thetaGrid, thetaGrid);
edges = round(linspace(0, n, nParts + 1));
for k = 1:nParts
    rows = edges(k) + 1:edges(k + 1);
    logL = zeros(size(TS));
    for i = rows
        p = questplus.model(history(i, 2), history(i, 1), TS, TE, slope, lapse);
        if history(i, 3) > 0.5; logL = logL + log(p); else; logL = logL + log(1 - p); end
    end
    w = exp(logL - max(logL(:)));
    w = w / sum(w(:));
    part.trials = [rows(1) rows(end)];
    part.n = numel(rows);
    part.thetaS = moments(TS, w);
    part.thetaE = moments(TE, w);
    if k == 1; S.parts = part; else; S.parts(k) = part; end
end
S.pThetaS = chi2p([S.parts.thetaS]);
S.pThetaE = chi2p([S.parts.thetaE]);
m = arrayfun(@(q) q.thetaE.mean, S.parts);
S.maxDiffThetaE = max(m) - min(m);
end


function s = moments(T, w)
s.mean = sum(w(:) .* T(:));
s.sd = sqrt(sum(w(:) .* (T(:) - s.mean).^2));
end


function p = chi2p(est)
% chi-square test of equal means (inverse-variance weights), df = K - 1
mu = [est.mean]; v = max([est.sd], 1e-6).^2;
wt = 1 ./ v;
m = sum(wt .* mu) / sum(wt);
chi2 = sum(wt .* (mu - m).^2);
df = numel(mu) - 1;
p = 1 - gammainc(chi2 / 2, df / 2);   % upper tail of the chi-square distribution
end
