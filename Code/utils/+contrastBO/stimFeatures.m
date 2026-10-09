function designMatrix = stimFeatures(logContrastShown, houseLeft, cfg)
% stimFeatures  Design matrix of the house-vs-face model, one row per trial.
%   logContrastShown  n x 3   [logLevel logHouseFace logLeftRight] of each trial
%   houseLeft         n x 1   true if the house was shown to the left eye
% Columns match cfg.paramPriorMean = [stimBias stimSlope eyeBias eyeSlope]:
%   [1,  logHouseFace - startHouseFace,  houseSide,  houseSide * (logLeftRight - startLeftRight)]

n = size(logContrastShown, 1);
houseSide = 2 * double(houseLeft(:)) - 1;                       % +1 house left, -1 house right
dHouseFace = logContrastShown(:, 2) - cfg.startLog(2);
dLeftRight = logContrastShown(:, 3) - cfg.startLog(3);
designMatrix = [ones(n, 1), dHouseFace, houseSide, houseSide .* dLeftRight];
end
