function choice = chooseOption(options)
% chooseOption  Prompt user to choose from a list of options
%   options : cellstr or string array of labels
%   returns choice (string)
options = string(options(:)); % column vector

% Special case: yes/no question
if numel(options) == 2 && all(ismember(lower(options), ["yes", "no"]))
    fprintf('Choose an option.\n');
    fprintf('  Yes - y\n');
    fprintf('  No  - n\n');
    validInput = false;
    while ~validInput
        s = strtrim(lower(input('Enter y/n: ', 's')));
        switch s
            case {"y", "yes"}
                choice = "yes";
                validInput = true;
            case {"n", "no"}
                choice = "no";
                validInput = true;
            otherwise
                fprintf('Please enter y/yes or n/no.\n');
        end
    end
    return
end

% Print numbered menu (0-based)
fprintf('%s\n', 'Choose an option.');
for k = 0:numel(options)-1; fprintf('  %s  - %d\n', char(options(k+1)), k);end

% Read and validate
validInput = false;
while ~validInput
    s = input('Enter number: ', 's');
    [v, choice] = str2num(s);
    if choice && isscalar(v) && v==floor(v) && v>=0 && v<=numel(options)-1
        choice = options(v+1);
        validInput = true;
    else
        fprintf('Please input an integer between 0 and %d.\n', numel(options)-1);
    end
end
end
