function logContrast = contrastsToParams(houseContrast, faceContrast, leftEyeContrast, rightEyeContrast)
% contrastsToParams  Inverse of paramsToContrasts: contrasts -> log-contrast
%                    vector [logLevel logHouseFace logLeftRight].
%
% Only the products (stimulus x eye contrast) matter for the shown textures, so
% a common factor between stimulus and eye contrast is absorbed into logLevel.
% The four texture contrasts are reproduced exactly.

logHouse = log(houseContrast);
logFace  = log(faceContrast);
logLeft  = log(leftEyeContrast);
logRight = log(rightEyeContrast);

logLevel     = 0.5 * (logHouse + logFace + logLeft + logRight);
logHouseFace = logHouse - logFace;
logLeftRight = logLeft - logRight;
logContrast  = [logLevel logHouseFace logLeftRight];
end
