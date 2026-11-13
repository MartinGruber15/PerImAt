function out = dryRunCalibration(observer, nRuns, quiet)
% dryRunCalibration  End-to-end dry run of the QUEST+ calibration and the
% baseline test (questPlusTest) with a simulated observer - no screen,
% keyboard, eye tracker or Psychtoolbox needed.
%
%   dryRunCalibration()                        % default observer, 1 run, full console output
%   out = dryRunCalibration(observer)          % observer fields below (missing = default)
%   out = dryRunCalibration(observer, nRuns)   % repeat (console output suppressed),
%                                              % summary over the runs at the end
%   out = dryRunCalibration(observer, nRuns, quiet)
%
% observer (log2 units, see questplus.model):
%   thetaS 0.5   stimulus balance point (> 0: the face is the stronger stimulus)
%   thetaE -0.3  eye balance point (< 0: the left eye is the stronger eye); a number
%                or a function of the house/face trial number n, e.g.
%                @(n) -0.3 + 1.0*(n <= 15)  (strong right eye in the first 15 trials)
%   slope 3, lapse 0.03, pMixed 0.1 (probability of a 'mixed' response)
%   thetaEDrift 0   linear change of thetaE per house/face trial (log2)
%   rt 0.8       response time from rivalry onset (s; for the duration estimate)
%
% What runs: questPlusCalibration.m and questPlusTest.m (report mode) and
% everything they call, unchanged, from Code/. Only the functions that need
% the screen/keyboard are replaced by tests/mocks (put first on the path for
% the duration of the call and removed afterwards):
%   questplus.runTrial          -> the simulated observer answers (simObserver)
%   questplus.makeRivalryTextures, questplus.captureRawStimuli -> images instead
%                                  of textures, synthetic house/face images
%   questplus.plotRun, display.stereo.alignFusion/instruction -> nothing shown
%   input.adaptStimuli          -> saves the training file without asking
%   Screen, KbQueue*, KbEventFlush, KbReleaseWait, ListenChar, WaitSecs -> no-ops
%   (Octave only, tests/mocks_octave: datetime, string, struct2table, writetable)
% Everything else - trial choice, posterior update, stop rules, validation
% (binomial tests), saving of the results and of <sub>_training_<n>.mat,
% loading it again, the texture contrasts and the baseline test - is the real code.
% The data are written to a temporary folder, never to rawdata/.
%
% out(r): calibration/test results, true vs. saved balance points, the
% P(house) the observer has at the saved contrasts and the estimated
% duration (trials x (mask + blank + rivalry + rt), without instructions).
% With a changing eye balance, "true" is its MEAN over the calibration
% trials (what a stationary model estimates); uErrorEnd is the error
% relative to the value at the end of the calibration.
% NOT covered: anything drawn on the screen (PTB), key handling, eye
% tracker, the main experiment (perImAtOffline/Online), getVisualDesignSettings.

if nargin < 1 || isempty(observer); observer = struct(); end
if nargin < 2 || isempty(nRuns); nRuns = 1; end
if nargin < 3 || isempty(quiet); quiet = nRuns > 1; end
def = struct('thetaS', 0.5, 'thetaE', -0.3, 'slope', 3, 'lapse', 0.03, 'pMixed', 0.1, ...
    'thetaEDrift', 0, 'rt', 0.8);
fn = fieldnames(def);
for i = 1:numel(fn)
    if ~isfield(observer, fn{i}); observer.(fn{i}) = def.(fn{i}); end
end

%% Path: Code/ + mocks first (restored on exit) -------------------------------
testsDir = fileparts(mfilename('fullpath'));
codeDir  = fileparts(testsDir);
oldPath = path;
restorePath = onCleanup(@() path(oldPath)); %#ok<NASGU>
addpath(codeDir, fullfile(codeDir, 'utils'), fullfile(codeDir, 'settings'));
addpath(fullfile(testsDir, 'mocks'), '-begin');
if exist('OCTAVE_VERSION', 'builtin')
    addpath(fullfile(testsDir, 'mocks_octave'), '-begin');
    confirm_recursive_rmdir(false);   % rmdir(..., "s") without asking
end

%% Minimal ptb / design (only what the calibration and the test read) -----------
ptb = struct('window', 10, 'grey', 128, 'ifi', 1/60, 'windowRect', [0 0 1280 1440], ...
    'Keyboard1', 1, 'Keyboard2', 2);
ptb.Keys = struct('house', 80, 'face', 79, 'left', 80, 'right', 79, 'accept', 81, ...
    'up', 82, 'down', 81, 'escape', 41);
design = struct('waitTillStart', '', 'waitTillStartDuration', 0, 'RunIsOver', '', ...
    'perceptRule', '', 'fixDotRule', '', ...   % instruction parts (getInstructions), not shown here
    'defaultLuminance', 128, 'destinationRect', [0 0 125 124]);
qpSet = getQuestPlusSettings();
trialDur = qpSet.maskDuration + qpSet.blankDuration + qpSet.rivalryDuration + observer.rt;

