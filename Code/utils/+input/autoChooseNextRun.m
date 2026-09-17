function runNr = autoChooseNextRun(maxRun, subjectDirectory, suffix)
runNr = [];
for n = 1:maxRun
    pattern = fullfile(subjectDirectory,sprintf('*run-%02d_%s.csv', n, suffix));
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
end