function c = paramsToContrasts(x, i0)
% paramsToContrasts  Optimiser parameters -> contrast values.
%
% The optimiser works on log-scale parameters x = [g s e] (model 'shared')
% or x = [g s e i] (model 'perConfig'):
%   g : overall contrast level
%   s : ln(houseContrast / faceContrast)   (> 0: house has the higher contrast)
%   e : ln(leftEyeContrast / rightEyeContrast)
%   i : ln(contrast of pair A / contrast of pair B)   (default 0)
%       pair A = house left + face right,  pair B = house right + face left
%
% They map onto the numbers stored in the training file (stimulus contrast x
% eye contrast x configuration contrast = contrast of each texture):
%   houseContrast    = exp(g + s/2)      faceContrast     = exp(g - s/2)
%   leftEyeContrast  = exp(e/2)          rightEyeContrast = exp(-e/2)
%   configContrast   = exp(i/2)
%
%   houseLeft  = houseContrast * leftEyeContrast  * configContrast
%   faceRight  = faceContrast  * rightEyeContrast * configContrast      (pair A)
%   houseRight = houseContrast * rightEyeContrast / configContrast
%   faceLeft   = faceContrast  * leftEyeContrast  / configContrast      (pair B)
%
% i0 (optional, default 0) is used when x has only three elements: the
% configuration term is then kept fixed at that value.

if nargin < 2, i0 = 0; end
g = x(1);  s = x(2);  e = x(3);
if numel(x) >= 4, i = x(4); else, i = i0; end

c.houseContrast    = exp(g + s/2);
c.faceContrast     = exp(g - s/2);
c.leftEyeContrast  = exp(e/2);
c.rightEyeContrast = exp(-e/2);
c.configContrast   = exp(i/2);

c.houseLeft  = c.houseContrast * c.leftEyeContrast  * c.configContrast;
c.faceRight  = c.faceContrast  * c.rightEyeContrast * c.configContrast;
c.houseRight = c.houseContrast * c.rightEyeContrast / c.configContrast;
c.faceLeft   = c.faceContrast  * c.leftEyeContrast  / c.configContrast;
end
