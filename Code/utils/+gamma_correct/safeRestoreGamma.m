function safeRestoreGamma(win, originalGamma)
try
    if Screen('WindowKind', win) ~= 0
        Screen('LoadNormalizedGammaTable', win, originalGamma);
    end
catch
    % fallback: restore to desktop screen
    Screen('LoadNormalizedGammaTable', 0, originalGamma);
end
end
