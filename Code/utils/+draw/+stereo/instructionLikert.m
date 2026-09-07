function instructionLikert(ptb, design, text, nOptions)
cueY = ptb.yCenter - design.stimSizeInPixelsY/3;
% Likert scale
scaleWidth = design.stimSizeInPixelsX;
xPos = linspace(ptb.xCenter - scaleWidth/2,ptb.xCenter + scaleWidth/2, nOptions);
circleSize = design.fixCrossInPixelsX;
labelY = ptb.yCenter + circleSize*2;

% Get label widths so they can be centered under the first/last option
leftBounds = Screen('TextBounds', ptb.window, 'Strongly disagree');
rightBounds = Screen('TextBounds', ptb.window, 'Strongly agree');
leftTextWidth = leftBounds(3) - leftBounds(1);
rightTextWidth = rightBounds(3) - rightBounds(1);

%% Left eye
Screen('SelectStereoDrawBuffer', ptb.window, ptb.leftBuffer);
% Question
DrawFormattedText(ptb.window, text,'center', cueY, ptb.FontColor);
% Likert circles
for i = 1:nOptions
    Screen('FrameOval', ptb.window, ptb.FontColor, ...
        [xPos(i)-circleSize/2, ptb.yCenter-circleSize/2, ...
        xPos(i)+circleSize/2, ptb.yCenter+circleSize/2], ...
        ptb.lineWidthInPix);
end
% Labels centered under first and last option
DrawFormattedText(ptb.window, 'Strongly disagree',xPos(1) - leftTextWidth/2, labelY, ptb.FontColor);
DrawFormattedText(ptb.window, 'Strongly agree',xPos(end) - rightTextWidth/2, labelY, ptb.FontColor);

%% Right eye
Screen('SelectStereoDrawBuffer', ptb.window, ptb.rightBuffer);
% Question
DrawFormattedText(ptb.window, text,'center', cueY, ptb.FontColor);
% Likert circles
for i = 1:nOptions
    Screen('FrameOval', ptb.window, ptb.FontColor, ...
        [xPos(i)-circleSize/2, ptb.yCenter-circleSize/2, ...
        xPos(i)+circleSize/2, ptb.yCenter+circleSize/2], ...
        ptb.lineWidthInPix);
end
% Labels centered under first and last option
DrawFormattedText(ptb.window, 'Strongly disagree', xPos(1) - leftTextWidth/2, labelY, ptb.FontColor);
DrawFormattedText(ptb.window, 'Strongly agree', xPos(end) - rightTextWidth/2, labelY, ptb.FontColor);

Screen('DrawingFinished', ptb.window);
end
