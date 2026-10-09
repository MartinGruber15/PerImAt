function [logContrast, info] = chooseParams(model, cfg, mode)
% chooseParams  Contrasts [logLevel logHouseFace logLeftRight] to use next, or
%               the current best estimate.
%
%   logContrast = contrastBO.chooseParams(model, cfg, 'sample')   next trial (Thompson sampling)
%   logContrast = contrastBO.chooseParams(model, cfg, 'map')      current best estimate
%   [logContrast, info] = contrastBO.chooseParams(...)            also says whether it had to be shrunk
%
% 'sample': draw ONE plausible parameter set from the posterior and return its
%   balance point.  While the posterior is wide, draws differ a lot, so many
%   different contrasts get tested (exploration); as data accumulate, draws
%   agree and the trials concentrate around the balance point (exploitation).
% 'map': use the most probable parameters instead of a random draw.
%
% The balance point of a parameter set: logLevel stays at its start value;
% logHouseFace and logLeftRight are the values at which house/face and
% left/right are equally likely to be reported (logit = 0):
%   balanceHouseFace = startHouseFace - stimBias / stimSlope
%   balanceLeftRight = startLeftRight - eyeBias  / eyeSlope
% If the start level leaves too little room, both are shrunk by the same factor
% so that all four textures stay within cMin..cMax; the balance point is then
% only approximated.
%
% info.shrunk   true if the two ratios had to be shrunk
% info.factor   the factor they were multiplied with (1 = not shrunk)
% info.wanted   [balanceHouseFace balanceLeftRight] asked for (before shrinking)
% info.used     [logHouseFace logLeftRight] returned
% info.needSum  |logHouseFace|+|logLeftRight| asked for
% info.roomSum  |logHouseFace|+|logLeftRight| that fits into cMin..cMax
% info.limit    'cMax' or 'cMin': which end of the range is reached first
% info.clipped  true if a balance point hit the maximum ratio cfg.maxLogRatio

if strcmpi(mode, 'sample')
    params = drawParams(model.stim, cfg);
else
    params = model.stim.params(:);
    params([2 4]) = max(params([2 4]), cfg.minSlope);
end
[logContrast, info] = balancePoint(params, cfg);
end


%% ------------------------------------------------------------------------
function params = drawParams(post, cfg)
% posterior draw, re-drawn while a contrast slope is implausibly small
for attempt = 1:100
    params = drawGaussian(post.params, post.paramCov);
    if params(2) >= cfg.minSlope && params(4) >= cfg.minSlope, return; end
end
params([2 4]) = max(params([2 4]), cfg.minSlope);
end

function draw = drawGaussian(mu, covariance)
mu = mu(:);
[cholFactor, notPosDef] = chol(covariance + 1e-9 * eye(numel(mu)), 'lower');
if notPosDef > 0
    cholFactor = diag(sqrt(max(diag(covariance), 1e-9)));
end
draw = mu + cholFactor * randn(numel(mu), 1);
end

function [logContrast, info] = balancePoint(params, cfg)
logLevel = cfg.startLog(1);
% where the house/face and left/right logits are zero
balanceHouseFaceRaw = cfg.startLog(2) - params(1) / params(2);
balanceLeftRightRaw = cfg.startLog(3) - params(3) / params(4);
logHouseFace = min(max(balanceHouseFaceRaw, cfg.logMin(2)), cfg.logMax(2));
logLeftRight = min(max(balanceLeftRightRaw, cfg.logMin(3)), cfg.logMax(3));
info.clipped = (logHouseFace ~= balanceHouseFaceRaw) || (logLeftRight ~= balanceLeftRightRaw);
info.wanted  = [logHouseFace logLeftRight];

% keep all four textures inside cMin..cMax at this level:
% largest texture = exp(logLevel + (|logHouseFace|+|logLeftRight|)/2),
% smallest        = exp(logLevel - (|logHouseFace|+|logLeftRight|)/2)
roomUp   = log(cfg.cMax) - logLevel;
roomDown = logLevel - log(cfg.cMin);
room = max(min(roomUp, roomDown), 0);
need = (abs(logHouseFace) + abs(logLeftRight)) / 2;
info.needSum = 2 * need;  info.roomSum = 2 * room;
if roomUp <= roomDown, info.limit = 'cMax'; else, info.limit = 'cMin'; end
info.factor = 1;  info.shrunk = false;
if need > room + 1e-9
    factor = room / need;
    logHouseFace = logHouseFace * factor;  logLeftRight = logLeftRight * factor;
    info.factor = factor;  info.shrunk = true;
end
info.used = [logHouseFace logLeftRight];
logContrast = [logLevel logHouseFace logLeftRight];
end
