function s = contrastText(c, withTextures)
% questplus.contrastText  The four contrast factors as they are entered in the settings. [added 2026-11-06]
%
%   s = questplus.contrastText(c)          % 'house 1.1518 face 0.7640 | left eye 0.9013 right eye 1.1095'
%   s = questplus.contrastText(c, true)    % + the four texture contrasts (stimulus x eye)
%
% c: struct from questplus.contrastsFromBalance (houseContrast, faceContrast,
% leftEyeContrast, rightEyeContrast; the values of <sub>_training_<n>.mat /
% input.adaptStimuli).
if nargin < 2; withTextures = false; end
s = sprintf('house %.4f  face %.4f | left eye %.4f  right eye %.4f', ...
    c.houseContrast, c.faceContrast, c.leftEyeContrast, c.rightEyeContrast);
if withTextures
    s = sprintf('%s   (textures HouseL %.3f FaceR %.3f | FaceL %.3f HouseR %.3f)', s, ...
        c.houseContrast * c.leftEyeContrast, c.faceContrast * c.rightEyeContrast, ...
        c.faceContrast * c.leftEyeContrast, c.houseContrast * c.rightEyeContrast);
end
end
