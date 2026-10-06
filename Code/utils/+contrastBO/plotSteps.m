function fig = plotSteps(trialParams, respCode, houseLeft, cfg, xFinal, visible)
% plotSteps  Contrast steps of the adaptive run, trial by trial.
%
%   fig = contrastBO.plotSteps(trialParams, respCode, houseLeft, cfg, xFinal)
%
% Colour code of the responses (all panels): green dot = house reported,
% purple dot = face reported, red x = mixed ("none"); in the texture panel the
% responses are shown as a strip at the bottom.
%
% Panels (x axis = trial):
%   1  g  overall contrast level (log scale)
%   2  s  ln(house contrast / face contrast): 0 = equal, > 0 house higher
%   3  e  ln(left-eye contrast / right-eye contrast): 0 = equal, > 0 left higher
%   4     resulting contrast of the four textures that were shown (dashed = final estimate)
% In panels 1-3 the dots/thin line are the values TESTED in each trial
% (exploration), the thick line is the best estimate after that trial
% (what the optimiser would have returned had the run stopped there), and
% the dashed line the final estimate.
%
% The inputs are the fields trialParams, respCode, houseLeft, cfg and
% finalParams of the optimisation record (<sub>_onsetBO_<time>.mat), so a
% saved run can be plotted again:
%   r = load(file);  b = r.boResult;
%   contrastBO.plotSteps(b.trialParams, b.respCode, b.houseLeft, b.cfg, b.finalParams);

if nargin < 6, visible = 'on'; end
if isfield(cfg, 'mode') && strcmpi(cfg.mode, 'perConfig')
    fig = plotStepsCfg(trialParams, respCode, houseLeft, cfg, xFinal, visible);
    return
end
n = size(trialParams, 1);
trials = (1:n)';

% best estimate after every trial
best = zeros(n, 3);
for k = 1:n
    m = contrastBO.fitModels(trialParams(1:k, :), houseLeft(1:k), respCode(1:k), cfg);
    best(k, :) = contrastBO.chooseParams(m, cfg, 'map');
end

% contrasts of the four textures in every trial
cT = zeros(n, 4);   % [FaceLeft FaceRight HouseLeft HouseRight]
for k = 1:n
    c = contrastBO.paramsToContrasts(trialParams(k, :));
    cT(k, :) = [c.faceLeft, c.faceRight, c.houseLeft, c.houseRight];
end

blue  = [0.00 0.45 0.70];
dark  = [0.85 0.33 0.10];
grey  = [0.55 0.55 0.55];
red   = [0.80 0.10 0.10];
colHouse = [0.00 0.62 0.45];   colFace = [0.60 0.25 0.70];   % response colours

fig = figure('Name', 'Adaptive contrast run', 'Color', 'w', ...
    'Visible', visible, 'Position', [100 60 900 900]);

names  = {'g  (overall level, ln)', 's = ln(house / face)', 'e = ln(left eye / right eye)'};
limits = [cfg.lo; cfg.hi];

% fixed layout: four axes of equal width, legends in the right margin
axH = 0.19;  axGap = 0.035;  axLeft = 0.10;  axW = 0.66;
axBottom = [0.745, 0.52, 0.295, 0.07];          % panels 1..4, top to bottom
legPos = @(p) [0.78, axBottom(p) + 0.03, 0.21, axH - 0.04];

for p = 1:3
    ax = axes('Position', [axLeft, axBottom(p), axW, axH]);  hold on;
    if p == 1, ax1 = ax; end
    % allowed range and reference line
    plot([0 n+1], [limits(1,p) limits(1,p)], ':', 'Color', grey);
    plot([0 n+1], [limits(2,p) limits(2,p)], ':', 'Color', grey);
    if p > 1, plot([0 n+1], [0 0], '-', 'Color', [0.85 0.85 0.85]); end
    h1 = plot(trials, trialParams(:, p), '-', 'Color', [0.70 0.78 0.88], 'LineWidth', 0.5);
    hr = plotResp(trials, trialParams(:, p), respCode(:), colHouse, colFace, red, 'o', 4);
    h2 = plot(trials, best(:, p), '-', 'Color', dark, 'LineWidth', 2);
    h3 = plot([0 n+1], [xFinal(p) xFinal(p)], '--', 'Color', dark, 'LineWidth', 1);
    if p == 1
        [hl, ll] = respLegend(hr, {'house reported', 'face reported', 'mixed (none)'});
        hl = [h1 hl h2 h3];
        ll = [{'tested in trial'} ll {'best estimate so far', 'final estimate'}];
        placeLegend(hl, ll, legPos(1));
    end
    xlim([0 n+1]);
    pad = 0.05 * (limits(2,p) - limits(1,p));
    ylim([limits(1,p) - pad, limits(2,p) + pad]);
    ylabel(names{p});
    grid on; box on;
    set(ax, 'XTickLabel', []);
