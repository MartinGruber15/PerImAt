function [design,ptb,log] = getKeyAssignment(design, ptb, log,offline)
% key assignment
sub = str2double(log.sub);
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

%% Report condition order
if offline
    reportConditions = [ ...
        reportCondition.report, ...
        reportCondition.noReport, ...
        reportCondition.dual ...
        ];

    reportOrders = perms(reportConditions);

else
    reportConditions = [ ...
        reportCondition.report, ...
        reportCondition.noReport ...
        ];

    reportOrders = perms(reportConditions);
end

% Select one complete order based on subject number
orderIdx = mod(sub, size(reportOrders, 1)) + 1;
design.reportOrder = reportOrders(orderIdx, :);


if ptb.Keys.house == ptb.Keys.right
    houseKeyLabel = 'right';
    faceKeyLabel  = 'left';
else
    houseKeyLabel = 'left';
    faceKeyLabel  = 'right';
end

if isequal(design.houseColor, design.conditionColors(1,:))
    houseColorLabel = 'red';
    faceColorLabel  = 'blue';
else
    houseColorLabel = 'blue';
    faceColorLabel  = 'red';
end

fprintf(['House: %s key | Face: %s key | ' ...
         'House color: %s | Face color: %s\n'], ...
    houseKeyLabel, ...
    faceKeyLabel, ...
    houseColorLabel, ...
    faceColorLabel);

end