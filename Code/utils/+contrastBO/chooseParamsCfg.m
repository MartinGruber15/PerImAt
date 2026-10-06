function x = chooseParamsCfg(model, cfg, mode)
% chooseParamsCfg  'perConfig' model: contrasts [g s e i] to use next / best estimate.
%
%   x = contrastBO.chooseParams(model, cfg, 'sample')   next trial (Thompson sampling)
%   x = contrastBO.chooseParams(model, cfg, 'map')      current best estimate
%
% One plausible parameter set is drawn from each model's posterior ('sample')
% or the most probable one is used ('map').  For EACH of the two pairs the
% level ell and house-face difference d are then chosen that minimise
%
%   balanceWeight * (P(house | answered) - 0.5)^2  +  mixedWeight * P(mixed)
%
% evaluated with that parameter set, with both textures of the pair kept
% within cMin..cMax.  The level costs no balance, so it is used to lower the
% mixed rate of each pair separately; d is where the pair is balanced, moved
% slightly in the direction that lowers the mixed rate if the mixed model says
% so.  cfg.levelMode changes what decides the level (see defaultSettings).  The two pairs are then combined into x = [g s e i]:
%   g = (ellA + ellB)/2   i = ellA - ellB   s = (dA + dB)/2   e = (dA - dB)/2

if strcmpi(mode, 'sample')
    thB = drawBalance(model.bal, cfg);
    % mixed model: draw shrunk towards the most probable values by cfg.mixSampleScale
    % (1 = full Thompson sample, 0 = most probable values) -> less random level exploration
    thM = model.mix.theta(:) + cfg.mixSampleScale * ...
        (drawGaussian(model.mix.theta, model.mix.Sigma) - model.mix.theta(:));
else
    thB = clampSlopes(model.bal.theta(:), cfg.minSlope);
    thM = model.mix.theta(:);
end
[lA, dA] = bestPair(thB, thM, true,  cfg);
[lB, dB] = bestPair(thB, thM, false, cfg);
x = [(lA + lB) / 2, (dA + dB) / 2, (dA - dB) / 2, lA - lB];
end


%% ------------------------------------------------------------------------
function [ell, d] = bestPair(thB, thM, isA, cfg)
% grid search over level and difference of one pair (level rule: cfg.levelMode)
persistent L0 D0 key
gridKey = [cfg.cMin cfg.cMax];
if isempty(key) || any(key ~= gridKey)
    lg = linspace(log(cfg.cMin), log(cfg.cMax), 37);
    dMax = log(cfg.cMax / cfg.cMin);
    dg = linspace(-dMax, dMax, 121);
    [Lg, Dg] = meshgrid(lg, dg);
    Lg = Lg(:);  Dg = Dg(:);
    % both textures ell +- d/2 inside the allowed range
    ok = abs(Dg) / 2 <= min(Lg - log(cfg.cMin), log(cfg.cMax) - Lg) + 1e-9;
    L0 = Lg(ok);  D0 = Dg(ok);  key = gridKey;
end
L = L0;  D = D0;
mw = cfg.mixedWeight;
extra = 0;
switch cfg.levelMode
    case 'fixed'
        % level pinned at its start value: only the difference is searched
        ellFix = min(max(cfg.ell0(2 - double(isA)), log(cfg.cMin)), log(cfg.cMax));
        dLim = 2 * min(ellFix - log(cfg.cMin), log(cfg.cMax) - ellFix);
        D = linspace(-dLim, dLim, 121)';
        L = repmat(ellFix, size(D));
    case 'balance'
        % mixed percepts do not count; among balanced options prefer the level
        % that needs the smallest difference
        mw = 0;
        extra = cfg.diffWeight * (D / log(cfg.cMax / cfg.cMin)).^2;
end
[PhiB, PhiM] = contrastBO.cfgDesign(L, D, isA, cfg);
p  = 1 ./ (1 + exp(-(PhiB * thB)));
pm = 1 ./ (1 + exp(-(PhiM * thM)));
loss = cfg.balanceWeight * (p - 0.5).^2 + mw * pm + extra;
[~, k] = min(loss);
ell = L(k);  d = D(k);
end

function th = drawBalance(post, cfg)
% posterior draw, re-drawn while a slope is implausibly small
for attempt = 1:100
    th = drawGaussian(post.theta, post.Sigma);
    if th(3) + th(4) >= cfg.minSlope && th(3) - th(4) >= cfg.minSlope, return; end
end
th = clampSlopes(th, cfg.minSlope);
end

function th = clampSlopes(th, minSlope)
% slopes of the two pairs are k + dk and k - dk
kA = max(th(3) + th(4), minSlope);
kB = max(th(3) - th(4), minSlope);
th(3) = (kA + kB) / 2;
th(4) = (kA - kB) / 2;
end

function th = drawGaussian(mu, Sigma)
mu = mu(:);
[R, p] = chol(Sigma + 1e-9 * eye(numel(mu)), 'lower');
if p > 0
    R = diag(sqrt(max(diag(Sigma), 1e-9)));
end
th = mu + R * randn(numel(mu), 1);
end
