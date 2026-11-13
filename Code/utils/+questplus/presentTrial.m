function [res, aborted] = presentTrial(ptb, design, qpSet, raw, houseEye, x, baseContrast)
% questplus.presentTrial  Build the two rivalry textures for (houseEye, x) and run one trial.
% Used by questPlusCalibration.m (contrasts per trial from questplus.trialImages).
[leftImg, rightImg, cHouse, cFace] = questplus.trialImages(raw, houseEye, x, baseContrast, design.defaultLuminance);
[leftTex, rightTex] = questplus.makeRivalryTextures(ptb, design, leftImg, rightImg);
[res, aborted] = questplus.runTrial(ptb, design, qpSet, leftTex, rightTex);
Screen('Close', [leftTex, rightTex]);
res.cHouse = cHouse;
res.cFace = cFace;
end
