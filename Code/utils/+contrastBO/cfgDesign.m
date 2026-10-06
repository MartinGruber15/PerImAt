function [PhiB, PhiM] = cfgDesign(ell, d, isA, cfg)
% cfgDesign  Design matrices of the 'perConfig' balance and mixed models.
%
%   ell  level of the pair that is shown   ( = ln of the geometric mean of its two contrasts)
%   d    ln(house contrast / face contrast) of that pair
%   isA  true: pair A (house left, face right); false: pair B (house right, face left)
%
% Column order matches cfg.cfgBalPriorMean / cfg.cfgMixPriorMean, see defaultSettings.

n = numel(ell);
ell = ell(:);  d = d(:);
isA = logical(isA(:));
if isscalar(isA), isA = repmat(isA, n, 1); end
sg  = 2 * double(isA) - 1;                 % +1 pair A, -1 pair B
idx = 2 - double(isA);                     % 1 for A, 2 for B
ell0 = cfg.ell0(:);  d0 = cfg.d0(:);
ll = ell - ell0(idx);                      % level relative to the start value of this pair
dd = d   - d0(idx);                        % difference relative to the start value
z  = (ell - cfg.gMid) / cfg.gHalf;

a = double(isA);  b = 1 - a;
PhiB = [a, b, dd, sg .* dd, ll, sg .* ll];
PhiM = [a, b, z, z.^2, dd, sg .* dd, dd.^2];
end