out = struct([]);
for r = 1:nRuns
    subDir = tempname; mkdir(subDir);
    cleanDir = onCleanup(@() rmdir(subDir, 's'));
    myPaths = struct('subjectDirectory', subDir, 'stimuliLocation', '');
    logS = struct('sub', '99');
    pinfo = struct('language', 'english', 'horizontalOffset', 0, 'verticalOffset', 0);
    simObserver('reset', observer);

    % 1. QUEST+ calibration
    cal = []; %#ok<NASGU>
    runQuiet('[pinfo, cal] = questPlusCalibration(logS, ptb, design, myPaths, pinfo);', quiet);
    assert(numel(cal.trials) == cal.nTotal, 'trial log and trial count differ');
    assert(cal.nTotal <= qpSet.maxTotalTrials, 'more trials than qpSet.maxTotalTrials');
    assert(~isempty(dir(fullfile(subDir, '*_training_*.mat'))), 'no training file saved');

    % 2. texture contrasts as getVisualDesignSettings builds them from the training file
    sp = []; %#ok<NASGU>
    runQuiet('sp = loadLatestTrainingParameters(subDir);', quiet);
    tc = struct('HouseL', sp.houseContrast * sp.leftEyeContrast, 'FaceL', sp.faceContrast * sp.leftEyeContrast, ...
        'HouseR', sp.houseContrast * sp.rightEyeContrast, 'FaceR', sp.faceContrast * sp.rightEyeContrast);
    raw = simObserver('raw');
    d2 = design;
    d2.textureContrasts = tc;
    d2.images.houseL = questplus.applyContrast(raw.houseL, tc.HouseL, design.defaultLuminance);
    d2.images.faceL  = questplus.applyContrast(raw.faceL,  tc.FaceL,  design.defaultLuminance);
    d2.images.houseR = questplus.applyContrast(raw.houseR, tc.HouseR, design.defaultLuminance);
    d2.images.faceR  = questplus.applyContrast(raw.faceR,  tc.FaceR,  design.defaultLuminance);

    % 3. baseline test at these contrasts
    tst = []; %#ok<NASGU>
    runQuiet('[pinfo, tst] = questPlusTest(logS, ptb, d2, myPaths, pinfo, ''report'', struct(''skipFusion'', true));', quiet);
    nTest = numel(tst.trials);

    % 4. true vs. saved
    nCal = sum(~strcmp({cal.trials.response}, 'mixed'));      % house/face trials of the calibration
    tE = simObserver('thetaE', 1:nCal);
    thetaEMean = mean(tE);
    uTrue    = observer.thetaS + [1 -1] * thetaEMean;          % [HouseL+FaceR, FaceL+HouseR]
    uTrueEnd = observer.thetaS + [1 -1] * tE(end);
    uSaved = [log2(tc.HouseL / tc.FaceR), log2(tc.HouseR / tc.FaceL)];
    pAtSaved = [questplus.model(uSaved(1), 1, observer.thetaS, thetaEMean, observer.slope, observer.lapse), ...
                questplus.model(uSaved(2), -1, observer.thetaS, thetaEMean, observer.slope, observer.lapse)];
    o.nTotal = cal.nTotal; o.nValid = cal.nValid;
    o.verified = isfield(cal, 'verified') && cal.verified;
    o.stopReason = cal.stopReason;
    o.uTrue = uTrue; o.uSaved = uSaved; o.uError = uSaved - uTrue; o.uErrorEnd = uSaved - uTrueEnd;
    o.thetaEMean = thetaEMean; o.thetaEEnd = tE(end);
    o.pHouseAtSaved = pAtSaved;
    o.calMinutes = cal.nTotal * trialDur / 60;
    o.testTrials = nTest; o.testMinutes = nTest * trialDur / 60;
    o.testPHouse = tst.pHouse.p; o.testPLeftEye = tst.pLeftEyeWins.p;
    o.calibration = cal; o.test = tst;
    if isempty(out); out = o; else; out(r) = o; end %#ok<AGROW>
    clear cleanDir   % delete the temporary subject folder
    fprintf('run %d/%d: %d trials (%d valid), verified %d, saved-true balance point %+.3f / %+.3f log2, %.1f + %.1f min\n', ...
        r, nRuns, o.nTotal, o.nValid, o.verified, o.uError, o.calMinutes, o.testMinutes);
end

%% Summary -------------------------------------------------------------------
if isa(observer.thetaE, 'function_handle'); tEStr = func2str(observer.thetaE); else; tEStr = sprintf('%+.2f', observer.thetaE); end
fprintf('\n===== dry run: %d run(s), observer thetaS %+.2f thetaE %s slope %.1f lapse %.2f mixed %.2f drift %.3f =====\n', ...
    nRuns, observer.thetaS, tEStr, observer.slope, observer.lapse, observer.pMixed, observer.thetaEDrift);
err = abs(vertcat(out.uError));
fprintf('calibration trials: median %d [%d %d], duration median %.1f min (without instructions/breaks)\n', ...
    round(median([out.nTotal])), min([out.nTotal]), max([out.nTotal]), median([out.calMinutes]));
fprintf('verified: %d of %d runs\n', sum([out.verified]), nRuns);
fprintf('|saved - true balance point|: median %.3f, max %.3f log2 (true = mean over the calibration)\n', median(err(:)), max(err(:)));
eS = vertcat(out.uSaved); eS = (eS(:, 1) - eS(:, 2)) / 2;   % saved eye balance
fprintf('eye balance thetaE: saved median %+.3f | true mean over calibration %+.3f, at its end %+.3f (medians)\n', ...
    median(eS), median([out.thetaEMean]), median([out.thetaEEnd]));
pS = vertcat(out.pHouseAtSaved);
fprintf('P(house) of the observer at the saved contrasts: %.2f-%.2f\n', min(pS(:)), max(pS(:)));
fprintf('baseline test: %d trials, P(house) median %.2f, P(left eye first) median %.2f\n', ...
    out(1).testTrials, median([out.testPHouse]), median([out.testPLeftEye]));
fprintf('All steps ran through.\n');
end


function runQuiet(cmd, quiet)
% evaluate cmd in the caller's workspace, with or without console output
if quiet
    evalin('caller', ['evalc(''' strrep(cmd, '''', '''''') ''');']);
else
    evalin('caller', cmd);
end
end
