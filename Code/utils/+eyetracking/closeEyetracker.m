function closeEyetracker(ptb, subjectDirectory)
% closeEyelink: Stops EyeLink recording, closes the EDF file, and
% retrieves the EDF file from the EyeLink host.
%
%   ptb              - struct containing Psychtoolbox parameters
%   subjectDirectory - directory in which to save the EDF file
%
% [changed 2026-11-13] The file on the EyeLink host keeps its short name
% (max. 8 characters, e.g. v09r01du.edf, set in eyetracking.startEyetracker).
% The local copy in the subject folder gets a time stamp, so that a repeated
% run (same host name) does not overwrite an earlier file:
%   <subject folder>/v09r01du_2026-11-13_141502.edf

if ~ptb.useEyetracker || ~ptb.eyelink.initialized
    return;
end

% Stop recording
Eyelink('StopRecording');

% Close the EDF file on the EyeLink
Eyelink('CloseFile');

% Retrieve EDF file from the EyeLink
hostFile  = [ptb.eyelink.edfFile '.edf'];                       % name on the EyeLink host (unchanged)
timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HHmmss'));
localFile = fullfile(subjectDirectory, [ptb.eyelink.edfFile '_' timeStamp '.edf']);
% 3rd argument 0: the destination is a full file name (not a folder), so the
% local copy can have a different name than the file on the host
status = Eyelink('ReceiveFile', hostFile, localFile, 0);
if status < 0
    warning('Failed to retrieve EyeLink file %s (would have been saved as %s).', hostFile, localFile);
else
    fprintf('EyeLink data saved: %s\n', localFile);
end
end
