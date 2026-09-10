function fixCrossPlusText(ptb, design, text, fixCrossColor)
% Save current text size and make instruction text larger
oldTextSize = Screen('TextSize', ptb.window);
Screen('TextSize', ptb.window, round(ptb.PixPerDegHeight * 0.5));

Screen('SelectStereoDrawBuffer', ptb.window, ptb.leftBuffer);
% Background
Screen('DrawTexture', ptb.window, design.backGroundTexture);
% Grey frame + circular aperture + ring + corner Xs
Screen('DrawTexture',ptb.window,design.frameTexture,[],design.frameRect);
DrawFormattedText(ptb.window, text, 'center', design.cueY, ptb.FontColor);
Screen('DrawLines',ptb.window,design.fixCrossCoords,design.fixCrossLineWidth,fixCrossColor,[design.centerX design.centerY]);

Screen('SelectStereoDrawBuffer', ptb.window, ptb.rightBuffer);
% Background
Screen('DrawTexture', ptb.window, design.backGroundTexture);
% Grey frame + circular aperture + ring + corner Xs
Screen('DrawTexture',ptb.window,design.frameTexture,[],design.frameRect);
DrawFormattedText(ptb.window, text, 'center', design.cueY, ptb.FontColor);
Screen('DrawLines',ptb.window,design.fixCrossCoords,design.fixCrossLineWidth,fixCrossColor,[design.centerX design.centerY]);

Screen('DrawingFinished', ptb.window);

% Restore previous text size
Screen('TextSize', ptb.window, oldTextSize);
end
