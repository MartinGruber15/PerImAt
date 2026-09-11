function [design,ptb] = conditionAndKeyAssignment(design, ptb, subNr)
% key assignment
sub = str2double(subNr);
if  mod(sub, 2) == 0
    ptb.Keys.house = ptb.Keys.right;
    ptb.Keys.face = ptb.Keys.left;
else
    ptb.Keys.house = ptb.Keys.left;
    ptb.Keys.face = ptb.Keys.right;
end

% Color: colors(1,:) for subjects 0/1 mod 4,
%        colors(2,:) for subjects 2/3 mod 4
colors = design.conditionColors;
colorIdx = floor(mod(sub, 4) / 2) + 1;
design.houseColor = colors(colorIdx, :);
design.faceColor  = colors(3 - colorIdx, :);
design.fontColor = ptb.FontColor;