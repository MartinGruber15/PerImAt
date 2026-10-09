function [stop, info, hist] = stopCheck(model, cfg, rule, hist, nDone)
% stopCheck  Stopping rule of the adaptive run (sliding window).
%
%   [stop, info, hist] = contrastBO.stopCheck(model, cfg, rule, hist, nDone)
%
% Called after every trial with the model fitted to the first nDone trials.
% hist starts as [] and is returned updated, one row per call:
%   [nDone, balanceHouseFace, balanceLeftRight, houseFaceHalf, leftRightHalf]
%
% rule.minTrials   never stop before this many trials
% rule.window      number of trials (= calls) the criteria must hold for
% rule.ci95        largest allowed half-width of the 95% interval of the two
%                  balance points (ln units; about 1.96 x SD)
% rule.drift       largest allowed change of the best estimate (max - min of
%                  each balance point) inside the window (ln units)
% rule.groupSize   stop only after complete groups of this many trials, so the
%                  house-left / house-right assignment stays balanced (4)
%
% The run stops when, over the last `window` trials, the interval half-widths
% were all <= ci95 AND the best estimate moved by no more than `drift`.
% The interval is the model's own (it assumes independent trials), so it is
% optimistic when the dominance drifts slowly; the drift criterion guards
% against that.

best = contrastBO.chooseParams(model, cfg, 'map');
pred = contrastBO.predictAt(model, best, cfg, 1500, 0.95);
row = [nDone, best(2), best(3), pred.houseFaceHalf, pred.leftRightHalf];
if isempty(hist), hist = row; else, hist = [hist; row]; end

info.nDone = nDone;
info.balanceHouseFace = best(2);  info.balanceLeftRight = best(3);
info.houseFaceHalf = pred.houseFaceHalf;  info.leftRightHalf = pred.leftRightHalf;
info.houseFaceSD = pred.houseFaceHalf / 1.96;  info.leftRightSD = pred.leftRightHalf / 1.96;
info.driftHouseFace = NaN;  info.driftLeftRight = NaN;
info.widthOK = false;  info.driftOK = false;  info.met = false;

stop = false;
if size(hist, 1) < rule.window, return; end
window = hist(end - rule.window + 1:end, :);
info.driftHouseFace = max(window(:, 2)) - min(window(:, 2));
info.driftLeftRight = max(window(:, 3)) - min(window(:, 3));
info.widthOK = all(window(:, 4) <= rule.ci95) && all(window(:, 5) <= rule.ci95);
info.driftOK = info.driftHouseFace <= rule.drift && info.driftLeftRight <= rule.drift;
info.met = info.widthOK && info.driftOK && nDone >= rule.minTrials;
stop = info.met && mod(nDone, rule.groupSize) == 0;
end
