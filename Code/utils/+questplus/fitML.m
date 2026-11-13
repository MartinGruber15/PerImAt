function fit = fitML(data, lapse, start)
% questplus.fitML  Unconstrained maximum-likelihood refit of the balance model.
%
%   fit = questplus.fitML(data, lapse, start)
%
% data   N x 3 [houseEye, x, isHouse] (house/face trials only, = qp.history)
% lapse  fixed lapse rate (e.g. posterior mean from QUEST+)
% start  [thetaS thetaE slope] starting values (e.g. posterior means)
%
% Watson (2017, "Timing") recommends refining the quantised QUEST+
% estimates by an unconstrained, unquantised fit to the data. Here this is
% only a cross-check of the posterior means; it uses base-MATLAB fminsearch.
% With few trials the ML slope can run away (perfect separation); the slope
% is therefore bounded to [0.05, 50] and fit.slopeAtBound flags this.

if nargin < 3 || isempty(start); start = [0 0 3]; end
if isempty(data)
    fit = struct('thetaS', NaN, 'thetaE', NaN, 'slope', NaN, 'lapse', lapse, 'nll', NaN, ...
        'slopeAtBound', false, 'uA', NaN, 'uB', NaN, 'n', 0);
    return
end
houseEye = data(:,1); x = data(:,2); y = data(:,3) > 0.5;

nll = @(q) negLogLik(q, houseEye, x, y, lapse);
q0 = [start(1), start(2), log(max(start(3), 0.1))];
opts = optimset('Display', 'off', 'MaxFunEvals', 4000, 'MaxIter', 4000, 'TolX', 1e-6, 'TolFun', 1e-8);
q = fminsearch(nll, q0, opts);

fit.thetaS = q(1);
fit.thetaE = q(2);
fit.slope  = min(max(exp(q(3)), 0.05), 50);
fit.lapse  = lapse;
fit.nll    = nll(q);
fit.slopeAtBound = exp(q(3)) >= 50 || exp(q(3)) <= 0.05;
fit.uA = fit.thetaS + fit.thetaE;
fit.uB = fit.thetaS - fit.thetaE;
fit.n  = numel(y);
end


function v = negLogLik(q, houseEye, x, y, lapse)
slope = min(max(exp(q(3)), 0.05), 50);
p = questplus.model(x, houseEye, q(1), q(2), slope, lapse);
p = min(max(p, 1e-12), 1 - 1e-12);
v = -sum(log(p(y))) - sum(log(1 - p(~y)));
end
