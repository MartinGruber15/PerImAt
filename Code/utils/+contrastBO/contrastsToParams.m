function x = contrastsToParams(houseContrast, faceContrast, leftEyeContrast, rightEyeContrast, configContrast)
% contrastsToParams  Inverse of paramsToContrasts: contrasts -> x = [g s e i].
%
% Only the products (stimulus x eye x configuration contrast) matter for the
% shown textures, so a common factor between stimulus and eye contrast is
% absorbed into g.  The four texture contrasts are reproduced exactly.
% configContrast is optional (default 1 -> i = 0).

if nargin < 5, configContrast = 1; end
lh = log(houseContrast);
lf = log(faceContrast);
ll = log(leftEyeContrast);
lr = log(rightEyeContrast);

g = 0.5 * (lh + lf + ll + lr);
s = lh - lf;
e = ll - lr;
i = 2 * log(configContrast);
x = [g s e i];
end
