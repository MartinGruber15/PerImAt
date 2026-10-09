function cfg = defaultSettings(startLog)
% defaultSettings  Search space and priors of the contrast optimisation.
%
%   cfg = contrastBO.defaultSettings(startLog)
%
% startLog = [logLevel logHouseFace logLeftRight] is the starting
% point (the contrasts of the last saved training file, see contrastsToParams).
% The optimiser assumes balance is reached near it until the data say otherwise.
%
% The overall contrast level logLevel stays FIXED at its start value; only the
% two ratios are adapted:
%   logHouseFace = ln(house contrast / face contrast)
%   logLeftRight = ln(left-eye contrast / right-eye contrast)
% If the start level leaves too little room for the ratios, they are shrunk so
% that all four textures stay inside cMin..cMax (see chooseParams).
startLog = startLog(:)';

%% Allowed range
cfg.cMin        = 0.5;       % no texture may get a contrast below this ...
cfg.cMax        = 2;         % ... or above this (above ~1.5 the uint8 image clips)
cfg.maxLogRatio = log(5);    % |logHouseFace| and |logLeftRight| limited to a factor of 5

% Resolution of the contrasts.  The textures are 8-bit images: a contrast step
% much smaller than ~0.01 does not change a single grey level, so the four
% stored contrasts (house, face, left eye, right eye) are rounded to multiples
% of contrastStep and are never below one step (cMin can never be below it either).
cfg.contrastStep = 0.01;
cfg.cMin         = max(cfg.cMin, cfg.contrastStep);

% limits of [logLevel logHouseFace logLeftRight]
cfg.logMin = [log(cfg.cMin), -cfg.maxLogRatio, -cfg.maxLogRatio];
cfg.logMax = [log(cfg.cMax),  cfg.maxLogRatio,  cfg.maxLogRatio];

% starting point = centre of the balance model
cfg.startLog = min(max(startLog, cfg.logMin), cfg.logMax);   % [logLevel startHouseFace startLeftRight]

%% Priors (Gaussian, on the logit scale)
% House-vs-face model, parameters [stimBias stimSlope eyeBias eyeSlope]:
%   logit P(house) = stimBias + stimSlope*(logHouseFace - startHouseFace)
%                  + houseSide*( eyeBias + eyeSlope*(logLeftRight - startLeftRight) )
%   houseSide = +1 if the house is shown to the left eye, -1 if to the right eye.
%   stimBias: stimulus bias at the start contrasts (0 = house and face equal)
%   eyeBias : eye bias      at the start contrasts (0 = left and right equal)
%   stimSlope, eyeSlope: how strongly a contrast change moves the dominance
%                        (logit per ln-unit)
cfg.paramPriorMean = [0 2   0 2];
cfg.paramPriorSD   = [1.5 1   1.5 1];
cfg.minSlope       = 0.3;    % slopes below this are not plausible (more contrast must help)

% Mixed-percept rate: logit P(mixed) = mixedLogit  (one constant rate, because
% logLevel is fixed)
cfg.mixedPriorMean = -1.5;   % = 18 % before any data
cfg.mixedPriorSD   = 2;
end
