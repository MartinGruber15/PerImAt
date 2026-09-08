function fixCrossPlusLegend(ptb, design, text, fixCrossColor)

% Text position
cueY = ptb.yCenter - design.stimSizeInPixelsY/5;
textY = ptb.yCenter + design.stimSizeInPixelsY/5;
% Save current text size and make legend text larger
oldTextSize = Screen('TextSize', ptb.window);
Screen('TextSize', ptb.window, round(ptb.PixPerDegHeight * 0.5));

% Left eye
Screen('SelectStereoDrawBuffer', ptb.window, ptb.leftBuffer);
% condition
DrawFormattedText(ptb.window, text, 'center', cueY, ptb.FontColor);
% Fixation cross
Screen('DrawLines', ptb.window,design.fixCrossCoords,ptb.lineWidthInPix,fixCrossColor,[ptb.xCenter ptb.yCenter]);
% Legend
DrawFormattedText(ptb.window, '+',ptb.xCenter - design.stimSizeInPixelsX/4,textY, design.houseColor);
DrawFormattedText(ptb.window, ' -> house',ptb.xCenter - design.stimSizeInPixelsX/4 + 20,textY, ptb.FontColor);
DrawFormattedText(ptb.window, '+',ptb.xCenter - design.stimSizeInPixelsX/4,textY + ptb.PixPerDegHeight * 0.5, design.faceColor);
DrawFormattedText(ptb.window, ' -> face',ptb.xCenter - design.stimSizeInPixelsX/4 + 20,textY + ptb.PixPerDegHeight * 0.5, ptb.FontColor);

% Right eye
Screen('SelectStereoDrawBuffer', ptb.window, ptb.rightBuffer);
% condition
DrawFormattedText(ptb.window, text, 'center', cueY, ptb.FontColor);
% Fixation cross
Screen('DrawLines', ptb.window,design.fixCrossCoords,ptb.lineWidthInPix,fixCrossColor,[ptb.xCenter ptb.yCenter]);
% Legend
DrawFormattedText(ptb.window, '+',ptb.xCenter - design.stimSizeInPixelsX/4,textY, design.houseColor);
DrawFormattedText(ptb.window, ' -> house',ptb.xCenter - design.stimSizeInPixelsX/4 + 20,textY, ptb.FontColor);
DrawFormattedText(ptb.window, '+',ptb.xCenter - design.stimSizeInPixelsX/4,textY + ptb.PixPerDegHeight * 0.5, design.faceColor);
DrawFormattedText(ptb.window, ' -> face',ptb.xCenter - design.stimSizeInPixelsX/4 + 20,textY + ptb.PixPerDegHeight * 0.5, ptb.FontColor);

Screen('DrawingFinished', ptb.window);

% Restore previous text size
Screen('TextSize', ptb.window, oldTextSize);
end
