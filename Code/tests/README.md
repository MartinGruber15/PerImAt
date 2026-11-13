# tests

Dry runs of the experiment code without screen, keyboard, eye tracker or Psychtoolbox.

## dryRunCalibration.m

Runs the QUEST+ calibration (`questPlusCalibration.m`) and the baseline test (`questPlusTest.m`, report mode)
end to end with a simulated observer, then compares the saved contrasts with the observer's true balance points.

```matlab
cd Code/tests
dryRunCalibration();                         % default observer, one run, full console output
obs = struct('thetaS', 0.5, 'thetaE', -0.3, 'slope', 3, 'lapse', 0.03, 'pMixed', 0.1, 'thetaEDrift', 0);
out = dryRunCalibration(obs, 10);            % 10 runs, console output suppressed, summary at the end
```

The observer answers with the calibration model
P(house) = λ/2 + (1−λ)/(1+exp(−β(x − θS − h·θE))), where x = log2(c_house/c_face) is measured from the two images
that the real code built for the trial (so `trialImages`/`applyContrast` and the saved texture contrasts are
tested too). The eye balance can change: `thetaE` may be a function of the house/face trial number, e.g.
`@(n) -0.3 + 1.0*(n <= 15)` (strong right eye for the first 15 trials), and `thetaEDrift` adds a linear drift
(log2 per trial). With a changing eye balance, "true" in the summary is its mean over the calibration.

Results so far (Octave, slope 3, lapse 0.03, 10 % mixed):

| observer | calibration trials (median) | saved − true eye balance | baseline test: left eye first |
|---|---|---|---|
| stationary (24 runs) | 139 | −0.01 ± 0.08 log2 (θS +0.02 ± 0.08) | 51 % |
| right eye +1.0 for the first 15 trials (6) | 192 | +0.17 towards the burst | 60 % |
| right eye +1.5 for the first 30 trials (6) | 198 | +0.09 towards the burst | 64 % |
| sub-01-like θE per 30 trials (−0.3, +1.2, +0.4, +0.3) (6) | 196 | ≈ mean over the run | 55 % |
| linear drift 0.003/trial (6) | 161 | ≈ mean over the run, drift continues | 20 % |

Summary printed at the end: trials and estimated duration of the calibration (trials × (mask + blank + rivalry +
response time), without instructions/breaks), how many runs were verified, |saved − true balance point|, the
observer's P(house) at the saved contrasts, and the baseline-test P(house) / P(left eye first).

### What is replaced (`mocks/`, first on the path only during the call)

| mock | instead of |
|---|---|
| `+questplus/runTrial.m` + `simObserver.m` | mask/blank/rivalry/response on screen → simulated response |
| `+questplus/makeRivalryTextures.m` | PTB textures → the images themselves |
| `+questplus/captureRawStimuli.m` | house.png/face.png captured from screen → synthetic grating/rings |
| `+questplus/plotRun.m`, `+display/+stereo/alignFusion.m`, `instruction.m` | figure, fusion screen, instructions |
| `+input/adaptStimuli.m` | experimenter prompt → saves `<sub>_training_<n>.mat` with the proposed values |
| `Screen.m`, `KbQueueStart/Stop.m`, `KbEventFlush.m`, `KbReleaseWait.m`, `ListenChar.m`, `WaitSecs.m` | no-ops |
| `mocks_octave/` (Octave only) | `datetime`, `split`, `string`, `struct2table`, `writetable` |

### Not covered

Anything drawn on the screen, key handling and timing (`questplus.runTrial` itself), the eye tracker, the
main experiment (`perImAtOffline/Online`, `trialProcedure*`), `getVisualDesignSettings` and the stimulus files.
For those, run `main.m` with a test subject ID (e.g. `99`) on the experiment computer.

## 2026-11-06

- `mocks/simObserver.m` and the no-op mocks `KbQueueStart`, `KbQueueStop`, `ListenChar`, `WaitSecs`,
  `FlushEvents` were missing from the folder and were re-created (the dry run did not start without them).
- New mocks `+questplus/askExperimenter.m` (takes the suggested step) and `+questplus/chooseContrasts.m` (takes
  the default) for the experimenter decisions, so the dry run still runs without input.
- Octave only: inside package functions `input(...)` resolves to the package `+input` ("invalid meta.package
  indexing"); MATLAB is not affected. To try the real prompts in Octave, replace `input(` by
  `builtin('input', ` in a copy.
- Checked (Octave 8.4, 3-s rivalry): 1 run with full output, 6 runs (all verified, median |saved − true| 0.08 log2),
  the decision prompts with typed answers (continue after a passed validation, a 3rd validation offered, invalid
  input rejected, stop after the calibration, choice of a saved set), and the manual contrast entry.
