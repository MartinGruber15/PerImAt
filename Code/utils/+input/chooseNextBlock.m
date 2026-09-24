function [reportCond,suffix] = chooseNextBlock(reportOrder, proposedCond)

% chooseNextBlock
%
% Select the next report condition.
%
% proposedCond:
%   - condition suggested by the automatic block detection
%   - [] if there is no suggested condition (e.g. all blocks finished)
%
% If a proposed condition exists, the user is asked whether to continue
% with it or choose another condition.
%
% If proposedCond is empty, the user is directly asked to choose a
% condition.

% --------------------------------------------------------------
% Create condition names corresponding to reportOrder
% --------------------------------------------------------------
conditionNames = strings(1, numel(reportOrder));
for b = 1:numel(reportOrder)
    if reportOrder(b) == reportCondition.report
        conditionNames(b) = "report";
    elseif reportOrder(b) == reportCondition.noReport
        conditionNames(b) = "noReport";
    elseif reportOrder(b) == reportCondition.dual
        conditionNames(b) = "dual";
    else
        error('Unknown report condition.');
    end
end
% --------------------------------------------------------------
% Suggested condition exists
% --------------------------------------------------------------
condFound=false;
if ~isempty(proposedCond)
    proposedIdx = find(reportOrder == proposedCond, 1);
    proposedName = conditionNames(proposedIdx);
    fprintf('\nDo you want to continue with: %s ?\n', proposedName);
    choice = input.chooseOption( ...
        ["yes","no"]);
    if choice == "yes"
        reportCond = proposedCond;
        condFound= true;
    end
end
% --------------------------------------------------------------
% Choose condition manually
% --------------------------------------------------------------
if ~condFound
reportCond = reportOrder( ...
    conditionNames == input.chooseOption(conditionNames));
end
if reportCond == reportCondition.report
    suffix = 'r';
elseif reportCond == reportCondition.noReport
    suffix = 'nr';
elseif reportCond == reportCondition.dual
    suffix = 'du';

end
