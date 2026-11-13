function cleanupObj = apply(window, gammaFilePath)

% Save original gamma table
originalGamma = repmat(linspace(0, 1, 256)', 1, 3);
% Load gamma file
gammaFile = load(gammaFilePath);
gammaTable = gammaFile.cal.iGammaTable;
% Clean tiny noise
gammaTable(gammaTable < 1e-6) = 0;
% Apply gamma correction
Screen('LoadNormalizedGammaTable', window, gammaTable);
% Restore original gamma if an error or cleanup occurs
cleanupObj = onCleanup(@() gamma_correct.safeRestoreGamma(window, originalGamma));
end
