function runNr = inputRun(maxRun, subjectDirectory)
% Function to enter run number
if nargin < 1
    maxRun = 2;
end

correctRunInput = false;
% check run input
while ~correctRunInput
    runNr = input(['Enter run  Nr [1-' num2str(maxRun) ']:'], 's');
    [runNr,isNumber] = str2num(runNr);
    if isNumber && runNr>0 && runNr<=maxRun
        if ~isempty(dir(fullfile(subjectDirectory, sprintf('*run-%02d.csv', runNr))))
            fprintf('There is already a file for run %d . Do you want to overwrite it?\n', runNr);
            choice = input.chooseOption(["NO", "yes"]);
            if choice == "yes"
                correctRunInput = true;
            end
        else
            correctRunInput = true;
        end
    end
end
end
