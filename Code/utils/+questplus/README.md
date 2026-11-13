# QUEST+ calibration of stimulus and eye balance

Before the main experiment, this procedure finds per subject the contrasts of the four rivalry textures
(**HouseL, FaceL, HouseR, FaceR**) at which, in a baseline without manipulation, the **first dominant percept**
in onset rivalry is house in 50 % and the left-eye image in 50 % of the trials. This leaves room in both
directions for the task manipulations. All settings: `Code/settings/getQuestPlusSettings.m`.

## Where it is used (options in `Code/main.m`)

| option | file | what it does |
|---|---|---|
| `QUEST+ calibration` | `Code/questPlusCalibration.m` | calibration + validation; at the end the contrasts are confirmed in the command window and saved as `<sub>_training_<n>.mat` (`input.adaptStimuli`) |
| `QUEST+ test` | `Code/questPlusTest.m` | 40 house/face trials of the same trial type at fixed contrasts: the textures `getVisualDesignSettings` built at start-up from the latest training file (default contrasts if there is none, i.e. a baseline before the first calibration) |
| `present fixDot locations` | `Code/presentFixDotLocations.m` | the fixation-dot positions, then 20 dual-task trials (`questPlusTest` in `'dual'` mode) |

`main` builds the textures from the latest training file at start-up, so every task after a calibration
(started with a new call of `main`) uses the new contrasts.

## Procedure (`questplus.verifyControl`)

1. **Calibration**: QUEST+ trials until the stop rule `verify.calibrationRule` is met, at least `minValidTrials`
   (80) house/face trials, at most `verify.maxCalibrationTrials` (150) trials incl. mixed.
   * `'sd'` (default): posterior SD of both balance points ≤ `verify.sdCriterion` (0.15 log2, i.e. the
     house/face contrast ratio of each eye configuration known to ±11 %).
   * `'balance'`: posterior SD of P(house) at the estimate ≤ `verify.preCriterion` (0.10) in both eye
     configurations, computed with the slope floor `stopSlopeFloor` (2.5).
2. **Break** (any key) + fusion alignment (`verify.fusionCheckAfterBreak`) + 3-s countdown.
3. **Validation**: `verify.validationValidTrials` (40) house/face trials at FIXED contrasts = the current
   posterior-mean estimate, 20 per eye configuration (mixed trials re-queued); counts printed after 20.
   Exact two-sided binomial tests against 0.5 of P(house) and of P(left-eye image first): passed if both
   p ≥ `verify.alpha` (0.05), i.e. 14–26 of 40 for both.
4. Passed → **verified**, the tested contrasts are proposed. Failed → another break and a validation at the
   updated estimate (up to `verify.maxValidations` = 2). Failed again → **NOT verified**, the estimate from all
   trials is proposed; the experimenter decides whether to save it.

**Experimenter decisions** (`verify.askExperimenter = true`, default since 2026-11-06): steps 2–4 are no longer
automatic. At the end of the calibration and after every validation the subject sees a break screen without key
instruction, and the command window shows (`questplus.askExperimenter`) the contrasts as they are entered in the
settings (house, face, left eye, right eye + the four texture contrasts) for the current estimate from all trials
and for every validation so far (with its result), plus the predicted P(house) and P(left eye first). Then:
`Enter` = suggested step (what the automatic procedure would do), `v` = (next) validation at the updated estimate
(posterior incl. the validation trials), `r` = (next) validation at exactly the contrasts of the previous validation
(stability check; only after a validation), `s` = stop (at most `verify.maxValidationsAsk` = 3 validations). After the run the experimenter chooses which of these
contrast sets to save (`questplus.chooseContrasts`; Enter = last passed validation, otherwise the estimate from all
trials), and `input.adaptStimuli` shows them once more (Enter keeps each value, Enter again saves).
Every trial line also shows the current best contrasts (posterior mean after that trial).

All trials (also the validation trials) update the posterior. `maxValidTrials` / `maxTotalTrials` still stop
the run. With `verify.enabled = false` there is no validation: the run stops on `stopRule` / `stopCriterion`
(`questplus.isFinished`: `'balance'`, `'sd'`, `'entropy'` or `'ntrials'`) and the estimate is proposed directly.

Duration: ~6.3 s per trial with the 3-s rivalry (5.3 s with 2 s). Typically ~14 min (calibration + one
validation); at most 150 calibration trials (~16 min) + two validations (~5 min each).

## Trial (`questplus.runTrial`)

