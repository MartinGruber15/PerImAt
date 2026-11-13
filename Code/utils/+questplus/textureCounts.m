function [c, str] = textureCounts(H)
% questplus.textureCounts  How often each of the four textures was seen first.
%
%   [c, str] = questplus.textureCounts(H)
%
% H: rows [houseEye, x, isHouse, ...] of house/face trials (e.g. a part of
% qp.history); mixed trials are not included.
%   HouseL+FaceR shown nA times: HouseL seen c.HouseL, FaceR seen c.FaceR
%   FaceL+HouseR shown nB times: FaceL  seen c.FaceL,  HouseR seen c.HouseR
% Balanced contrasts -> each texture ~50 % of the trials of its pair;
% balanced eyes -> left-eye textures (HouseL, FaceL) ~50 % of all trials.
% str: one-line summary for the terminal.
A = H(:, 1) == 1; B = H(:, 1) == -1; h = H(:, 3) > 0.5;
c.nA = sum(A); c.nB = sum(B);
c.HouseL = sum(A & h); c.FaceR = sum(A & ~h);
c.FaceL = sum(B & ~h); c.HouseR = sum(B & h);
c.left = c.HouseL + c.FaceL; c.n = c.nA + c.nB;
str = sprintf(['HouseL %2d/%-2d (%3.0f%%)  FaceR %2d/%-2d (%3.0f%%) | FaceL %2d/%-2d (%3.0f%%)  HouseR %2d/%-2d (%3.0f%%)' ...
    ' | left eye %2d/%-2d (%3.0f%%)'], c.HouseL, c.nA, pct(c.HouseL, c.nA), c.FaceR, c.nA, pct(c.FaceR, c.nA), ...
    c.FaceL, c.nB, pct(c.FaceL, c.nB), c.HouseR, c.nB, pct(c.HouseR, c.nB), c.left, c.n, pct(c.left, c.n));
end

function p = pct(k, n)
if n > 0; p = 100 * k / n; else; p = NaN; end
end
