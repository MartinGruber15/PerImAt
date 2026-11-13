function qpSet = getQuestPlusSettings()
% getQuestPlusSettings  All settings of the QUEST+ calibration of the
% house/face and left/right-eye contrasts (questPlusCalibration.m) and of the
% test run (questPlusTest.m).
%
% Units: all "Log2" quantities are log2 contrast ratios, i.e. 1 = factor 2,
% 0.2 = factor 2^0.2 = 1.15 (15 %), 0.5 = factor 1.41.
%
% Procedure, model, trial choice and stop rules: Code/utils/+questplus/README.md.

%% ---------------------------------------------------------------------
%  Contrast space
%  ---------------------------------------------------------------------
% Texture contrast = (houseContrast or faceContrast) x (leftEyeContrast or
% rightEyeContrast), the multiplicative scheme of generate.getContrastAdjustedImages.
% In a trial the house texture gets baseContrast*2^(+x/2) and the face texture
% baseContrast*2^(-x/2), x = log2(c_house/c_face). With baseContrast =
% sqrt(min*max) the whole range is usable: 0.4 / 2.2 -> baseContrast 0.938,
% x up to +-2.4 log2 (ratio between the two textures up to 5.3x). Up to x2.2
% the RMS contrast still scales (a few % of the pixels clip); re-check after
% changing the stimuli.
qpSet.minTextureContrast  = 0.4;  % no texture (HouseL, FaceL, HouseR, FaceR) may go below ...
qpSet.maxTextureContrast  = 2.2;  % ... or above these values
qpSet.baseContrast        = sqrt(qpSet.minTextureContrast * qpSet.maxTextureContrast);   % 0.938; geometric mean of the four textures

% Grid of the tested contrast ratios: x takes multiples of stepLog2.
% 0.2 log2 = 15 % ratio between the two rivalling textures (each texture
% changes by 2^0.1 = 7 %). The final estimate (posterior mean) is not rounded
% to this grid.
qpSet.stepLog2            = 0.2;

%% ---------------------------------------------------------------------
%  Parameter domain (psychometric model, see questplus.model)
%  ---------------------------------------------------------------------
qpSet.thetaStepLog2   = 0.05;                     % grid step of both balance parameters
qpSet.thetaRangeLog2  = 2.5;                      % grid = -range:step:range (wider than the
                                                  % feasible +-2.4 so that "not reachable" is detectable)
qpSet.slopeValues     = 0.75 * 2.^((0:8)/2);      % logistic slope per log2 unit: 0.75 ... 12
qpSet.lapseValues     = [0.01 0.03 0.06 0.12];    % lapse rates (nuisance parameter)

%% ---------------------------------------------------------------------
%  Priors  (update these after piloting)
%  ---------------------------------------------------------------------
% houseFaceRatio: expected house/face contrast ratio at which house and face are
%   equally likely. >1 means the FACE is generally more dominant (the house
%   needs more contrast), <1 means the HOUSE is more dominant.
% leftRightRatio: expected left/right-eye contrast ratio at which both eyes
%   are equally likely to win. >1 means the RIGHT eye is generally dominant.
% The prior means also determine where the first trials are placed.
qpSet.prior.houseFaceRatio  = 1.75;
qpSet.prior.leftRightRatio  = 1;
qpSet.prior.sdStimLog2      = 0.75;  % SD of the Gaussian prior on log2(houseFaceRatio)
qpSet.prior.sdEyeLog2       = 0.5;   % SD of the Gaussian prior on log2(leftRightRatio)
qpSet.prior.slopeMedian     = 3;     % log-normal prior on the slope ...
qpSet.prior.slopeSdLn       = 1;     % ... (SD in natural-log units; 1 = broad)
qpSet.prior.lapseWeights    = [1 1 1 1] / 4;  % one weight per lapseValues entry
% true: centre the stimulus/eye priors on the subject's latest *_training_*.mat
qpSet.prior.centreOnLatestTraining = false;
% true: if this subject's latest calibration ended NOT verified, the next run
% centres the stimulus/eye priors on that run's estimate (SDs as above).
% Takes precedence over centreOnLatestTraining.
qpSet.prior.centreOnUnverifiedRun = true;

