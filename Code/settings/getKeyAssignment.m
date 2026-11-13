function [design,ptb,log] = getKeyAssignment(design, ptb, log,offline)
% key assignment
sub = str2double(log.sub);
if isnan(sub)   % [added 2026-11-05] non-numeric ID such as 'test' (rawdata/sub-test)
    sub = 1;
    fprintf('Subject ID "%s" is not a number: keys, colours and report order as for subject 1.\n', log.sub);
end
% [changed 2026-11-12] Counterbalancing: each factor has its own rhythm, so that block
% order, key mapping and cue colour are crossed (before: house = left key for odd IDs,
% colour from floor(mod(ID,4)/2), order mod(ID, nOrders) + 1 -> every block order came
% with only one key mapping). With i = ID - 1:
%   house key    : left if mod(floor(i/2), 2) == 0, else right    (period 4)
%   house colour : colors(1,:) (red) if mod(i + floor(i/12), 2) == 0, else colors(2,:)
%   block order  : offline mod(i, 6) + 1; fMRI (2 orders) mod(floor(i/4), 2) + 1
% Offline: every 4 IDs all key x colour combinations, every 6 all block orders, every
% 12 each order with both key mappings, every 24 all 24 order x key x colour
% combinations. fMRI: all 8 combinations every 8 IDs. ID 1: house left, red.
i = sub - 1;
if mod(floor(i / 2), 2) == 0
    ptb.Keys.house = ptb.Keys.left;
    ptb.Keys.face = ptb.Keys.right;
else
    ptb.Keys.house = ptb.Keys.right;
    ptb.Keys.face = ptb.Keys.left;
end

% Colour of the cue cross: colors(1,:) or colors(2,:) for the house (see above)
colors = design.conditionColors;
colorIdx = mod(i + floor(i / 12), 2) + 1;
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

% Select one complete order based on subject number ([changed 2026-11-12], see above)
if offline
    orderIdx = mod(i, size(reportOrders, 1)) + 1;
else
    orderIdx = mod(floor(i / 4), size(reportOrders, 1)) + 1;
end
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

orderNames = strjoin(arrayfun(@(c) char(string(c)), design.reportOrder, 'UniformOutput', false), ' -> ');
fprintf(['House: %s key | Face: %s key | ' ...
         'House color: %s | Face color: %s | Block order %d: %s\n'], ...
    houseKeyLabel, ...
    faceKeyLabel, ...
    houseColorLabel, ...
    faceColorLabel, orderIdx, orderNames);   % [changed 2026-11-12] + block order

end