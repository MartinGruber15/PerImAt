function pred = predictAtCfg(model, x, cfg, nDraw)
% predictAtCfg  'perConfig' model: what is expected at contrasts x = [g s e i].
%
%   pred.pHouse  expected share of "house" among answered trials (both pairs pooled)
%   pred.pLeft   expected share of "left eye" among answered trials
%   pred.pMixed  expected share of mixed ("none") responses
%   pred.pA, pred.pB       P(house | answered) in pair A / pair B
%   pred.mixA, pred.mixB   P(mixed) in pair A / pair B
%   pred.dACI, pred.dBCI   90% interval of the balance point d* (ln house/face) of each pair
%                          at the chosen level of that pair
%
% Pairs: A = house left + face right, B = house right + face left.

if nargin < 4, nDraw = 500; end
sig = @(a) 1 ./ (1 + exp(-a));
thB = model.bal.theta(:);
thM = model.mix.theta(:);

[ellA, dA] = contrastBO.configFeatures(x, true);
[ellB, dB] = contrastBO.configFeatures(x, false);
[PhiBA, PhiMA] = contrastBO.cfgDesign(ellA, dA, true,  cfg);
[PhiBB, PhiMB] = contrastBO.cfgDesign(ellB, dB, false, cfg);
pred.pA = sig(PhiBA * thB);   pred.pB = sig(PhiBB * thB);
pred.mixA = sig(PhiMA * thM); pred.mixB = sig(PhiMB * thM);

wA = 1 - pred.mixA;  wB = 1 - pred.mixB;          % shares of answered trials
pred.pHouse = (wA * pred.pA + wB * pred.pB) / (wA + wB);
pred.pLeft  = (wA * pred.pA + wB * (1 - pred.pB)) / (wA + wB);   % A: left = house; B: left = face
pred.pMixed = (pred.mixA + pred.mixB) / 2;

% uncertainty of the balance points
[R, p] = chol(model.bal.Sigma + 1e-9 * eye(6), 'lower');
if p > 0, R = diag(sqrt(max(diag(model.bal.Sigma), 1e-9))); end
dsA = zeros(nDraw, 1);  dsB = zeros(nDraw, 1);
for k = 1:nDraw
    th = thB + R * randn(6, 1);
    kA = max(th(3) + th(4), cfg.minSlope);  kB = max(th(3) - th(4), cfg.minSlope);
    lA = th(5) + th(6);                     lB = th(5) - th(6);
    dsA(k) = cfg.d0(1) - (th(1) + lA * (ellA - cfg.ell0(1))) / kA;
    dsB(k) = cfg.d0(2) - (th(2) + lB * (ellB - cfg.ell0(2))) / kB;
end
dsA = sort(dsA);  dsB = sort(dsB);
lo = max(round(0.05 * nDraw), 1);  hi = min(round(0.95 * nDraw), nDraw);
pred.dACI = [dsA(lo) dsA(hi)];
pred.dBCI = [dsB(lo) dsB(hi)];
end
