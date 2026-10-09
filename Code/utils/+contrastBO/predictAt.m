function pred = predictAt(model, logContrast, cfg, nDraw, ciLevel)
% predictAt  What the current model expects at logContrast =
%            [logLevel logHouseFace logLeftRight].
%
%   pred = contrastBO.predictAt(model, logContrast, cfg)             90% intervals, 500 draws
%   pred = contrastBO.predictAt(model, logContrast, cfg, nDraw, 0.95) other level / draws
%
%   pred.pHouse         expected share of "house" among answered trials
%   pred.pLeft          expected share of "left eye" among answered trials
%   pred.pMixed         expected share of mixed ("none") responses
%   pred.houseFaceCI    interval of the balance point balanceHouseFace (ln units)
%   pred.leftRightCI    interval of the balance point balanceLeftRight (ln units)
%   pred.houseFaceHalf, pred.leftRightHalf   half-width of those intervals
%
% pHouse / pLeft are averaged over both trial types (house left / house right).

if nargin < 4 || isempty(nDraw), nDraw = 500; end
if nargin < 5 || isempty(ciLevel), ciLevel = 0.90; end
sigmoid = @(z) 1 ./ (1 + exp(-z));
params = model.stim.params(:);
logitHouseLeft  = contrastBO.stimFeatures(logContrast, true,  cfg) * params;    % house at left eye
logitHouseRight = contrastBO.stimFeatures(logContrast, false, cfg) * params;    % house at right eye
pHouseLeft = sigmoid(logitHouseLeft);  pHouseRight = sigmoid(logitHouseRight);
pred.pHouse = 0.5 * (pHouseLeft + pHouseRight);
pred.pLeft  = 0.5 * (pHouseLeft + (1 - pHouseRight));
pred.pMixed = sigmoid(model.mix.mixedLogit(1));

% uncertainty of the balance points
[cholFactor, notPosDef] = chol(model.stim.paramCov + 1e-9 * eye(4), 'lower');
if notPosDef > 0, cholFactor = diag(sqrt(max(diag(model.stim.paramCov), 1e-9))); end
houseFaceDraws = zeros(nDraw, 1);  leftRightDraws = zeros(nDraw, 1);
for k = 1:nDraw
    drawn = params + cholFactor * randn(4, 1);
    drawn([2 4]) = max(drawn([2 4]), cfg.minSlope);
    houseFaceDraws(k) = cfg.startLog(2) - drawn(1) / drawn(2);
    leftRightDraws(k) = cfg.startLog(3) - drawn(3) / drawn(4);
end
houseFaceDraws = sort(houseFaceDraws);  leftRightDraws = sort(leftRightDraws);
lo = max(round((1 - ciLevel) / 2 * nDraw), 1);
hi = min(round((1 + ciLevel) / 2 * nDraw), nDraw);
pred.houseFaceCI = [houseFaceDraws(lo) houseFaceDraws(hi)];
pred.leftRightCI = [leftRightDraws(lo) leftRightDraws(hi)];
pred.houseFaceHalf = (houseFaceDraws(hi) - houseFaceDraws(lo)) / 2;
pred.leftRightHalf = (leftRightDraws(hi) - leftRightDraws(lo)) / 2;
end
