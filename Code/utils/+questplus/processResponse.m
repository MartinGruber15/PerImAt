function [qp, sch, isValid] = processResponse(qp, qpSet, sch, houseEye, x, response)
% questplus.processResponse  Feed one response into QUEST+ / the schedule.
%
%   [qp, sch, isValid] = questplus.processResponse(qp, qpSet, sch, houseEye, x, response)
%
% response 'house' | 'face' -> posterior update (questplus.update); clears
%                              sch.mixedSinceUpdate
%          'mixed'          -> no update; the same eye configuration is
%                              re-queued (questplus.schedule);
%                              [houseEye x] is added to sch.mixedSinceUpdate so
%                              that chooseNextTrial does not repeat it
% Used by questPlusCalibration.m (and tests/dryRunCalibration.m).

switch lower(response)
    case 'house'
        qp = questplus.update(qp, houseEye, x, true);  isValid = true;
        sch.mixedSinceUpdate = zeros(0, 2);
    case 'face'
        qp = questplus.update(qp, houseEye, x, false); isValid = true;
        sch.mixedSinceUpdate = zeros(0, 2);
    case 'mixed'
        isValid = false;
        if ~isfield(sch, 'mixedSinceUpdate'); sch.mixedSinceUpdate = zeros(0, 2); end
        sch.mixedSinceUpdate(end+1, :) = [houseEye, x];
        [~, sch] = questplus.schedule('requeue', sch, houseEye);
    otherwise
        error('questplus:processResponse', 'Unknown response "%s".', response);
end
end
