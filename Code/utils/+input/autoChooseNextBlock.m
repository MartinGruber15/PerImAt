function [reportCond,suffix] = autoChooseNextBlock(maxRun, subjectDirectory, reportOrder)

reportCond = [];
suffix = [];
% ==============================================================
% Find the first unfinished condition
% ==============================================================
proposedCond = [];
for b = 1:numel(reportOrder)
    condition = reportOrder(b);
    % Determine filename suffix
    if condition == reportCondition.report
        suffix = 'r';
    elseif condition == reportCondition.noReport
        suffix = 'nr';
    elseif condition == reportCondition.dual
        suffix = 'du';
    else
        error('Unknown report condition.');
    end

    % Check whether all runs for this condition are finished
    allRunsFinished = true;
    for runNr = 1:maxRun
        pattern = fullfile(subjectDirectory, ...
            sprintf('*run-%02d_%s*.csv', runNr, suffix));
        if isempty(dir(pattern))
            allRunsFinished = false;
            break;
        end
    end

    if ~allRunsFinished
        proposedCond = condition;
        break
    end
end


% ==============================================================
% All conditions finished
% ==============================================================

if isempty(proposedCond)
    fprintf('\nAll report-condition blocks are finished!\n');
    choice = input.chooseOption( ...
        ["Repeat a condition", "End experiment"]);
    if choice == "End experiment"
        fprintf('Ending experiment.\n');
        return
    end
end


% ==============================================================
% Let user choose next condition
% ==============================================================

[reportCond,suffix] = input.chooseNextBlock(reportOrder, proposedCond);

end
