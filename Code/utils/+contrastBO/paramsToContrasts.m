function c = paramsToContrasts(logContrast)
% paramsToContrasts  Log-contrast vector -> contrast values.
%
% The optimiser works on log-scale numbers logContrast = [logLevel logHouseFace logLeftRight]:
%   logLevel      : overall contrast level (log of the geometric mean of the four textures)
%   logHouseFace  : ln(houseContrast / faceContrast)      (> 0: house has the higher contrast)
%   logLeftRight  : ln(leftEyeContrast / rightEyeContrast)
%
% They map onto the numbers stored in the training file (stimulus contrast x
% eye contrast = contrast of each texture).  The whole level sits on the
% stimulus contrasts, the eye contrasts only carry the ratio:
%   houseContrast   = exp(logLevel + logHouseFace/2)    faceContrast     = exp(logLevel - logHouseFace/2)
%   leftEyeContrast = exp( logLeftRight/2)              rightEyeContrast = exp(-logLeftRight/2)
%
%   houseLeft  = houseContrast * leftEyeContrast       faceLeft  = faceContrast * leftEyeContrast
%   houseRight = houseContrast * rightEyeContrast      faceRight = faceContrast * rightEyeContrast

logLevel = logContrast(1);  logHouseFace = logContrast(2);  logLeftRight = logContrast(3);

c.houseContrast    = exp(logLevel + logHouseFace/2);
c.faceContrast     = exp(logLevel - logHouseFace/2);
c.leftEyeContrast  = exp(logLeftRight/2);
c.rightEyeContrast = exp(-logLeftRight/2);

c.houseLeft  = c.houseContrast * c.leftEyeContrast;
c.faceRight  = c.faceContrast  * c.rightEyeContrast;
c.houseRight = c.houseContrast * c.rightEyeContrast;
c.faceLeft   = c.faceContrast  * c.leftEyeContrast;
end
