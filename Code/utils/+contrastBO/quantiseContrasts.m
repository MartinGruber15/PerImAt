function [c, logContrastReal] = quantiseContrasts(logContrast, cfg)
% quantiseContrasts  Contrasts that are really used for logContrast =
%                    [logLevel logHouseFace logLeftRight].
%
%   [c, logContrastReal] = contrastBO.quantiseContrasts(logContrast, cfg)
%
% The four contrasts that are stored in the training file (house, face, left
% eye, right eye) are rounded to multiples of cfg.contrastStep (default 0.01;
% steps much smaller than that do not change a single grey level of the 8-bit
% image) and are never below one step.  The texture contrasts are the products
% of these numbers (stimulus x eye contrast, as in getVisualDesignSettings), so
% a texture can deviate from cMin..cMax by up to about one rounding step.
%
% c has the same fields as paramsToContrasts; logContrastReal is the
% log-contrast vector of the contrasts that are actually shown (the model is
% fitted with these).

c0 = contrastBO.paramsToContrasts(logContrast);
contrasts = [c0.houseContrast, c0.faceContrast, c0.leftEyeContrast, c0.rightEyeContrast];
rounded = max(round(contrasts / cfg.contrastStep) * cfg.contrastStep, cfg.contrastStep);
rounded = round(1e6 * rounded) / 1e6;       % remove floating-point dust

c.houseContrast    = rounded(1);
c.faceContrast     = rounded(2);
c.leftEyeContrast  = rounded(3);
c.rightEyeContrast = rounded(4);
c.houseLeft  = rounded(1) * rounded(3);
c.faceRight  = rounded(2) * rounded(4);
c.houseRight = rounded(1) * rounded(4);
c.faceLeft   = rounded(2) * rounded(3);

% log-contrast vector of what is shown (the house/face and left/right ratios are
% exact; the level can differ from logContrast by the rounding of the left/right
% eye contrast, < 1 %)
logContrastReal = contrastBO.contrastsToParams(rounded(1), rounded(2), rounded(3), rounded(4));
end