end
title(ax1, sprintf('Contrast steps during the adaptive run (%d trials)', n));

% panel 4: the four textures
ax = axes('Position', [axLeft, axBottom(4), axW, axH]);  hold on;
cols = [0.85 0.33 0.10; 0.93 0.69 0.13; 0.00 0.45 0.70; 0.30 0.75 0.93];
mark = {'o', 's', 'o', 's'};
labs = {'FaceLeft', 'FaceRight', 'HouseLeft', 'HouseRight'};
hh = zeros(1, 4);
for j = 1:4
    hh(j) = plot(trials, cT(:, j), mark{j}, 'Color', cols(j, :), ...
        'MarkerSize', 3, 'MarkerFaceColor', cols(j, :));
end
cF = contrastBO.paramsToContrasts(xFinal);          % final estimate (dashed)
finals = [cF.faceLeft, cF.faceRight, cF.houseLeft, cF.houseRight];
for j = 1:4
    plot([0 n+1], [finals(j) finals(j)], '--', 'Color', cols(j, :), 'LineWidth', 1.2);
end
plot([0 n+1], [cfg.cMin cfg.cMin], ':', 'Color', grey);
plot([0 n+1], [cfg.cMax cfg.cMax], ':', 'Color', grey);
plotResp(trials, 0.07 * cfg.cMax * ones(n, 1), respCode(:), colHouse, colFace, red, 'o', 4);   % response strip
placeLegend(hh, labs, legPos(4));
xlim([0 n+1]);
ylim([0, cfg.cMax * 1.05]);
xlabel('trial');
ylabel('texture contrast');
grid on; box on;
drawnow;
end


function h = plotResp(t, y, resp, cHouse, cFace, cMix, mk, ms)
% responses as markers: house = filled dot, face = filled dot (other colour),
% mixed = x.  Returns a 1x3 cell {house, face, mixed} of handles ([] if none).
h = cell(1, 3);
t = t(:);  y = y(:);  resp = resp(:);
k = resp == 1;
if any(k), h{1} = plot(t(k), y(k), mk, 'Color', cHouse, 'MarkerSize', ms, 'MarkerFaceColor', cHouse); end
k = resp == 0;
if any(k), h{2} = plot(t(k), y(k), mk, 'Color', cFace, 'MarkerSize', ms, 'MarkerFaceColor', cFace); end
k = resp < 0;
if any(k), h{3} = plot(t(k), y(k), 'x', 'Color', cMix, 'MarkerSize', 8, 'LineWidth', 1.5); end
end


function [hl, ll] = respLegend(h, labels)
% legend entries of the response markers that occur
hl = [];  ll = {};
for q = 1:numel(h)
    if ~isempty(h{q}), hl(end+1) = h{q}; ll{end+1} = labels{q}; end %#ok<AGROW>
end
end


function placeLegend(handles, labels, pos)
% legend at a fixed position in the right margin (falls back to 'best')
try
    lg = legend(handles, labels, 'Position', pos);
    try, set(lg, 'FontSize', 8); catch, end
catch
    legend(handles, labels, 'Location', 'best');
end
end


function fig = plotStepsCfg(trialParams, respCode, houseLeft, cfg, xFinal, visible)
% Model 'perConfig': level and house-face difference of the pair that was shown
% in each trial, separately for pair A (house left + face right) and pair B
% (house right + face left), and the contrasts of the four textures.
n = size(trialParams, 1);
trials = (1:n)';
houseLeft = logical(houseLeft(:));
[ell, d] = contrastBO.configFeatures(trialParams, houseLeft);

% best estimate of both pairs after every trial
best = zeros(n, 4);          % [ellA dA ellB dB]
for k = 1:n
    m = contrastBO.fitModels(trialParams(1:k, :), houseLeft(1:k), respCode(1:k), cfg);
    xk = contrastBO.chooseParams(m, cfg, 'map');
    [la, da] = contrastBO.configFeatures(xk, true);
    [lb, db] = contrastBO.configFeatures(xk, false);
    best(k, :) = [la da lb db];
end
[laF, daF] = contrastBO.configFeatures(xFinal, true);
[lbF, dbF] = contrastBO.configFeatures(xFinal, false);

colA = [0.00 0.45 0.70];   colB = [0.85 0.33 0.10];
grey = [0.55 0.55 0.55];   red  = [0.80 0.10 0.10];
colHouse = [0.00 0.62 0.45];   colFace = [0.60 0.25 0.70];   % response colours

