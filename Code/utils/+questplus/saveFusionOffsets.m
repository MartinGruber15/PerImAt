function offsets = saveFusionOffsets(participantInfo, myPaths)
% questplus.saveFusionOffsets  Keep the fusion offsets of alignFusion.
%
%   offsets = questplus.saveFusionOffsets(participantInfo, myPaths)
%
% display.stereo.alignFusion starts from participantInfo.horizontalOffset /
% verticalOffset if they exist, but the offsets were never written to the
% subject's participantInfo.mat (main.m saves to <subjectDirectory>.mat), so
% every new MATLAB session started from 0 and the offsets were not logged.
% This writes them into <subjectDirectory>/participantInfo.mat (other fields
% of the file are kept) and returns them for the results file, so that
% fusion can be compared between calibration and test runs.

offsets = struct('horizontal', NaN, 'vertical', NaN);
if isfield(participantInfo, 'horizontalOffset'); offsets.horizontal = participantInfo.horizontalOffset; end
if isfield(participantInfo, 'verticalOffset');   offsets.vertical   = participantInfo.verticalOffset;   end
f = fullfile(myPaths.subjectDirectory, 'participantInfo.mat');
try
    newInfo = participantInfo;
    if exist(f, 'file') == 2
        S = load(f, 'participantInfo');
        if isfield(S, 'participantInfo')
            newInfo = S.participantInfo;
            newInfo.horizontalOffset = offsets.horizontal;
            newInfo.verticalOffset   = offsets.vertical;
        end
    end
    participantInfo = newInfo; %#ok<NASGU>
    save(f, 'participantInfo');
catch err
    warning('questplus:saveFusionOffsets', 'Could not save the fusion offsets to %s: %s', f, err.message);
end
fprintf('Fusion offsets: x %+.3f, y %+.3f (default for the next alignment)\n', offsets.horizontal, offsets.vertical);
end
