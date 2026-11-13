function fig = plotRun(qp, trials, est, titleStr)
% questplus.plotRun  Overview figure of a QUEST+ calibration run.
%
%   fig = questplus.plotRun(qp, trials, est, titleStr)
%
% qp      final QUEST+ state, est = questplus.estimates(qp, qpSet)
% trials  struct array / table with fields houseEye, x, response
%
% Panels: (1) contrast ratio per trial and response, (2) psychometric
% functions of both eye configurations with the binned data, (3) marginal
% posterior of the stimulus and eye balance points with the admissible
% region and the recommended solution.

if nargin < 4; titleStr = 'QUEST+ calibration'; end
if isa(trials, 'table'); trials = table2struct(trials); end
if isfield(trials, 'isWarmup'); trials = trials(~[trials.isWarmup]); end   % runs saved with warm-up trials
he = [trials.houseEye]; x = [trials.x]; resp = {trials.response};
isH = strcmp(resp, 'house'); isF = strcmp(resp, 'face'); isM = strcmp(resp, 'mixed');
colA = [0.85 0.33 0.10]; colB = [0.00 0.45 0.74];
cols = {colA, colB};
labels = {'HouseL + FaceR', 'FaceL + HouseR'};
u = [est.final.uA, est.final.uB];

fig = figure('Name', titleStr, 'Color', 'w', 'Position', [100 100 1400 420]);

%% 1. Trial sequence
subplot(1, 3, 1); hold on;
n = 1:numel(trials);
for c = 1:2
    sel = he == qp.houseEyeValues(c);
    plot(n(sel & isH), x(sel & isH), 'o', 'MarkerFaceColor', cols{c}, 'MarkerEdgeColor', cols{c});
    plot(n(sel & isF), x(sel & isF), 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', cols{c});
    yline(u(c), '--', 'Color', cols{c});
end
plot(n(isM), x(isM), 'x', 'Color', [0.5 0.5 0.5]);
xlabel('trial'); ylabel('log_2(c_{house} / c_{face}) on screen');
title('filled = house, open = face, x = mixed');
ylim([-qp.xMax qp.xMax] * 1.05); box on;

%% 2. Psychometric functions
subplot(1, 3, 2); hold on;
xx = linspace(-qp.xMax, qp.xMax, 200);
hLines = gobjects(1, 2);
for c = 1:2
    p = zeros(size(xx));
    for k = 1:numel(xx)   % loop keeps memory small (nParam is ~1e5)
        p(k) = questplus.model(xx(k), qp.houseEyeValues(c), qp.P(1,:), qp.P(2,:), qp.P(3,:), qp.P(4,:)) * qp.posterior';
    end
    hLines(c) = plot(xx, p, '-', 'Color', cols{c}, 'LineWidth', 1.5);
    sel = he == qp.houseEyeValues(c) & ~isM;
    ux = unique(x(sel));
    for k = 1:numel(ux)
        s = sel & x == ux(k);
        plot(ux(k), mean(isH(s)), 'o', 'Color', cols{c}, 'MarkerFaceColor', cols{c}, ...
            'MarkerSize', 3 + 2 * sqrt(sum(s)));
    end
    xline(u(c), '--', 'Color', cols{c});
end
yline(0.5, ':k');
xlabel('log_2(c_{house} / c_{face}) on screen'); ylabel('P(first percept = house)');
legend(hLines, labels, 'Location', 'northwest'); ylim([0 1]); box on;
title('posterior-mean psychometric functions (marker size ~ n)');

%% 3. Posterior over the balance parameters
subplot(1, 3, 3); hold on;
M = reshape(sum(reshape(qp.posterior, qp.nInterest, []), 2), qp.dims(1), qp.dims(2));   % thetaS x thetaE
imagesc(qp.thetaS, qp.thetaE, M');            % x: thetaS, y: thetaE
set(gca, 'YDir', 'normal'); colormap(gca, flipud(gray));
% admissible region: |thetaS + thetaE| <= xMax and |thetaS - thetaE| <= xMax
xm = qp.xMax;
plot([xm 0 -xm 0 xm], [0 xm 0 -xm 0], '-', 'Color', [0.2 0.6 0.2]);
plot(est.thetaS.mean, est.thetaE.mean, '+r', 'MarkerSize', 10, 'LineWidth', 1.5);
plot(est.final.thetaS, est.final.thetaE, 'or', 'MarkerSize', 8, 'LineWidth', 1.5);
xlabel('\theta_S = log_2(house/face)  (>0: face dominant)');
ylabel('\theta_E = log_2(left/right)  (>0: right eye dominant)');
title('posterior (+ mean, o recommended, green: allowed)');
axis equal tight; box on;

if exist('sgtitle', 'file'); sgtitle(titleStr, 'Interpreter', 'none'); end
end