| phase | duration | screen |
|---|---|---|
| mask | 2 s (`maskDuration`) | coarse Gaussian noise inside the circular aperture, as in the ITI of the main experiment (mean 128, SD 30, 4-px elements, new image every 100 ms, independent per eye) |
| blank | 1 s (`blankDuration`) | frame + fixation cross |
| onset rivalry | 3 s (`rivalryDuration`; 2 s before 2026-11-06) | house in one eye, face in the other, on pink noise as in the main experiment |
| response | until a key | grey aperture + fixation cross |

Keys: house / face (`getKeyAssignment`) and mixed (`ptb.Keys.accept`). The first key from rivalry onset counts
(`acceptResponsesDuringRivalry`); if it came during the rivalry, the next trial starts at rivalry offset.
No fixation dots.

## Contrast scheme

Texture contrast = stimulus factor × eye factor, as in `generate.getContrastAdjustedImages`. A trial shows one
house and one face texture; it is described by its **eye configuration** (houseEye = +1: HouseL+FaceR, −1:
FaceL+HouseR) and

```
x = log2(c_house / c_face)        house texture c0·2^(+x/2), face texture c0·2^(−x/2)
```

with c0 = `baseContrast` = √(0.4 · 2.2) = 0.938, so all textures stay within [0.4, 2.2] and x within ±2.4.
x takes multiples of `stepLog2` = 0.2. The calibration textures (`questplus.captureRawStimuli` +
`questplus.applyContrast`) are made exactly like the main-experiment textures. From the two balance points
uA (HouseL+FaceR) and uB (FaceL+HouseR) the saved factors are (`questplus.contrastsFromBalance`):

```
thetaS = (uA + uB)/2   thetaE = (uA − uB)/2
houseContrast = c0·2^(+thetaS/2)   faceContrast = c0·2^(−thetaS/2)
leftEyeContrast = 2^(+thetaE/2)    rightEyeContrast = 2^(−thetaE/2)
```

## Model (`questplus.model`)

```
P(house | x, houseEye) = λ/2 + (1−λ) / (1 + exp(−β · (x − θS − houseEye·θE)))
```

| parameter | meaning | grid |
|---|---|---|
| θS | log2 house/face ratio at which house and face are equally likely (> 0: face more dominant) | −2.5 … 2.5, step 0.05 |
| θE | log2 left/right-eye ratio at which both eyes are equally likely to win (> 0: right eye more dominant) | −2.5 … 2.5, step 0.05 |
| β | slope per log2 unit (nuisance) | 0.75 … 12, 9 values |
| λ | lapse rate, split 50:50 between house and face (nuisance) | 0.01, 0.03, 0.06, 0.12 |

The two eye configurations are two psychometric functions with a shared slope and balance points
uA = θS + θE and uB = θS − θE. Mixed responses are not modelled: they do not update the posterior.
A response bias towards one key is absorbed into θS (fine here: the goal is a balanced *reported* percept).

There is no term for trial-to-trial carry-over of the winning eye: in the pilot data it could not be told apart
from a drifting eye balance, and the goal is to match the eyes regardless of the origin. `questplus.carryover`
only reports runs of the same winning eye as a diagnostic.

## Trial choice

* **Eye configuration**: shuffled blocks of `blockSize` (4) trials, 2 × HouseL+FaceR and 2 × FaceL+HouseR; a
  mixed trial is put back into the current block (`questplus.schedule`).
* **Contrast ratio**: the x with the minimum expected entropy (Watson 2017, Eq. 4–7) of the posterior of the two
  balance points, marginalised over slope and lapse (psi-marginal, Prins 2013) (`questplus.selectStimulus`);
  ties are broken at random.
* `avoidRepeatAfterMixed`: until the next house/face response, stimuli that got "mixed" are excluded (the
  posterior is unchanged, so QUEST+ would otherwise repeat them).

## Priors (`qpSet.prior`)

Independent marginals: Gaussian on θS (centre `houseFaceRatio` 1.75, SD 0.75 log2) and θE (centre
`leftRightRatio` 1, SD 0.5), log-normal on β (median 3), flat on λ. The centres also set the first trials.
`centreOnUnverifiedRun` (on): after a NOT-verified run, the next run of the subject is centred on its estimate.

## Output (`rawdata/sub-XX/`)

* `sub-XX_questplus_<time>.mat`: `results` with settings, all trials (`phase` 'adaptive'/'verify',
  `validation`), posterior and prior (`results.qp`), estimates, ML refit, validations (`results.verification`),
  `verified`, stop reason, saved parameters.
* `sub-XX_questplus_<time>.csv`: one row per trial (eye configuration, x, texture contrasts, response, RT,
  running estimates, timing).
* `XX_training_<n>.mat`: `stimuliParameters` (house/face/left/right contrasts + `questPlus` summary), read by
  `loadLatestTrainingParameters`.
