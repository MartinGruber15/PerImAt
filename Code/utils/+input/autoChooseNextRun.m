function runNr = autoChooseNextRun(maxRun, subjectDirectory, suffix)
runNr = [];
for n = 1:maxRun
    pattern = fullfile(subjectDirectory,sprintf('*run-%02d_%s*.csv', n, suffix));
    if isempty(dir(pattern))
        fprintf('Do you want to continue with run %d?\n', n);
        choice = lower(input.chooseOption(["Yes", "No"]));
        if choice == "yes"
            runNr = n;
        else
            fprintf('Manually choose the run to continue with\n')
            runNr = input.inputRun(maxRun, subjectDirectory);
        end
        break;
    end
end
if isempty(runNr)
    disp('All runs finished! Do you want to repeat a run?');
    choice = lower(input.chooseOption(["Yes", "No"]));
    if choice == "yes"
        runNr = input.inputRun(maxRun, subjectDirectory);
    else
        disp('Ending experiment')
    end
end
end