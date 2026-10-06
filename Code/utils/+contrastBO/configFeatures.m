function [ell, d] = configFeatures(X, houseLeft)
% configFeatures  Level and house-face difference of the pair shown in each trial.
%
%   X          n x 4   [g s e i] of each trial
%   houseLeft  n x 1   true: pair A (house left + face right), false: pair B
%
%   pair A: ell = g + i/2,  d = s + e        pair B: ell = g - i/2,  d = s - e
% (ell = ln of the geometric mean of the two shown contrasts, d = ln(house / face))

sg = 2 * double(logical(houseLeft(:))) - 1;
ell = X(:, 1) + sg .* X(:, 4) / 2;
d   = X(:, 2) + sg .* X(:, 3);
end
