function [suffix,reportCond] = autoChooseNextBlock(maxRun, subjectDirectory, reportOrder)

% Condition order was established by getKeyAssignment()
reportCond = [];
blockNr = [];

% Check conditions in the predetermined counterbalanced order
for b = 1:numel(reportOrder)
    condition = reportOrder(b);

    % Has this condition completed all runs?
    allRunsFinished = true;

    % Determine filename suffix
    if condition == reportCondition.report
        suffix = 'r';
        conditionName = 'report';
    elseif condition == reportCondition.noReport
        suffix = 'nr';
        conditionName = 'noReport';
    elseif condition == reportCondition.dual
        suffix = 'du';
        conditionName = 'dual';
    end

    for runNr = 1:maxRun
        pattern = fullfile(subjectDirectory, ...
            sprintf('*run-%02d_%s*.csv', runNr, suffix));

        if isempty(dir(pattern))
            allRunsFinished = false;
            break;
        end
    end

    % First unfinished condition = next block
    if ~allRunsFinished
        reportCond = condition;
        fprintf('Next Report Condition: %s\n', conditionName);
        return
    end
end

% ==============================================================
% All conditions are finished
% ==============================================================

fprintf('\nAll report-condition blocks are finished!\n');
choice = input.chooseOption(["Repeat a condition", "End experiment"]);

if choice == "Repeat a condition"
    conditionNames = strings(1, numel(reportOrder));
    for b = 1:numel(reportOrder)
        if reportOrder(b) == reportCondition.report
            conditionNames(b) = "report";
        elseif reportOrder(b) == reportCondition.noReport
            conditionNames(b) = "noReport";
        elseif reportOrder(b) == reportCondition.dual
            conditionNames(b) = "dual";
        end
    end

    fprintf('\nChoose condition:\n');
    for b = 1:numel(conditionNames)
        fprintf('%d: %s\n', b, conditionNames(b));
    end

    while true
        blockNr = input(['Enter block number [1-' num2str(numel(reportOrder)) ']: '], 's');
        [blockNr, isNumber] = str2num(blockNr);
        if isNumber && isscalar(blockNr) && ...
                blockNr >= 1 && blockNr <= numel(reportOrder)
            reportCond = reportOrder(blockNr);
            break
        end
        fprintf('Enter a valid block number.\n');
    end

else
    fprintf('Ending experiment.\n');
end

end