%% ---------------------------------------------------------------------
%  Trial choice
%  ---------------------------------------------------------------------
% Eye configuration: shuffled blocks of blockSize trials, half HouseL+FaceR,
% half FaceL+HouseR; a mixed trial is re-queued in the current block, so the
% house/face trials stay balanced (questplus.schedule).
qpSet.blockSize = 4;      % must be even
% Contrast ratio: QUEST+ (Watson 2017) chooses the x with the minimum expected
% entropy of the posterior of the two balance points, marginalised over slope
% and lapse (psi-marginal, Prins 2013; questplus.selectStimulus).
% Ties are broken at random.
% After a 'mixed' response the posterior does not change, so QUEST+ would
% propose the same stimulus again. true: until the next house/face response,
% stimuli that got 'mixed' are excluded and the next-best ratio is used.
qpSet.avoidRepeatAfterMixed = true;

%% ---------------------------------------------------------------------
%  Trial limits
%  ---------------------------------------------------------------------
qpSet.minValidTrials = 80;   % never end the calibration part before this many house/face responses
                             % (protects the 'sd' rule against an early, spuriously precise posterior)
qpSet.maxValidTrials = 270;  % always stop after this many house/face responses (150 calibration + 3 x 40 validation)
                             % [changed 2026-11-06] was 230 (2 validations); a 3rd validation is possible (verify.maxValidationsAsk)
qpSet.maxTotalTrials = 330;  % always stop after this many trials incl. mixed [changed 2026-11-06, was 280]

%% ---------------------------------------------------------------------
%  Calibrate -> validate   (questplus.verifyControl; default)
%  ---------------------------------------------------------------------
% 1. Calibration: QUEST+ trials until verify.calibrationRule is met (at least
%    minValidTrials house/face trials), or after verify.maxCalibrationTrials
%    trials incl. mixed (the current estimate is then validated anyway):
%      'sd'      : posterior SD of both balance points (HouseL+FaceR and
%                  FaceL+HouseR) <= verify.sdCriterion, in log2 units
%      'balance' : posterior SD of P(house) at the estimate <= verify.preCriterion
%                  in both eye configurations, computed with the slope floor
%                  stopSlopeFloor (below)
% 2. Short break (+ fusion check if fusionCheckAfterBreak), then the
%    validation: validationValidTrials house/face trials at FIXED contrasts =
%    the current estimate, eye configurations balanced. Exact two-sided
%    binomial tests against 0.5 of P(house) and of P(left-eye stimulus first);
%    40 trials, alpha 0.05: passed if 14-26 of 40 are house AND 14-26 of 40
%    are left-eye wins.
% 3. Passed -> "verified", the tested contrasts are proposed. Failed -> another
%    break and a validation at the updated estimate (up to maxValidations);
%    then "NOT verified", the estimate from all trials is proposed.
% All trials update the posterior. maxValidTrials / maxTotalTrials still apply.
% Simulations (simulated observer as in tests/dryRunCalibration; 4 runs per cell, 10 % mixed, ~5.3 s per trial; dev = max
% |P(house)-0.5| of the simulated observer at the saved contrasts; slope 5 / 3 / 1.5):
%   'sd' 0.15           : calibration 60 / 60-109 / 86-136 valid trials; total
%                         12 / 12 / 17 min; dev median 0.07 / 0.07 / 0.05 (max 0.16)
%   'balance' floor 2.5 : calibration 70 / 72-88 / 82-132 valid trials; total
%                         11 / 14 / 16 min; dev median 0.07 / 0.09 / 0.05 (max 0.20)
% A second validation adds ~4 min.
qpSet.verify.enabled                   = true;
qpSet.verify.calibrationRule           = 'sd';  % 'sd' | 'balance' (see above)
qpSet.verify.sdCriterion               = 0.15;  % 'sd': log2 units (0.15 = SD of ~11 % contrast ratio)
qpSet.verify.preCriterion              = 0.10;  % 'balance': SD of P(house) (with stopSlopeFloor)
qpSet.verify.maxCalibrationTrials      = 150;   % calibration part ends at the latest after this many trials incl. mixed
qpSet.verify.validationValidTrials     = 40;    % house/face trials per validation (20 per eye configuration)
qpSet.verify.alpha                     = 0.05;  % binomial tests (house, left eye): failed if p < alpha
qpSet.verify.maxValidations            = 2;     % 1 = no repetition after a failed validation
                                                % (with askExperimenter: up to here a failed validation SUGGESTS another one)
