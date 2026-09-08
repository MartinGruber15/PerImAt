function closeEyetracker(ptb, subjectDirectory)
% closeEyelink: Stops EyeLink recording, closes the EDF file, and
% retrieves the EDF file from the EyeLink host.
%
%   ptb              - struct containing Psychtoolbox parameters
%   subjectDirectory - directory in which to save the EDF file

if ~ptb.useEyetracker
    return;
end

% Stop recording
Eyelink('StopRecording');

% Close the EDF file on the EyeLink
Eyelink('CloseFile');

% Retrieve EDF file from the EyeLink
status = Eyelink('ReceiveFile', ptb.eyelink.edfFile, subjectDirectory, 1);
if status < 0
    warning('Failed to retrieve EyeLink file: %s',ptb.eyelink.edfFile);
else
    fprintf('EyeLink data saved: %s\n',fullfile(subjectDirectory, ptb.eyelink.edfFile));
end
end
