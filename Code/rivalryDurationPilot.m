function results = rivalryDurationPilot(setUp, sub, opts)
% rivalryDurationPilot  How long must the rivalry last until ONE fixation dot is clearly seen? [added 2026-11-06]
%
%   rivalryDurationPilot                          % set-up 'CIN-experimentroom', subject 'test'
%   rivalryDurationPilot('CIN-experimentroom', 'test', struct('nTrials', 60, 'taskDuration', 6))
%   rivalryDurationPilot([], 'test', struct('task', 'image'))   % same, but report the image (no dots)
%   rivalryDurationPilot([], 'test', struct('bigDot', true))    % big dot (getVisualDesignSettings) [added 2026-11-06]
%   rivalryDurationPilot([], 'test', struct('bigDot', true, 'weber', 0.2))   % big dot, other 'local' step
%
% Run it from Code/ (like main.m and fixDotPilot). Uses the contrasts of the
% latest training file in rawdata/sub-<sub> and the dot settings of
% getVisualDesignSettings.m, so the images are exactly those of the no-report /
% dual runs. Nothing in the settings files is changed.
%
% TRIAL (like a baseline trial of the main experiment, but the rivalry stays on
% until the subject answers):
%   cue 'x'             opts.cueDuration  (1 s)
%   task screen         opts.taskDuration (6 s, grey square as in baseline; 0 = skip)
%   rivalry + dots      until a key press (at most opts.maxRivalry s); one dot per eye at a
%                       valid house/face position pair (design.fixDotValidPairs), as in the
%                       no-report runs
%   blank               opts.blankDuration (0.5 s)
%   noise mask          opts.itiDuration (2 s, as the main experiment's mask/ITI)
%
% ANSWER (subject keyboard; house/face keys as in the experiment: odd or non-numeric
% subject = house left, even = house right):
%   opts.task = 'dot'   (default) "As soon as you clearly see ONE dot, look at it and press
%                       the key of the image it is on." Lower key = two dots / not sure.
%   opts.task = 'image' "Press the key of the image you clearly see." Lower key = mixed.
%                       No dots - for comparison with the image report.
%   ESC (experimenter keyboard) stops; the trials done so far are kept.
%
% OUTPUT: rawdata/sub-<sub>/sub-<sub>_rivalryDurationPilot_<task>_<time>.csv (written after
% every trial) and .mat (results, opts, settings). The command window prints the
% RT percentiles and, for each candidate rivalry duration (opts.candidates), the share
% of trials in which a dot was reported before that time. The RT includes the time to
% decide and press (about 0.3-0.5 s), so these shares are conservative; in the
% no-report runs the eyes also need time to land on the dot.

if nargin < 1 || isempty(setUp); setUp = 'CIN-experimentroom'; end
if nargin < 2 || isempty(sub); sub = 'test'; end
if nargin < 3 || isempty(opts); opts = struct(); end
opts = setDefault(opts, 'nTrials', 40);                         % half house left, half house right
opts = setDefault(opts, 'task', 'dot');                         % 'dot' | 'image'
opts = setDefault(opts, 'cueDuration', 1);                      % s, cue 'x'
opts = setDefault(opts, 'taskDuration', 6);                     % s, grey square (baseline task screen)
opts = setDefault(opts, 'maxRivalry', 10);                      % s, rivalry ends without answer after this
opts = setDefault(opts, 'blankDuration', 0.5);                  % s, cross after the answer
opts = setDefault(opts, 'itiDuration', 2);                      % s, noise mask
opts = setDefault(opts, 'bigDot', []);                          % [] = getVisualDesignSettings default; true/false overrides
opts = setDefault(opts, 'weber', []);                           % [] = from the settings; a number = 'local' Weber step
opts = setDefault(opts, 'candidates', [1.5 2 2.5 3 3.5 4 5]);   % s, rivalry durations to evaluate
opts = setDefault(opts, 'plot', true);
assert(any(strcmp(opts.task, {'dot', 'image'})), 'opts.task must be ''dot'' or ''image''.');
dotTask = strcmp(opts.task, 'dot');

addpath('utils'); addpath('settings');
sca;
ptb = DataContainer(); design = DataContainer(); myPaths = DataContainer();
results = [];
cleanupObj = onCleanup(@() closeScreen()); %#ok<NASGU>

%% Set-up (as fixDotPilot / main.m) ----------------------------------------------
ptb = getPTBSettings(ptb, setUp, false, false);
myPaths = getPaths(myPaths, sub);
assert(isfolder(myPaths.subjectDirectory), 'No folder %s.', myPaths.subjectDirectory);
if ~isempty(opts.bigDot); design.fixDotBig = logical(opts.bigDot); end   % [added 2026-11-06]
design = getVisualDesignSettings(ptb, myPaths, design);
if ~isempty(opts.weber)   % [added 2026-11-06] rebuild the dot images with another 'local' step
    assert(strcmp(design.fixDotContrastMode, 'local'), 'opts.weber needs fixDotContrastMode ''local''.');
    design.fixDotLocalWeber = opts.weber;
    design = generate.getContrastAdjustedImages(ptb, design, design.stimuliParameters, myPaths, ...
        design.fixDotTexture, design.fixDotTransparency);
end
isBig = design.hasField('fixDotBig') && isequal(design.fixDotBig, true);
dotSigma = design.fixDotSigmaInDegrees; dotWeber = NaN; dotMode = design.fixDotContrastMode;
if strcmp(dotMode, 'local'); dotWeber = design.fixDotLocalWeber; end
gammaCleanup = gamma_correct.apply(ptb.window, myPaths.monCalDirPath); %#ok<NASGU>
participantInfo = struct('language', 'german');
if isfile(fullfile(myPaths.subjectDirectory, 'participantInfo.mat'))
    P = load(fullfile(myPaths.subjectDirectory, 'participantInfo.mat')); participantInfo = P.participantInfo;
end
if ~isfield(participantInfo, 'language'); participantInfo.language = 'german'; end
participantInfo = display.stereo.alignFusion(ptb, participantInfo);

% keys as getKeyAssignment (which needs a numeric subject ID): even = house right
subNum = str2double(sub);
if ~isnan(subNum) && mod(subNum, 2) == 0
    houseKey = ptb.Keys.right; faceKey = ptb.Keys.left; houseSide = 'right';
else
    houseKey = ptb.Keys.left; faceKey = ptb.Keys.right; houseSide = 'left';
end
unclearKey = ptb.Keys.accept;
validKeys = [houseKey, faceKey, unclearKey];


%% Trial list ---------------------------------------------------------------------
nT = opts.nTrials;
houseLeft = [true(ceil(nT / 2), 1); false(floor(nT / 2), 1)];
houseLeft = houseLeft(randperm(nT));
pairIdx = randi(size(design.fixDotValidPairs, 1), nT, 1);

fprintf(['\nRivalry-duration pilot: %d trials, task ''%s'', house = %s key, cue %.1f s + task %.1f s, ' ...
    'rivalry until answer (max %.0f s)\n'], nT, opts.task, houseSide, opts.cueDuration, ...
    opts.taskDuration, opts.maxRivalry);
if dotTask
    fprintf('Fixation dot: %s, sigma %.3f deg, mode ''%s'', local Weber %.2f\n', bigName(isBig), dotSigma, dotMode, dotWeber);
end
fprintf('Texture contrasts: HouseL %.3f, FaceL %.3f, HouseR %.3f, FaceR %.3f\n', design.textureContrasts.HouseL, ...
    design.textureContrasts.FaceL, design.textureContrasts.HouseR, design.textureContrasts.FaceR);

display.stereo.instruction(ptb, design, instructionText(participantInfo.language, opts.task, houseSide), 0.5, false);

stamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HHmmss'));
base = fullfile(myPaths.subjectDirectory, ['sub-' sub '_rivalryDurationPilot_' opts.task '_' stamp]);
res = struct('trial', {}, 'task', {}, 'eyeConfig', {}, 'leftEye', {}, 'rightEye', {}, 'leftImage', {}, ...
    'rightImage', {}, 'houseDotPos', {}, 'faceDotPos', {}, 'response', {}, 'responseEye', {}, 'responseKey', {}, ...
    'rt', {}, 'timeout', {}, 'bigDot', {}, 'dotSigmaDeg', {}, 'dotMode', {}, 'dotWeber', {}, 'cueOnset', {}, 'taskOnset', {}, 'rivalryOnset', {}, 'rivalryOffset', {}, 'maskOnset', {});

KbQueueStart(ptb.Keyboard2);
draw.stereo.blanks(ptb, design);
tNext = Screen('Flip', ptb.window) + 1;

%% Trials ---------------------------------------------------------------------------
for i = 1:nT
    % images (made before the cue, as in the experiment)
    if houseLeft(i)
        leftBase = 'houseL'; rightBase = 'faceR'; leftEye = 'house'; rightEye = 'face';
    else
        leftBase = 'faceL'; rightBase = 'houseR'; leftEye = 'face'; rightEye = 'house';
    end
    pr = design.fixDotValidPairs(pairIdx(i), :);        % [left-eye position, right-eye position]
    if dotTask
        leftName = sprintf('%s_dot_%d', leftBase, pr(1));
        rightName = sprintf('%s_dot_%d', rightBase, pr(2));
        if houseLeft(i); houseDot = pr(1); faceDot = pr(2); else; houseDot = pr(2); faceDot = pr(1); end
    else
        leftName = leftBase; rightName = rightBase; houseDot = NaN; faceDot = NaN;
    end
    texL = generate.makePinkNoiseTex(ptb.window, design.images.(leftName), design.masks.(leftName), design);
    texR = generate.makePinkNoiseTex(ptb.window, design.images.(rightName), design.masks.(rightName), design);

    % cue 'x' (baseline)
    KbEventFlush(ptb.Keyboard2);
    events = struct('Time', {}, 'Keycode', {});
    draw.stereo.fixCrossPlusText(ptb, design, 'x', ptb.FontColor);
    cueOnset = Screen('Flip', ptb.window, tNext);
    tEnd = cueOnset + opts.cueDuration - ptb.ifi / 2;
    % task screen (grey square, as in baseline)
    taskOnset = NaN;
    if opts.taskDuration > 0
        draw.stereo.images(ptb, design, design.stimuli.grey_square, design.stimuli.grey_square);
        taskOnset = Screen('Flip', ptb.window, tEnd);
        tEnd = taskOnset + opts.taskDuration - ptb.ifi / 2;
    end
    % rivalry until a key press
    draw.stereo.images(ptb, design, texL, texR);
    rivOnset = Screen('Flip', ptb.window, tEnd);
    key = []; tKey = NaN; aborted = false;
    while GetSecs < rivOnset + opts.maxRivalry
        events = input.updateKeyboardEvents(ptb.Keyboard2, events);
        [key, tKey] = firstValid(events, validKeys, rivOnset);
        if ~isempty(key); break; end
        if escapePressed(ptb); aborted = true; break; end
        WaitSecs(0.001);
    end
    draw.stereo.blanks(ptb, design);
    rivOffset = Screen('Flip', ptb.window);
    Screen('Close', [texL, texR]);
    if aborted
        fprintf('Stopped by the experimenter (ESC) in trial %d.\n', i);
        break
    end
    % noise mask
    [ln, rn] = generate.createStereoGaussianNoiseTextures(ptb, design);
    draw.stereo.textures(ptb, design, ln, rn);
    maskOnset = Screen('Flip', ptb.window, rivOffset + opts.blankDuration - ptb.ifi / 2);
    lastFlip = display.stereo.gaussianNoise(ptb, design, maskOnset, opts.itiDuration, ln, rn);
    draw.stereo.blanks(ptb, design);
    tNext = Screen('Flip', ptb.window, maskOnset + opts.itiDuration - ptb.ifi / 2) + 0.2;   % cross 0.2 s before the cue
    if lastFlip > tNext; tNext = lastFlip; end

    % bookkeeping
    if isempty(key)
        response = 'none'; respEye = ''; respKey = 0; rt = NaN;
    elseif key == houseKey
        response = 'house'; respKey = key; rt = tKey - rivOnset;
    elseif key == faceKey
        response = 'face'; respKey = key; rt = tKey - rivOnset;
    else
        response = 'unclear'; respEye = ''; respKey = key; rt = tKey - rivOnset;
    end
    if any(strcmp(response, {'house', 'face'}))
        if strcmp(response, leftEye); respEye = 'L'; else; respEye = 'R'; end
    end
    eyeConfig = 'FaceL_HouseR'; if houseLeft(i); eyeConfig = 'HouseL_FaceR'; end
    res(i) = struct('trial', i, 'task', opts.task, 'eyeConfig', eyeConfig, 'leftEye', leftEye, ...
        'rightEye', rightEye, 'leftImage', leftName, 'rightImage', rightName, 'houseDotPos', houseDot, ...
        'faceDotPos', faceDot, 'response', response, 'responseEye', respEye, 'responseKey', respKey, ...
        'rt', rt, 'timeout', isempty(key), ...
        'bigDot', isBig, 'dotSigmaDeg', dotSigma, 'dotMode', dotMode, 'dotWeber', dotWeber, ...
        'cueOnset', cueOnset, 'taskOnset', taskOnset, 'rivalryOnset', rivOnset, 'rivalryOffset', rivOffset, ...
        'maskOnset', maskOnset);
    dotStr = ''; if dotTask; dotStr = sprintf('  dots house %d / face %d', houseDot, faceDot); end
    fprintf('%3d/%d  %s%s -> %-7s %-1s  rt %5.2f s\n', i, nT, eyeConfig, dotStr, response, respEye, rt);
    writetable(struct2table(res, 'AsArray', true), [base '.csv']);   % after every trial (ESC / crash safe)
end

%% Save + summary ---------------------------------------------------------------------
if isempty(res); return; end
results = res;
settings = struct('opts', opts, 'setUp', setUp, 'houseKey', houseSide, ...
    'textureContrasts', design.textureContrasts, ...
    'fixDotContrastMode', dotMode, 'bigDot', isBig, 'dotSigmaDeg', dotSigma, 'dotWeber', dotWeber); %#ok<NASGU>
save([base '.mat'], 'res', 'settings');
display.stereo.instruction(ptb, design, endText(participantInfo.language), 0.5, true);
printSummary(res, opts);
fprintf('Saved %s.csv / .mat\n', base);
if opts.plot
    sca;
    plotSummary(res, opts, sub);
end
end


%% ---------------------------------------------------------------------------------------
function txt = instructionText(language, task, houseSide)
if strcmpi(language, 'german')
    if strcmp(houseSide, 'left'); L = 'Haus'; R = 'Gesicht'; else; L = 'Gesicht'; R = 'Haus'; end
    head = ['Gleich siehst du wieder das Kreuz, ein x und ein graues Feld.\n' ...
        'Dann kommen die Haus- und Gesichtsbilder.\n' ...
        'Sie bleiben, bis du eine Taste drückst.\n\n'];
    if strcmp(task, 'dot')
        body = ['Auf den Bildern ist ein kleiner Punkt.\n' ...
            'Sobald du EINEN Punkt deutlich siehst, schau ihn an\n' ...
            'und drücke die Taste für das Bild, auf dem er ist:\n\n' ...
            'Punkt auf dem ' L ': linke Taste\nPunkt auf dem ' R ': rechte Taste\n\n' ...
            'Siehst du zwei Punkte oder weißt du es nicht: untere Taste.\n\n'];
    else
        body = ['Drücke die Taste für das Bild, das du deutlich siehst:\n\n' ...
            L ': linke Taste\n' R ': rechte Taste\n\n' ...
            'Siehst du keines deutlich (nur eine Mischung): untere Taste.\n\n'];
    end
    txt = [head body 'Antworte, sobald du es weißt.\n\nDrücke eine beliebige Taste, um zu beginnen.'];
else
    if strcmp(houseSide, 'left'); L = 'house'; R = 'face'; else; L = 'face'; R = 'house'; end
    head = ['You will see the cross, an x and a grey square.\n' ...
        'Then the house and face images appear.\n' ...
        'They stay until you press a key.\n\n'];
    if strcmp(task, 'dot')
        body = ['There is a small dot on the images.\n' ...
            'As soon as you clearly see ONE dot, look at it\n' ...
            'and press the key for the image it is on:\n\n' ...
            'Dot on the ' L ': left key\nDot on the ' R ': right key\n\n' ...
            'Two dots, or you are not sure: lower key.\n\n'];
    else
        body = ['Press the key for the image you see clearly:\n\n' ...
            L ': left key\n' R ': right key\n\n' ...
            'Neither clearly (only a mixture): lower key.\n\n'];
    end
    txt = [head body 'Answer as soon as you know.\n\nPress any key to start.'];
end
end


function txt = endText(language)
if strcmpi(language, 'german'); txt = 'Fertig. Danke!'; else; txt = 'Done. Thank you!'; end
end


function printSummary(res, opts)
resp = {res.response}; rt = [res.rt]; eyeCfg = {res.eyeConfig};
n = numel(res);
isHF = strcmp(resp, 'house') | strcmp(resp, 'face');
nH = sum(strcmp(resp, 'house')); nF = sum(strcmp(resp, 'face'));
nU = sum(strcmp(resp, 'unclear')); nN = sum(strcmp(resp, 'none'));
nLeft = sum(strcmp({res.responseEye}, 'L'));
fprintf('\n=== Rivalry-duration pilot (%s): %d trials ===\n', opts.task, n);
if strcmp(opts.task, 'dot')
    fprintf('%s, sigma %.3f deg, mode ''%s'', Weber %.2f\n', bigName(res(1).bigDot), res(1).dotSigmaDeg, res(1).dotMode, res(1).dotWeber);
end
fprintf('house %d, face %d, unclear %d, no answer within %.0f s: %d\n', nH, nF, nU, opts.maxRivalry, nN);
if nH + nF > 0
    fprintf('P(house | house or face) = %.2f, P(left eye | house or face) = %.2f\n', nH / (nH + nF), nLeft / (nH + nF));
end
p = [25 50 75 80 90 95];
fprintf('RT from rivalry onset, house/face answers (n = %d):  ', sum(isHF));
fprintf('%d%%: %.2f s  ', [p; pct(rt(isHF), p)]);
fprintf('\n');
if any(strcmp(resp, 'unclear'))
    fprintf('RT of "unclear" answers: median %.2f s\n', median(rt(strcmp(resp, 'unclear'))));
end
fprintf('\nShare of ALL trials with a house/face answer before t (unclear and no answer count as not resolved):\n');
for d = opts.candidates
    all_ = mean(isHF & rt <= d);
    hl = strcmp(eyeCfg, 'HouseL_FaceR'); hr = ~hl;
    fprintf('  t = %.1f s: %3.0f %%   (HouseL/FaceR %3.0f %%, FaceL/HouseR %3.0f %%)\n', d, 100 * all_, ...
        100 * mean(isHF(hl) & rt(hl) <= d), 100 * mean(isHF(hr) & rt(hr) <= d));
end
fprintf(['Note: RT includes deciding and pressing (~0.3-0.5 s); the rivalry has to last at least this long ' ...
    'for the answer, and in the no-report runs the eyes must also reach the dot.\n']);
end


function plotSummary(res, opts, sub)
resp = {res.response}; rt = [res.rt];
isHF = strcmp(resp, 'house') | strcmp(resp, 'face');
figure('Name', 'Rivalry-duration pilot', 'Color', 'w');
t = linspace(0, max([opts.candidates, rt(isHF)]) + 0.5, 400);
hold on
plot(t, arrayfun(@(x) mean(isHF & rt <= x), t), 'k-', 'LineWidth', 2);
plot(t, arrayfun(@(x) mean(strcmp(resp, 'house') & rt <= x), t), '-', 'Color', [0.16 0.47 0.84], 'LineWidth', 1.5);
plot(t, arrayfun(@(x) mean(strcmp(resp, 'face') & rt <= x), t), '-', 'Color', [0.92 0.41 0.20], 'LineWidth', 1.5);
for d = opts.candidates
    plot([d d], [0 1], ':', 'Color', [0.6 0.6 0.6]);
end
hold off
ylim([0 1]); xlabel('time from rivalry onset (s)'); ylabel('share of trials answered');
legend({'house or face', 'house', 'face'}, 'Location', 'southeast');
title(sprintf('sub-%s, task ''%s'': answered by time t (n = %d)', sub, opts.task, numel(res)), 'Interpreter', 'none');
grid on
end


function q = pct(x, p)
% percentiles without the Statistics Toolbox (linear interpolation, like prctile)
x = sort(x(~isnan(x)));
q = nan(size(p));
if isempty(x); return; end
n = numel(x);
for j = 1:numel(p)
    pos = p(j) / 100 * n + 0.5;
    if pos <= 1; q(j) = x(1);
    elseif pos >= n; q(j) = x(n);
    else; lo = floor(pos); q(j) = x(lo) + (pos - lo) * (x(lo + 1) - x(lo));
    end
end
end


function [key, time] = firstValid(events, validKeys, tFrom)
key = []; time = NaN;
if isempty(events); return; end
t = [events.Time]; k = [events.Keycode];
sel = find(t >= tFrom & ismember(k, validKeys));
if isempty(sel); return; end
[time, i] = min(t(sel));
key = k(sel(i));
end


function tf = escapePressed(ptb)
% all keyboards (the subject KbQueue does not contain ESCAPE)
[down, ~, keyCode] = KbCheck(-1);
tf = down && keyCode(ptb.Keys.escape);
end


function str = bigName(b)
if b; str = 'big dot'; else; str = 'small dot'; end
end


function s = setDefault(s, f, v)
if ~isfield(s, f); s.(f) = v; end
end


function closeScreen()
ListenChar(0);
sca;
end
