function [isFin, reason, est] = isFinished(qp, qpSet, nValid, nTotal)
% questplus.isFinished  Stop rules of a run WITHOUT validation (qpSet.verify.enabled = false).
%
%   [isFin, reason, est] = questplus.isFinished(qp, qpSet, nValid, nTotal)
%
% nValid  number of house/face responses used by QUEST+
% nTotal  number of QUEST+ trials incl. mixed
%
% Order of evaluation (cf. QuestPlus.isFinished, petejonze/QuestPlus):
%   1. nTotal >= maxTotalTrials                -> stop (too many mixed)
%   2. nValid <  minValidTrials                -> continue
%   3. nValid >= maxValidTrials                -> stop
%   4. precision rule (qpSet.stopRule):
%      'balance' : posterior SD of P(house) at the estimated balance point
%                  <= stopCriterion in BOTH eye configurations
%      'sd'      : posterior SD of both balance points uA, uB <= stopCriterion (log2)
%      'entropy' : entropy (bits) of the marginal posterior of the two balance
%                  points <= stopCriterion (Watson 2017 / petejonze)
%      'ntrials' : never (only rules 1-3)

est = questplus.estimates(qp, qpSet, false);   % fast version (no CIs)
isFin = false; reason = '';

if nTotal >= qpSet.maxTotalTrials
    isFin = true; reason = sprintf('maxTotalTrials (%d) reached', qpSet.maxTotalTrials); return
end
if nValid < qpSet.minValidTrials
    return
end
if nValid >= qpSet.maxValidTrials
    isFin = true; reason = sprintf('maxValidTrials (%d) reached', qpSet.maxValidTrials); return
end

switch lower(qpSet.stopRule)
    case 'balance'
        if all(est.pAtEstimate.sd <= qpSet.stopCriterion)
            isFin = true;
            reason = sprintf('balance criterion: SD of P(house) = %.3f / %.3f <= %.3f', ...
                est.pAtEstimate.sd(1), est.pAtEstimate.sd(2), qpSet.stopCriterion);
        end
    case 'sd'
        if max(est.uA.sd, est.uB.sd) <= qpSet.stopCriterion
            isFin = true;
            reason = sprintf('sd criterion: SD of the balance points = %.3f / %.3f <= %.3f log2', ...
                est.uA.sd, est.uB.sd, qpSet.stopCriterion);
        end
    case 'entropy'
        H = est.entropyBits.marginal;
        if H <= qpSet.stopCriterion
            isFin = true; reason = sprintf('entropy criterion: H = %.2f bits <= %.2f', H, qpSet.stopCriterion);
        end
    case 'ntrials'
        % only min/max
    otherwise
        error('questplus:isFinished', 'Unknown stopRule "%s".', qpSet.stopRule);
end
end