fig = figure('Name', 'Adaptive contrast run (per configuration)', 'Color', 'w', ...
    'Visible', visible, 'Position', [100 60 900 900]);
axH = 0.24;  axLeft = 0.10;  axW = 0.66;
axBottom = [0.69, 0.385, 0.08];
legPos = @(p) [0.78, axBottom(p) + 0.03, 0.21, axH - 0.04];

isA = houseLeft;   isB = ~houseLeft;
dMax = log(cfg.cMax / cfg.cMin);
panels = {'level of the shown pair (ln)', 'd = ln(house / face) of the shown pair'};
vals   = {ell, d};
bestA  = {best(:, 1), best(:, 2)};
bestB  = {best(:, 3), best(:, 4)};
finA   = [laF, daF];
finB   = [lbF, dbF];
lims   = {[log(cfg.cMin) log(cfg.cMax)], [-dMax dMax]};

for p = 1:2
    ax = axes('Position', [axLeft, axBottom(p), axW, axH]);  hold on;
    if p == 2, plot([0 n+1], [0 0], '-', 'Color', [0.85 0.85 0.85]); end
    h3 = plot(trials, bestA{p}, '-', 'Color', colA, 'LineWidth', 2);
    h4 = plot(trials, bestB{p}, '-', 'Color', colB, 'LineWidth', 2);
    plot([0 n+1], [finA(p) finA(p)], '--', 'Color', colA);
    plot([0 n+1], [finB(p) finB(p)], '--', 'Color', colB);
    resp = respCode(:);
    hrA = plotResp(trials(isA), vals{p}(isA), resp(isA), colHouse, colFace, red, 'o', 4);
    hrB = plotResp(trials(isB), vals{p}(isB), resp(isB), colHouse, colFace, red, 'd', 4);
    if p == 1
        hr = hrA;
        for q = 1:3, if isempty(hr{q}), hr{q} = hrB{q}; end, end
        [hl, ll] = respLegend(hr, {'house reported', 'face reported', 'mixed (none)'});
        hA = plot(NaN, NaN, 'o', 'Color', grey, 'MarkerSize', 4);
        hB = plot(NaN, NaN, 'd', 'Color', grey, 'MarkerSize', 4);
        hl = [hl hA hB h3 h4];
        ll = [ll {'circle = pair A', 'diamond = pair B', 'best A so far', 'best B so far'}];
        placeLegend(hl, ll, legPos(1));
        title(ax, sprintf('Contrast steps during the adaptive run (%d trials); A = house left + face right, B = house right + face left', n), 'FontSize', 9);
    end
    xlim([0 n+1]);
    pad = 0.05 * (lims{p}(2) - lims{p}(1));
    ylim([lims{p}(1) - pad, lims{p}(2) + pad]);
    ylabel(panels{p});
    grid on; box on;
    set(ax, 'XTickLabel', []);
end

% panel 3: contrasts of the textures that were shown
ax = axes('Position', [axLeft, axBottom(3), axW, axH]);  hold on;
cHouse = exp(ell + d / 2);   cFace = exp(ell - d / 2);
cols = [0.00 0.45 0.70; 0.30 0.75 0.93; 0.85 0.33 0.10; 0.93 0.69 0.13];
labs = {'HouseLeft', 'FaceRight', 'HouseRight', 'FaceLeft'};
sel  = {isA, isA, isB, isB};
dat  = {cHouse, cFace, cHouse, cFace};
mark = {'o', 's', 'o', 's'};
hh = zeros(1, 4);
for j = 1:4
    hh(j) = plot(trials(sel{j}), dat{j}(sel{j}), mark{j}, 'Color', cols(j, :), ...
        'MarkerSize', 3, 'MarkerFaceColor', cols(j, :));
end
cF = contrastBO.paramsToContrasts(xFinal);
finals = [cF.houseLeft, cF.faceRight, cF.houseRight, cF.faceLeft];
for j = 1:4
    plot([0 n+1], [finals(j) finals(j)], '--', 'Color', cols(j, :), 'LineWidth', 1.2);
end
plot([0 n+1], [cfg.cMin cfg.cMin], ':', 'Color', grey);
plot([0 n+1], [cfg.cMax cfg.cMax], ':', 'Color', grey);
plotResp(trials, 0.07 * cfg.cMax * ones(n, 1), respCode(:), colHouse, colFace, red, 'o', 4);   % response strip
placeLegend(hh, labs, legPos(3));
xlim([0 n+1]);  ylim([0, cfg.cMax * 1.05]);
xlabel('trial');  ylabel('texture contrast (shown)');
grid on; box on;
drawnow;
end
