function x = chooseParams(model, cfg, mode)
% chooseParams  Contrasts [g s e] to use next, or the current best estimate.
%
%   x = contrastBO.chooseParams(model, cfg, 'sample')   next trial (Thompson sampling)
%   x = contrastBO.chooseParams(model, cfg, 'map')      current best estimate
%
% 'sample': draw ONE plausible parameter set from each model's posterior and
%   return the optimum of that draw.  While the posterior is wide, draws
%   differ a lot, so many different contrasts get tested (exploration); as
%   data accumulate, draws agree and the trials concentrate around the
%   optimum (exploitation).
% 'map': use the most probable parameters instead of a random draw.
%
% The optimum of a parameter set is
%   - s, e : the values at which house/face and left/right are equally
%            likely to be reported (logit = 0)
%   - g    : depends on cfg.levelMode: 'mixed' = level with the lowest mixed-
%            percept probability among those that keep all four contrasts within
%            cMin..cMax; 'balance' = level needing the smallest differences
%            (mixed percepts ignored); 'fixed' = start level.

if isfield(cfg, 'mode') && strcmpi(cfg.mode, 'perConfig')
    x = contrastBO.chooseParamsCfg(model, cfg, mode);          % per-pair model
    return
end

if strcmpi(mode, 'sample')
    thS = drawStim(model.stim, cfg);
    thM = drawGaussian(model.mix.theta, model.mix.Sigma);
else
    thS = model.stim.theta(:);
    thS([2 5]) = max(thS([2 5]), cfg.minSlope);
    thM = model.mix.theta(:);
end
x = optimumFor(thS, thM, cfg);
end


%% ------------------------------------------------------------------------
function th = drawStim(post, cfg)
% posterior draw, re-drawn while a contrast slope is implausibly small
for attempt = 1:100
    th = drawGaussian(post.theta, post.Sigma);
    if th(2) >= cfg.minSlope && th(5) >= cfg.minSlope, return; end
end
th([2 5]) = max(th([2 5]), cfg.minSlope);
end

function th = drawGaussian(mu, Sigma)
mu = mu(:);
[R, p] = chol(Sigma + 1e-9 * eye(numel(mu)), 'lower');
if p > 0
    R = diag(sqrt(max(diag(Sigma), 1e-9)));
end
th = mu + R * randn(numel(mu), 1);
end

function x = optimumFor(thS, thM, cfg)
gGrid = linspace(cfg.lo(1), cfg.hi(1), 61)';
mixLogit = contrastBO.mixFeatures(gGrid, cfg) * thM(:);
lvl = 'mixed';
if isfield(cfg, 'levelMode'), lvl = cfg.levelMode; end

switch lvl
    case 'fixed'
        g = cfg.center(1);
        [s, e] = balancePoint(thS, g, cfg);
        % keep all four textures inside cMin..cMax at this level
        room = min(g - log(cfg.cMin), log(cfg.cMax) - g);
        need = (abs(s) + abs(e)) / 2;
        if need > room
            f = max(room, 0) / need;  s = s * f;  e = e * f;
        end
        x = [g s e];
        return
    case 'balance'
        % level where the differences needed for balance are smallest (mixed ignored)
        cost = zeros(size(gGrid));
        for k = 1:numel(gGrid)
            [sk, ek] = balancePoint(thS, gGrid(k), cfg);
            half = (abs(sk) + abs(ek)) / 2;
            cost(k) = abs(sk) + abs(ek) + 1e3 * (gGrid(k) + half > log(cfg.cMax) + 1e-9 ...
                | gGrid(k) - half < log(cfg.cMin) - 1e-9) + 1e-3 * abs(gGrid(k) - cfg.center(1));
        end
        [~, i] = min(cost);
        g = gGrid(i);
    otherwise
        % overall level: lowest mixed probability that keeps all contrasts in range
        [~, i] = min(mixLogit);
        g = gGrid(i);
        for it = 1:4
            [s, e] = balancePoint(thS, g, cfg);
            half = (abs(s) + abs(e)) / 2;
            ok = (gGrid + half <= log(cfg.cMax) + 1e-9) & (gGrid - half >= log(cfg.cMin) - 1e-9);
            if any(ok)
                idx = find(ok);
                [~, j] = min(mixLogit(idx));
                g = gGrid(idx(j));
            else
                % ratios too large for the allowed range: shrink them, centre g
                g = cfg.gMid;
                f = cfg.gHalf / half;
                s = s * f;  e = e * f;
                x = [g s e];
                return
            end
        end
end
[s, e] = balancePoint(thS, g, cfg);
% keep all four textures inside cMin..cMax (g is shifted if the final s, e need more room)
half = (abs(s) + abs(e)) / 2;
gLo = log(cfg.cMin) + half;  gHi = log(cfg.cMax) - half;
if gLo > gHi
    f = cfg.gHalf / half;
    s = s * f;  e = e * f;
    g = cfg.gMid;
else
    g = min(max(g, gLo), gHi);
end
x = [g s e];
end

function [s, e] = balancePoint(th, g, cfg)
% where the house/face and left/right logits are zero, at overall level g
dg = g - cfg.center(1);
s = cfg.center(2) - (th(1) + th(3) * dg) / th(2);
e = cfg.center(3) - (th(4) + th(6) * dg) / th(5);
s = min(max(s, cfg.lo(2)), cfg.hi(2));
e = min(max(e, cfg.lo(3)), cfg.hi(3));
end
