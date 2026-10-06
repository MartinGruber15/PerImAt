function cfg = defaultSettings(x0, modelName, levelMode)
% defaultSettings  Search space and priors of the contrast optimisation.
%
%   cfg = contrastBO.defaultSettings(x0)               model 'shared'
%   cfg = contrastBO.defaultSettings(x0, 'perConfig')  model 'perConfig'
%   cfg = contrastBO.defaultSettings(x0, model, levelMode)  with a level rule, see below
%
% x0 = [g s e i] is the starting point (the contrasts of the last saved
% training file, see contrastsToParams).  The optimiser assumes balance is
% reached near x0 until the data say otherwise.
%
% Models
%   'shared'    : overall level g, house/face ratio s and left/right ratio e
%                 (3 parameters, i stays at its start value).  One mixed-
%                 percept curve over g for both stimulus configurations.
%   'perConfig' : the two stimulus configurations (pair A = house left + face
%                 right, pair B = house right + face left) each get their own
%                 balance curve, mixed-percept curve and contrast level, so
%                 all four textures can be set individually (4 parameters
%                 g s e i, see paramsToContrasts).  The shared model is the
%                 special case i = 0 / same mixed curve; the two models are
%                 linked by priors, see 'perConfig' priors below.

%
% Level rule (levelMode) = what decides the overall contrast level g
%   'mixed'   (default) the level is chosen where the model expects the fewest
%             mixed percepts (the pair levels in 'perConfig').
%   'balance' mixed percepts are ignored when choosing the level.  The level is
%             where the contrast DIFFERENCES needed for balance are smallest, so
%             it moves only because the balance model says that the level and the
%             balance interact (terms a3/b3 resp. l/dl) and because of the range.
%             In 'perConfig' the mixed term is also dropped for the differences.
%   'fixed'   the level stays at its starting value (g, and in 'perConfig' also
%             i: both pair levels); only the ratios (s, e and, with the pair
%             model, the pair differences) are adapted.  If the start level
%             leaves too little room, the ratios are shrunk to fit cMin..cMax.
if nargin < 2 || isempty(modelName), modelName = 'shared'; end
if nargin < 3 || isempty(levelMode), levelMode = 'mixed'; end
levelMode = lower(levelMode);
if ~ismember(levelMode, {'mixed', 'balance', 'fixed'})
    error('levelMode must be ''mixed'', ''balance'' or ''fixed''.');
end
x0 = x0(:)';
if numel(x0) == 3, x0(4) = 0; end
cfg.mode = modelName;
cfg.levelMode = levelMode;
% 'balance' rule: weight of the penalty on the size of the contrast difference (tie-break only)
cfg.diffWeight = 0.01;

%% Allowed range
cfg.cMin        = 0.25;      % no texture may get a contrast below this ...
cfg.cMax        = 1.5;       % ... or above this (above ~1.5 the uint8 image clips)
cfg.maxLogRatio = log(3);    % |ln(house/face)| and |ln(left/right)| limited to a factor of 3

cfg.lo = [log(cfg.cMin), -cfg.maxLogRatio, -cfg.maxLogRatio];   % [g s e]
cfg.hi = [log(cfg.cMax),  cfg.maxLogRatio,  cfg.maxLogRatio];
cfg.gMid  = (cfg.lo(1) + cfg.hi(1)) / 2;
cfg.gHalf = (cfg.hi(1) - cfg.lo(1)) / 2;

% starting point / centre of the balance model
cfg.i0     = x0(4);                                  % configuration term at the start
cfg.center = min(max(x0(1:3), cfg.lo), cfg.hi);
cfg.nParams = 3;

%% Priors (Gaussian, on logit scale)
% House-vs-face model, parameters [a0 a1 a3 b0 b1 b3]:
%   logit P(house) = a0 + a1*(s-s0) + a3*(g-g0)  +  t*( b0 + b1*(e-e0) + b3*(g-g0) )
%   t = +1 if the house is shown to the left eye, -1 if to the right eye.
%   a0: stimulus bias at the start contrasts (0 = house and face equal)
%   b0: eye bias        at the start contrasts (0 = left and right equal)
%   a1, b1: how strongly a contrast change moves the dominance (logit per ln-unit)
%   a3, b3: does the bias change with overall contrast level g?
cfg.stimPriorMean = [0 2 0   0 2 0];
cfg.stimPriorSD   = [1.5 1 0.7   1.5 1 0.7];
cfg.minSlope      = 0.3;     % slopes below this are not plausible (more contrast must help)

% Mixed-percept model: logit P(mixed) = m0 + m1*z + m2*z^2,  z = (g-gMid)/gHalf
cfg.mixPriorMean = [-1.5 0 0];
cfg.mixPriorSD   = [2 2 1.5];

%% Model 'perConfig'
if strcmpi(modelName, 'perConfig')
    cfg.nParams = 4;
    cfg.lo(4) = -(log(cfg.cMax) - log(cfg.cMin));    % i = ln(level A / level B)
    cfg.hi(4) =  (log(cfg.cMax) - log(cfg.cMin));
    cfg.center(4) = min(max(x0(4), cfg.lo(4)), cfg.hi(4));

    % level (ell) and house-face difference (d) of the two pairs at the start
    %   pair A: ell = g + i/2, d = s + e      pair B: ell = g - i/2, d = s - e
    cfg.ell0 = [cfg.center(1) + cfg.center(4)/2, cfg.center(1) - cfg.center(4)/2];
    cfg.d0   = [cfg.center(2) + cfg.center(3),   cfg.center(2) - cfg.center(3)];

    % What the optimiser minimises for each pair (see chooseParams):
    %   balanceWeight * (P(house | answered) - 0.5)^2  +  mixedWeight * P(mixed)
    % A small mixedWeight keeps balance the priority; the contrast LEVEL of a pair
    % does not cost any balance, so it is always used to reduce mixed percepts.
    cfg.balanceWeight = 1;
    cfg.mixedWeight   = 0.1;
    % The mixed model has many parameters and few mixed trials to learn them from, so a
    % full Thompson draw makes the tested levels scatter a lot.  The draw is therefore
    % shrunk towards the most probable mixed model (1 = full draw, 0 = no exploration).
    cfg.mixSampleScale = 0.5;

    % Balance model per pair c (A or B), parameters [aA aB k dk l dl]:
    %   logit P(house | answered) = a_c + (k +- dk)*(d - d0_c) + (l +- dl)*(ell - ell0_c)
    %   a_c: bias of pair c (0 = house and face equally likely at the start contrasts)
    %   k  : slope on the house-face difference d, shared by the pairs; dk: how much it
    %        differs between pairs (+ for A, - for B) -> partial pooling
    %   l, dl: effect of the pair's overall level, shared / pair-specific
    cfg.cfgBalPriorMean = [0 0   2 0     0 0];
    cfg.cfgBalPriorSD   = [1.5 1.5   1 0.5   0.7 0.5];

    % Mixed model per pair c, parameters [uA uB m1 m2 m3 dm3 m4]:
    %   logit P(mixed) = u_c + m1*z + m2*z^2 + (m3 +- dm3)*(d - d0_c) + m4*(d - d0_c)^2
    %   z = (ell - gMid)/gHalf.  m3 +- dm3: mixed percepts can depend on the
    %   house-face difference in a direction that differs per pair (e.g. the house
    %   turns into a 'mixed' percept only in pair A when it is too weak).
    cfg.cfgMixPriorMean = [-1.5 -1.5   0 0 0 0 0];
    cfg.cfgMixPriorSD   = [1.5 1.5   1.5 1 1 0.7 0.7];
end
end
