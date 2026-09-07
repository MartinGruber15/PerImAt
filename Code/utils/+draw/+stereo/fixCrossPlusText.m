function fixCrossPlusText(ptb, design, text, fixCrossColor)
cueY = ptb.yCenter - design.stimSizeInPixelsY/3;
% Save current text size and make instruction text larger
oldTextSize = Screen('TextSize', ptb.window);
Screen('TextSize', ptb.window, round(ptb.PixPerDegHeight * 0.5));

Screen('SelectStereoDrawBuffer', ptb.window, ptb.leftBuffer);
DrawFormattedText(ptb.window, text, 'center', cueY, ptb.FontColor);
Screen('DrawLines',ptb.window,design.fixCrossCoords, ptb.lineWidthInPix,fixCrossColor,[ptb.xCenter ptb.yCenter]);

Screen('SelectStereoDrawBuffer', ptb.window, ptb.rightBuffer);
DrawFormattedText(ptb.window, text, 'center', cueY, ptb.FontColor);
Screen('DrawLines',ptb.window,design.fixCrossCoords, ptb.lineWidthInPix,fixCrossColor,[ptb.xCenter ptb.yCenter]);

Screen('DrawingFinished', ptb.window);

% Restore previous text size
Screen('TextSize', ptb.window, oldTextSize);
end
