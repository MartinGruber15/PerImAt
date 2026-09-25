function closeAll(ptb, log, design,myPaths)
disp('Closing open connections and saving data')
% Eye tracker
if isfield(ptb, 'useEyetracker') && ptb.useEyetracker && isfield(myPaths,'subjectDirectory')
    try
        eyetracking.closeEyetracker(ptb, myPaths.subjectDirectory);
    catch ME
        warning('Could not close EyeLink properly: %s', ME.message);
    end
end

% DataPixx
if isfield(ptb, 'usedatapixx') && ptb.usedatapixx
    try
        Datapixx('Close');
    catch ME
        warning('Could not close DataPixx: %s', ME.message);
    end
end

% Psychtoolbox
try
    Screen('CloseAll');
catch ME
    warning('Could not close Psychtoolbox: %s', ME.message);
end

% Save log LAST
if isfield(myPaths,'subjectDirectory')
    try
        %save_utils.saveEnvironment(log,ptb,design,myPaths)
        disp('TODO reinclude log (etc) saving')
    catch ME
        warning('Could not save ptb data: %s', ME.message);
    end
end
end
