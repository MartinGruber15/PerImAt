function pred = predictAt(model, x, cfg, nDraw)
% predictAt  What the current model expects at contrasts x = [g s e].
%
%   pred.pHouse  expected share of "house" among answered trials
%   pred.pLeft   expected share of "left eye" among answered trials
%   pred.pMixed  expected share of mixed ("none") responses
%   pred.sCI     90% interval of the house/face balance point s* (ln units)
%   pred.eCI     90% interval of the left/right balance point e* (ln units)
%
% pHouse / pLeft are averaged over both trial types (house left / house right).

if nargin < 4, nDraw = 500; end
if isfield(cfg, 'mode') && strcmpi(cfg.mode, 'perConfig')
    pred = contrastBO.predictAtCfg(model, x, cfg, nDraw);      % per-pair model
    return
end
sig = @(a) 1 ./ (1 + exp(-a));
thS = model.stim.theta(:);
etaL = contrastBO.stimFeatures(x, true,  cfg) * thS;    % house at left eye
etaR = contrastBO.stimFeatures(x, false, cfg) * thS;    % house at right eye
pHL = sig(etaL);  pHR = sig(etaR);
pred.pHouse = 0.5 * (pHL + pHR);
pred.pLeft  = 0.5 * (pHL + (1 - pHR));
pred.pMixed = sig(contrastBO.mixFeatures(x(1), cfg) * model.mix.theta(:));

% uncertainty of the balance point at this overall level
[R, p] = chol(model.stim.Sigma + 1e-9 * eye(6), 'lower');
if p > 0, R = diag(sqrt(max(diag(model.stim.Sigma), 1e-9))); end
sv = zeros(nDraw, 1);  ev = zeros(nDraw, 1);
dg = x(1) - cfg.center(1);
for k = 1:nDraw
    th = thS + R * randn(6, 1);
    th([2 5]) = max(th([2 5]), cfg.minSlope);
    sv(k) = cfg.center(2) - (th(1) + th(3) * dg) / th(2);
    ev(k) = cfg.center(3) - (th(4) + th(6) * dg) / th(5);
end
sv = sort(sv);  ev = sort(ev);
lo = max(round(0.05 * nDraw), 1);  hi = min(round(0.95 * nDraw), nDraw);
pred.sCI = [sv(lo) sv(hi)];
pred.eCI = [ev(lo) ev(hi)];
end
