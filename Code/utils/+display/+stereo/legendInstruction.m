function legendInstruction(ptb, design, text, waitDuration, autoContinue)

switchOrder = rand < 0.5;

% Left eye
Screen('SelectStereoDrawBuffer', ptb.window, ptb.leftBuffer);
DrawFormattedText(ptb.window, text, 'center', design.cueY, ptb.FontColor);

% Legend
drawLegend(ptb, design, switchOrder);
if ptb.usedatapixx
    Screen('FillRect', ptb.window, [0, 0, 255], design.blueRectLeftOn);
    Screen('FillRect', ptb.window, [0, 0, 0], design.blueRectLeftOff);
end

% Right eye
Screen('SelectStereoDrawBuffer', ptb.window, ptb.rightBuffer);
DrawFormattedText(ptb.window, text, 'center', design.cueY, ptb.FontColor);
% Legend
drawLegend(ptb, design, switchOrder)
if ptb.usedatapixx
    Screen('FillRect', ptb.window, [0, 0, 255], design.blueRectRightOn);
    Screen('FillRect', ptb.window, [0, 0, 0], design.blueRectRightOff);
end
Screen('DrawingFinished', ptb.window);
Screen ('Flip', ptb.window);
WaitSecs (waitDuration);
if ~autoContinue
    KbWait(ptb.Keyboard2, 2);
end
end

function drawLegend(ptb, design, switchOrder)

order = [1 2];
if switchOrder
    order = [2 1];
end
colors = {design.houseColor, design.faceColor};
textures = {design.housePictogramTexture, design.facePictogramTexture};
for row = 1:2
    i = order(row);
    y = design.legendY1 + (row-1)*design.legendYSpacing;
    pictogramRect = [design.legendPictogramX, y,design.legendPictogramX + design.legendPictogramSize,y + design.legendPictogramSize];

    drawLegendCross(ptb.window, design.legendCrossCenterX,y + design.legendPictogramSize/2, design.legendCrossSize, colors{i});
    drawLegendArrow(ptb.window, design.legendArrowX,y + design.legendPictogramSize/2, design.legendArrowLength, ptb.FontColor);
    Screen('DrawTexture', ptb.window, textures{i}, [], pictogramRect);
end
end


function drawLegendCross(window, centerX, centerY, size, color)
coords = [-size/2 size/2 0 0; 0 0 -size/2 size/2];
Screen('DrawLines', window, coords, 2, color, [centerX centerY]);
end


function drawLegendArrow(window, x, centerY, length, color)
shaftY = centerY;
headLength = length * 0.25;
headHeight = length * 0.20;
% Arrow shaft
Screen('DrawLine', window, color, ...
    x, shaftY, x + length, shaftY, 2);
% Arrow head
Screen('DrawLine', window, color, ...
    x + length, shaftY, ...
    x + length - headLength, shaftY - headHeight, 2);
Screen('DrawLine', window, color, ...
    x + length, shaftY, ...
    x + length - headLength, shaftY + headHeight, 2);
end