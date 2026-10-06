function Phi = stimFeatures(X, houseLeft, cfg)
% stimFeatures  Design matrix of the house-vs-face model, one row per trial.
%   X          n x 3   [g s e] of each trial
%   houseLeft  n x 1   true if the house was shown to the left eye
% Columns match cfg.stimPriorMean = [a0 a1 a3 b0 b1 b3].

n  = size(X, 1);
t  = 2 * double(houseLeft(:)) - 1;          % +1 house left, -1 house right
dg = X(:, 1) - cfg.center(1);
ds = X(:, 2) - cfg.center(2);
de = X(:, 3) - cfg.center(3);
Phi = [ones(n, 1), ds, dg, t, t .* de, t .* dg];
end
