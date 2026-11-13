function [houseEye, x, sch] = chooseNextTrial(qp, qpSet, sch)
% questplus.chooseNextTrial  Eye configuration and contrast ratio of the next trial.
%
%   [houseEye, x, sch] = questplus.chooseNextTrial(qp, qpSet, sch)
%
% 1. Eye configuration: from the balanced, shuffled block schedule
%    (questplus.schedule, qpSet.blockSize).
% 2. Contrast ratio x: minimum expected entropy given that configuration
%    (questplus.selectStimulus).
% With qpSet.avoidRepeatAfterMixed, stimuli that got 'mixed' since the last
% house/face response (sch.mixedSinceUpdate, set by questplus.processResponse)
% are excluded: the posterior has not changed, so QUEST+ would otherwise pick
% exactly the same stimulus again.
% Used by questPlusCalibration.m (and tests/dryRunCalibration.m).

exclude = [];
if isfield(qpSet, 'avoidRepeatAfterMixed') && qpSet.avoidRepeatAfterMixed && ...
        isfield(sch, 'mixedSinceUpdate') && ~isempty(sch.mixedSinceUpdate)
    exclude = false(numel(qp.xDomain), 2);
    for i = 1:size(sch.mixedSinceUpdate, 1)
        c = find(qp.houseEyeValues == sch.mixedSinceUpdate(i, 1));
        [~, xi] = min(abs(qp.xDomain - sch.mixedSinceUpdate(i, 2)));
        exclude(xi, c) = true;
    end
end

[houseEye, sch] = questplus.schedule('next', sch);            % eye configuration: balanced blocks
x = questplus.selectStimulus(qp, qpSet, houseEye, exclude);     % contrast ratio: minimum expected entropy
end