* `sub-XX_questplus-test[-dual]_<time>.mat/.csv`: test runs (counts per texture, P(house), P(left eye), CIs).

## Console and diagnostics

* Before the first trial: the plan (stop rule, limits, validation) and what the columns of the trial lines mean.
* Calibration trials: trial (house/face trials), eye configuration, x → response, θS/θE ± SD, SD of the balance
  points (SD of P(house) only with the `'balance'` rule). Validation trials: `V<k> n/40`, eye configuration,
  x → response, running counts of house and left-eye wins. Phase changes are marked with `===`.
* Warning if > 40 % of the last 20 trials were mixed (`mixedWarnRate`, `mixedWindow`).
* `questplus.carryover`: winning eye per trial, P(same eye as before), longest run of one eye; warns at
  ≥ 10 in a row (check head position / fusion).
* `questplus.fitML`: maximum-likelihood refit as a cross-check; `questplus.plotRun`: figure of the run.
* `questplus.stability`: the house/face trials are split into consecutive parts of ~30 trials, θS and θE are
  estimated from each part alone (slope/lapse fixed), and a χ² test asks whether the parts differ. A small p for
  θE (note at p < .05; expect this in ~1 of 20 runs by chance) means the eye balance changed during the run: the saved contrasts are then the average over
  the run. Diagnostic only, it changes nothing. Saved as `results.stability`.

## Dry run (testing without screen)

`Code/tests/dryRunCalibration.m` runs `questPlusCalibration` and `questPlusTest` end to end with a simulated
observer that follows the model above (θS, θE, slope, lapse, proportion mixed, optional drift of θE). Only the
screen/keyboard functions are replaced (`Code/tests/mocks`); trial choice, updates, stop rules, validation,
saving, the training file and the baseline test are the real code. Data go to a temporary folder. Works in
MATLAB and Octave (with the image package). See `Code/tests/README.md`.

```matlab
cd Code/tests
dryRunCalibration();                                            % one run, full console output
out = dryRunCalibration(struct('slope', 1.5, 'thetaEDrift', 0.003), 10);   % 10 runs, summary
```

## Pilot findings (sub-01)

* The eye balance drifted within runs (θE per quarter of run 1: −0.30, +1.21, +0.41, +0.30 log2). Pooled, this
  flattens the psychometric function (posterior slope ~1.1 instead of 2.5–4.8), which is why the slope floor of
  the `'balance'` rule and the 60-trial minimum exist.
* Separate slopes per eye configuration did not improve the fit.

## Files

| file | content |
|---|---|
| `verifyControl.m` | phase control: calibration → break → validation(s), binomial tests, stop |
| `isFinished.m` | stop rules without validation (`verify.enabled = false`) |
| `initialise.m`, `makeDomains.m` | stimulus domain, parameter grid, prior, likelihoods |
| `model.m`, `stimLikelihood.m` | psychometric function; likelihoods of the next trial |
| `schedule.m`, `chooseNextTrial.m`, `selectStimulus.m` | eye configuration, contrast ratio (minimum expected entropy) |
| `processResponse.m`, `update.m` | response → posterior update / re-queueing of mixed trials |
| `verifyNextTrial.m` | next validation trial |
| `estimates.m`, `contrastsFromBalance.m` | posterior summaries, recommended contrasts, predicted P(house) |
| `fitML.m`, `carryover.m`, `stability.m`, `textureCounts.m`, `binomialSummary.m` | ML refit, eye-run diagnostic, change over the run, counts, binomial test + Wilson CI |
| `captureRawStimuli.m`, `applyContrast.m`, `trialImages.m`, `makeRivalryTextures.m` | per-trial textures, made like the main-experiment textures |
| `presentTrial.m`, `runTrial.m` | one trial (mask, blank, rivalry, response) |
| `appendTrial.m`, `eyeConfigName.m`, `printSummary.m`, `plotRun.m` | trial log, console summary, figure |
| `instructionText.m`, `breakText.m`, `saveFusionOffsets.m` | instructions (EN/DE), break text, fusion offsets |

## References

* Watson, A. B. (2017). QUEST+: A general multidimensional Bayesian adaptive psychometric method. *Journal of
  Vision, 17*(3):10. https://doi.org/10.1167/17.3.10
* Jones, P. R. QuestPlus: a MATLAB implementation of QUEST+. https://github.com/petejonze/QuestPlus
* Prins, N. (2013). The psi-marginal adaptive method: How to give nuisance parameters the attention they
  deserve (no more, no less). *Journal of Vision, 13*(7):3.