qpSet.verify.fusionCheckAfterBreak     = true;  % run alignFusion in the break before every validation
% [added 2026-11-06] The experimenter decides at the end of the calibration and after
% every validation (questplus.askExperimenter, command window): the current contrasts
% (house, face, left eye, right eye - the values of the settings / training file),
% those tested in each validation and the predicted P(house) / P(left eye first) are
% shown; Enter = the suggested step (what the automatic procedure would do),
% v = (next) validation at the updated estimate, r = (next) validation at the same
% contrasts as the previous validation (stability check), s = stop. After the run the
% experimenter chooses which contrasts to save (questplus.chooseContrasts) and confirms
% them with Enter (input.adaptStimuli). false = automatic as before.
qpSet.verify.askExperimenter           = true;
qpSet.verify.maxValidationsAsk         = 3;     % with askExperimenter: at most this many validations

%% ---------------------------------------------------------------------
%  Run WITHOUT validation (verify.enabled = false; questplus.isFinished)
%  ---------------------------------------------------------------------
% The run then stops as soon as stopRule is met (after minValidTrials), or at
% maxValidTrials / maxTotalTrials, and the estimate is proposed directly:
%  'balance' : posterior SD of P(house) at the estimate <= stopCriterion in both
%              eye configurations (with the slope floor stopSlopeFloor)
%  'sd'      : posterior SD of both balance points <= stopCriterion (log2)
%  'entropy' : entropy of the posterior of the two balance points <= stopCriterion (bits)
%  'ntrials' : only min/maxValidTrials
qpSet.stopRule      = 'balance';
qpSet.stopCriterion = 0.08;
% Slope floor of the 'balance' rules (verify.preCriterion and stopRule
% 'balance'), per log2 unit. The SD of P(house) at the estimate is roughly
% slope/4 x SD(balance point), so an underestimated slope lets the rule stop
% with imprecise contrasts (a drifting eye balance flattens the pooled
% psychometric function: sub-01 posterior slope ~1.1, 2.5-4.8 once the eye
% balance may change during the run). The SD of P(house) is computed with
% max(slope, stopSlopeFloor) for every grid point; predictions
% (est.final.pHouse) still use the posterior slope. 0 = no floor.
qpSet.stopSlopeFloor = 2.5;

%% ---------------------------------------------------------------------
%  Experimenter warnings
%  ---------------------------------------------------------------------
% warn if more than mixedWarnRate of the last mixedWindow trials were 'mixed'
qpSet.mixedWarnRate = 0.4;
qpSet.mixedWindow   = 20;

%% ---------------------------------------------------------------------
%  Trial timing (seconds)
%  ---------------------------------------------------------------------
% 1. mask: coarse Gaussian noise of the main experiment's ITI (mean 128, SD 30,
%    4-px elements, new image every 100 ms, independent per eye, inside the
%    circular aperture; questplus.runTrial)  2. blank (frame + fixation cross)
% 3. onset rivalry  4. grey screen until a response, at most qpSet.responseDeadline s
qpSet.maskDuration       = 2;
qpSet.blankDuration      = 1;
qpSet.rivalryDuration    = 3;   % [changed 2026-11-06] was 2 s; 3 s in all parts (calibration, validation, test, offline, online)
qpSet.responseDeadline   = 2;   % [added 2026-11-10] s after rivalry offset (as maxReportTime in the main
                                % experiment); no key by then = missed, put back like 'mixed'; Inf = no deadline
qpSet.acceptResponsesDuringRivalry = true;  % key presses from rivalry onset count;
                                            % false: only presses after rivalry offset
qpSet.instructionWaitDuration = 0.5;

%% ---------------------------------------------------------------------
%  Keys
%  ---------------------------------------------------------------------
% house/face keys come from getKeyAssignment (ptb.Keys.house / ptb.Keys.face).
% Field of ptb.Keys used for "mixed" (the key perImAtOffline maps to 'mixed').
qpSet.mixedKeyField = 'accept';

%% ---------------------------------------------------------------------
%  Test run with fixed contrasts (questPlusTest.m)
%  ---------------------------------------------------------------------
qpSet.test.nValidTrials   = 40;  % house/face responses (balanced between eye configurations)
qpSet.test.maxTotalTrials = 60;  % incl. mixed
qpSet.test.dualTrials     = 20;  % questPlusTest 'dual' mode: trials in total, incl. mixed
                                 % ([2026-11-04] no longer called by presentFixDotLocations,
                                 % which now runs perImAtOffline 'practice', 7 trials)

%% ---------------------------------------------------------------------
%  Misc
%  ---------------------------------------------------------------------
qpSet.showPlots = true;   % figure of the run at the end of the calibration
end
