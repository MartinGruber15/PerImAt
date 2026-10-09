function fig = plotSteps(trialLog, report, houseLeft, cfg, finalLog, visible)
% plotSteps  Contrast steps of the adaptive run, trial by trial.
%
%   fig = contrastBO.plotSteps(trialLog, report, houseLeft, cfg, finalLog)
%
% Code of the responses (all panels): colour = reported stimulus (green = house,
% purple = face), shape = perceived eye (circle = left eye, diamond = right eye),
% red x = mixed ("none").  In the texture panel the responses are shown as a
% strip at the bottom.
%
% Panels (x axis = trial):
%   1  logLevel      overall contrast level (log scale)
%   2  logHouseFace  ln(house contrast / face contrast): 0 = equal, > 0 house higher
%   3  logLeftRight  ln(left-eye contrast / right-eye contrast): 0 = equal, > 0 left higher
%   4     resulting contrast of the four textures that were shown (dashed = final estimate)
% In panels 1-3 the dots/thin line are the values TESTED in each trial
% (exploration), the thick line is the best estimate after that trial
% (what the optimiser would have returned had the run stopped there), and
% the dashed line the final estimate.
%
% The inputs are the fields trialParams (= trialLog: [logLevel logHouseFace
% logLeftRight] of each trial), respCode (= report), houseLeft, cfg and
% finalParams (= finalLog) of the optimisation record (<sub>_onsetBO_<time>.mat), so a
% saved run can be plotted again:
%   r = load(file);  b = r.boResult;
%   contrastBO.plotSteps(b.trialParams, b.respCode, b.houseLeft, b.cfg, b.finalParams);

if nargin < 6, visible = 'on'; end
n = size(trialLog, 1);
trials = (1:n)';

% best estimate after every trial
best = zeros(n, 3);
for k = 1:n
    m = contrastBO.fitModels(trialLog(1:k, :), houseLeft(1:k), report(1:k), cfg);
    best(k, :) = contrastBO.chooseParams(m, cfg, 'map');
end

% contrasts of the four textures in every trial
cT = zeros(n, 4);   % [FaceLeft FaceRight HouseLeft HouseRight]
for k = 1:n
    c = contrastBO.paramsToContrasts(trialLog(k, :));
    cT(k, :) = [c.faceLeft, c.faceRight, c.houseLeft, c.houseRight];
end

blue  = [0.00 0.45 0.70];
dark  = [0.85 0.33 0.10];
grey  = [0.55 0.55 0.55];
red   = [0.80 0.10 0.10];
colHouse = [0.00 0.62 0.45];   colFace = [0.60 0.25 0.70];   % response colours

fig = figure('Name', 'Adaptive contrast run', 'Color', 'w', ...
    'Visible', visible, 'Position', [100 60 900 900]);

names  = {'logLevel (overall, ln)', 'logHouseFace = ln(house / face)', 'logLeftRight = ln(left / right eye)'};
limits = [cfg.logMin; cfg.logMax];

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
    h1 = plot(trials, trialLog(:, p), '-', 'Color', [0.70 0.78 0.88], 'LineWidth', 0.5);
    plotResp(trials, trialLog(:, p), report(:), houseLeft(:), colHouse, colFace, red, 4);
    h2 = plot(trials, best(:, p), '-', 'Color', dark, 'LineWidth', 2);
    h3 = plot([0 n+1], [finalLog(p) finalLog(p)], '--', 'Color', dark, 'LineWidth', 1);
    if p == 1
        [hl, ll] = respLegend(colHouse, colFace, red);
        placeLegend(hl, ll, legPos(1));
    elseif p == 2
        placeLegend([h1 h2 h3], {'tested in trial', 'best estimate so far', 'final estimate'}, legPos(2));
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
cF = contrastBO.paramsToContrasts(finalLog);          % final estimate (dashed)
finals = [cF.faceLeft, cF.faceRight, cF.houseLeft, cF.houseRight];
for j = 1:4
    plot([0 n+1], [finals(j) finals(j)], '--', 'Color', cols(j, :), 'LineWidth', 1.2);
end
plot([0 n+1], [cfg.cMin cfg.cMin], ':', 'Color', grey);
plot([0 n+1], [cfg.cMax cfg.cMax], ':', 'Color', grey);
plotResp(trials, 0.07 * cfg.cMax * ones(n, 1), report(:), houseLeft(:), colHouse, colFace, red, 4);   % response strip
placeLegend(hh, labs, legPos(4));
xlim([0 n+1]);
ylim([0, cfg.cMax * 1.05]);
xlabel('trial');
ylabel('texture contrast');
grid on; box on;
drawnow;
end


function plotResp(t, y, report, houseLeft, cHouse, cFace, cMix, ms)
% Responses as markers.  colour = reported stimulus (house / face), shape = perceived
% eye (circle = left eye, diamond = right eye), x = mixed.
t = t(:);  y = y(:);  report = report(:);  houseLeft = logical(houseLeft(:));
% perceived eye: house in the left eye + house reported -> left eye, etc.
leftEye = (report == 1 & houseLeft) | (report == 0 & ~houseLeft);
rightEye = (report == 1 & ~houseLeft) | (report == 0 & houseLeft);
cols = {cHouse, cFace};  stim = {report == 1, report == 0};
for q = 1:2
    ring = cols{q};  lw = 0.5;
    k = stim{q} & leftEye;
    if any(k), plot(t(k), y(k), 'o', 'MarkerSize', ms, 'MarkerFaceColor', cols{q}, 'MarkerEdgeColor', ring, 'LineWidth', lw); end
    k = stim{q} & rightEye;
    if any(k), plot(t(k), y(k), 'd', 'MarkerSize', ms + 1, 'MarkerFaceColor', cols{q}, 'MarkerEdgeColor', ring, 'LineWidth', lw); end
end
k = report < 0;
if any(k), plot(t(k), y(k), 'x', 'Color', cMix, 'MarkerSize', 8, 'LineWidth', 1.5); end
end


function [hl, ll] = respLegend(cHouse, cFace, cMix)
% legend of the response code (dummy handles, drawn outside the data)
g = [0.45 0.45 0.45];
hl(1) = plot(NaN, NaN, 'o', 'MarkerSize', 6, 'MarkerFaceColor', cHouse, 'MarkerEdgeColor', cHouse);
hl(2) = plot(NaN, NaN, 'o', 'MarkerSize', 6, 'MarkerFaceColor', cFace,  'MarkerEdgeColor', cFace);
hl(3) = plot(NaN, NaN, 'o', 'MarkerSize', 6, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', g);
hl(4) = plot(NaN, NaN, 'd', 'MarkerSize', 7, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', g);
hl(5) = plot(NaN, NaN, 'x', 'MarkerSize', 8, 'LineWidth', 1.5, 'Color', cMix);
ll = {'house reported', 'face reported', 'left eye seen', 'right eye seen', 'mixed (none)'};
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
