function c = contrastsFromBalance(thetaS, thetaE, baseContrast)
% questplus.contrastsFromBalance  Balance point (log2 units) -> contrast factors.
%
%   c = questplus.contrastsFromBalance(thetaS, thetaE, baseContrast)
%
% thetaS = log2(houseContrast/faceContrast), thetaE = log2(leftEye/rightEye).
% The factors are split symmetrically so that the geometric mean of the four
% textures equals baseContrast:
%   houseContrast = c0*2^(+thetaS/2)   faceContrast     = c0*2^(-thetaS/2)
%   leftEyeContrast = 2^(+thetaE/2)    rightEyeContrast = 2^(-thetaE/2)
% Field names match loadLatestTrainingParameters / input.adaptStimuli /
% generate.getContrastAdjustedImages (texture = stimulus factor * eye factor).

c.houseContrast    = baseContrast * 2^( thetaS / 2);
c.faceContrast     = baseContrast * 2^(-thetaS / 2);
c.leftEyeContrast  = 2^( thetaE / 2);
c.rightEyeContrast = 2^(-thetaE / 2);
c.textures.HouseL  = c.houseContrast * c.leftEyeContrast;
c.textures.FaceL   = c.faceContrast  * c.leftEyeContrast;
c.textures.HouseR  = c.houseContrast * c.rightEyeContrast;
c.textures.FaceR   = c.faceContrast  * c.rightEyeContrast;
end
