function [leftImg, rightImg, cHouse, cFace] = trialImages(raw, houseEye, x, baseContrast, targetLuminance)
% questplus.trialImages  Contrast-adjusted images for one QUEST+ trial.
%
%   [leftImg, rightImg, cHouse, cFace] = questplus.trialImages(raw, houseEye, x, c0, lum)
%
% The two textures on screen get c0*2^(+x/2) (house) and c0*2^(-x/2) (face),
% so their log2 contrast ratio is x and their geometric mean stays c0
% (symmetric anchoring). houseEye = +1: house left / face right,
% -1: face left / house right.

cHouse = baseContrast * 2^( x / 2);
cFace  = baseContrast * 2^(-x / 2);
% [changed 2026-11-10] centre of the scaling = mean of the visible content
% (raw.refMask from questplus.captureRawStimuli; [] = whole image)
mH = []; mF = [];
if isfield(raw, 'refMask'); mH = raw.refMask.house; mF = raw.refMask.face; end
if houseEye == 1
    leftImg  = questplus.applyContrast(raw.houseL, cHouse, targetLuminance, mH);
    rightImg = questplus.applyContrast(raw.faceR,  cFace,  targetLuminance, mF);
else
    leftImg  = questplus.applyContrast(raw.faceL,  cFace,  targetLuminance, mF);
    rightImg = questplus.applyContrast(raw.houseR, cHouse, targetLuminance, mH);
end
end
