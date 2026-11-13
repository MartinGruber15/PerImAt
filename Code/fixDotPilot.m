function results = fixDotPilot(setUp, sub, opts)
% fixDotPilot  Pilot for the visibility of the no-report fixation dots. [added 2026-11-05]
%
%   fixDotPilot                       % set-up 'CIN-experimentroom', subject 'test'
%   fixDotPilot('CIN-experimentroom', 'test', struct('levels', [0.1 0.2 0.3 0.4 0.5], 'reps', 2))
%   fixDotPilot([], 'test', struct('bigDot', true, 'levels', [0.1 0.15 0.2 0.25 0.3]))   % big dot [added 2026-11-06]
%
% Uses the contrasts of the latest training file in rawdata/sub-<sub> (as the
% experiment does) and builds the dot images with generate.getContrastAdjustedImages,
% so what you see is exactly what the experiment would show with these settings.
% Run it from Code/ (as main.m). Nothing is changed in the settings files: put
% the values you settle on into getVisualDesignSettings.m.
%
% PART 1 - viewer (experimenter keyboard; the settings are printed in the command window)
%   t      next texture: houseL, faceL, houseR, faceR (view 3: next texture pairing)
%   p      next dot position 1-6 (view 3: next valid house/face position pair)
%   a      all 6 positions at once
%   v      view: 1 texture in both eyes | 2 texture in its own eye only |
%                3 rivalry pair as in a trial (house + face, one dot each)
%   m      mode 'local' <-> 'texture'
%   w / s  Weber value + / - 0.05 ('local'; below 0 = dark dot); e = texture-scaled Weber ([])
%   g / h  clutter gain + / - 0.5 ('local')
%   k / j  luminance exponent + / - 0.25 ('local'; 1 = same step / local mean,
%          0 = same step in grey levels at every spot)
%   r      redraw (new pink noise)
%   f      play one rivalry trial (current house/face pair and dots, as view 3):
%          fixation cross 1 s, rivalry 3 s, cross again
%   d      detection test (part 2) with the current mode, gain and view 1 or 2
%   ESC    end
%
% PART 2 - detection test (subject keyboard): per trial the fixation cross for
%   opts.fixDuration s, then ONE texture for opts.duration s (view 1: in both eyes,
%   view 2: in its own eye) with or without a dot, then the cross until the
%   answer: left key = dot seen, right key = no dot. The subject looks at the
%   cross. Trials: 4 textures x 6 positions x Weber levels (opts.levels; mode
%   'texture': only its own contrast) x opts.reps, plus opts.pNoDot no-dot
%   trials, in random order. Saved as rawdata/sub-<sub>/sub-<sub>_fixDotPilot_<time>.csv
%   and .mat; hit rates per texture x level and per texture x position printed.
%   Equal visibility = similar hit rates over textures and positions at the
%   same level; raise the clutter gain if the house (busier) needs higher levels.

if nargin < 1 || isempty(setUp); setUp = 'CIN-experimentroom'; end
if nargin < 2 || isempty(sub); sub = 'test'; end
if nargin < 3; opts = struct(); end
opts = setDefault(opts, 'levels', [0.1 0.2 0.3 0.4 0.5]);   % Weber values tested ('local')
opts = setDefault(opts, 'reps', 2);                          % trials per texture x position x level
opts = setDefault(opts, 'pNoDot', 0.25);                     % no-dot trials (fraction of all trials)
opts = setDefault(opts, 'duration', 2);                      % s, as the rivalry images in the experiment
opts = setDefault(opts, 'fixDuration', 1);                   % s fixation cross before each image
opts = setDefault(opts, 'mode', 'local');                    % start mode of the viewer
opts = setDefault(opts, 'bigDot', []);                       % [added 2026-11-06] [] = getVisualDesignSettings default; true/false
addpath('utils'); addpath('settings');
sca;
ptb = DataContainer(); design = DataContainer(); myPaths = DataContainer();
results = [];
cleanupObj = onCleanup(@() closeScreen()); %#ok<NASGU>

ptb = getPTBSettings(ptb, setUp, false, false);
myPaths = getPaths(myPaths, sub);
assert(isfolder(myPaths.subjectDirectory), 'No folder %s.', myPaths.subjectDirectory);
if ~isempty(opts.bigDot); design.fixDotBig = logical(opts.bigDot); end   % [added 2026-11-06]
design = getVisualDesignSettings(ptb, myPaths, design);
% [added 2026-11-06] rivalry duration of the 'f' trial (was never set here; perImAtOffline sets it
% only for the main experiment)
design.stimulusPresentationTime = 3 - ptb.ifi/2;
fprintf('Fixation dot: %s (sigma %.3f deg, local Weber %.2f)\n', bigStr(design.fixDotBig), ...
    design.fixDotSigmaInDegrees, design.fixDotLocalWeber);
gammaCleanup = gamma_correct.apply(ptb.window, myPaths.monCalDirPath); %#ok<NASGU>
participantInfo = struct('language', 'german');
if isfile(fullfile(myPaths.subjectDirectory, 'participantInfo.mat'))
    P = load(fullfile(myPaths.subjectDirectory, 'participantInfo.mat')); participantInfo = P.participantInfo;
end
participantInfo = display.stereo.alignFusion(ptb, participantInfo);

texNames = {'houseL', 'faceL', 'houseR', 'faceR'};
k = struct('t', KbName('t'), 'p', KbName('p'), 'a', KbName('a'), 'v', KbName('v'), 'm', KbName('m'), ...
    'w', KbName('w'), 's', KbName('s'), 'e', KbName('e'), 'g', KbName('g'), 'h', KbName('h'), ...
    'r', KbName('r'), 'd', KbName('d'), 'k', KbName('k'), 'j', KbName('j'), 'f', KbName('f'), ...
    'esc', KbName('ESCAPE'));
st = struct('tex', 1, 'pos', 1, 'pair', 1, 'view', 1, 'mode', opts.mode, ...
    'weber', 0.39, 'gain', 0, 'lumExp', 1);
if design.hasField('fixDotLocalWeber'); st.weber = design.fixDotLocalWeber; end
if design.hasField('fixDotLocalMaskGain'); st.gain = design.fixDotLocalMaskGain; end
if design.hasField('fixDotLocalLumExponent'); st.lumExp = design.fixDotLocalLumExponent; end
rebuild(st);
viewNames = {'both eyes', 'own eye', 'rivalry pair'};

%% PART 1: viewer ------------------------------------------------------------
while true
    showView(st);
    [~, keyCode] = KbStrokeWait(-1);
    changed = false;
    if keyCode(k.esc); break
    elseif keyCode(k.t); st.tex = mod(st.tex, 4) + 1;
    elseif keyCode(k.p)
        if st.view == 3; st.pair = mod(st.pair, size(design.fixDotValidPairs, 1)) + 1;
        else; st.pos = mod(max(st.pos, 1), 6) + 1; end
    elseif keyCode(k.a); st.pos = 0;
    elseif keyCode(k.v); st.view = mod(st.view, 3) + 1;
    elseif keyCode(k.m)
        if strcmp(st.mode, 'local'); st.mode = 'texture'; else; st.mode = 'local'; end; changed = true;
    elseif keyCode(k.w); st.weber = round((wOr(st.weber) + 0.05) * 100) / 100;   % [changed 2026-11-06] negative = dark dot changed = true;
    elseif keyCode(k.s); st.weber = round((wOr(st.weber) - 0.05) * 100) / 100; changed = true;
    elseif keyCode(k.e); st.weber = []; changed = true;
    elseif keyCode(k.g); st.gain = st.gain + 0.5; changed = true;
    elseif keyCode(k.h); st.gain = max(0, st.gain - 0.5); changed = true;
    elseif keyCode(k.k); st.lumExp = st.lumExp + 0.25; changed = true;
    elseif keyCode(k.j); st.lumExp = st.lumExp - 0.25; changed = true;
    elseif keyCode(k.f); playTrial(st);
    elseif keyCode(k.d)
        results = detectionTest(st);
        rebuild(st);   % the test rebuilt the images per level
    end
    if changed; rebuild(st); end
end
fprintf(['\nLast settings: mode ''%s'', Weber %s, gain %.1f, luminance exponent %.2f ' ...
    '-> put them into getVisualDesignSettings.m if you keep them.\n'], ...
    st.mode, wStr(st.weber), st.gain, st.lumExp);


%% nested functions -------------------------------------------------------------
    function rebuild(s)
        % dot images for mode / Weber / gain s (all textures, positions, pairs)
        design.fixDotContrastMode = s.mode;
        design.fixDotLocalWeber = s.weber;
        design.fixDotLocalMaskGain = s.gain;
        design.fixDotLocalLumExponent = s.lumExp;
        design = generate.getContrastAdjustedImages(ptb, design, design.stimuliParameters, myPaths, ...
            design.fixDotTexture, design.fixDotTransparency);
    end

    function showView(s)
        if s.view == 3
            pairNames = {'houseL', 'faceR'; 'faceL', 'houseR'};   % left eye, right eye
            ip = 1 + any(strcmp(texNames{s.tex}, {'faceL', 'houseR'}));
            pr = design.fixDotValidPairs(s.pair, :);   % [left-eye position, right-eye position]
            imgL = design.images.(sprintf('%s_dot_%d', pairNames{ip, 1}, pr(1)));
            imgR = design.images.(sprintf('%s_dot_%d', pairNames{ip, 2}, pr(2)));
            what = sprintf('%s + %s, dots %d / %d', pairNames{ip, 1}, pairNames{ip, 2}, pr(1), pr(2));
        else
            name = texNames{s.tex};
            if s.pos == 0; img = allDots(name); else; img = design.images.(sprintf('%s_dot_%d', name, s.pos)); end
            [imgL, imgR] = eyeImages(name, img, s.view);
            what = sprintf('%s, position %s', name, posStr(s.pos));
        end
        present(imgL, imgR);
        fprintf('%-34s | view %-12s | mode %-7s | Weber %-6s | gain %.1f | lum. exp. %.2f%s\n', what, viewNames{s.view}, ...
            s.mode, wStr(s.weber), s.gain, s.lumExp, localLine(s));
    end

    function playTrial(s)
        % [added 2026-11-05] one rivalry trial as in no-report/dual: the house/face
        % pair of view 3 (t: other pairing, p: other dot positions), 2 s
        pairNames = {'houseL', 'faceR'; 'faceL', 'houseR'};
        ip = 1 + any(strcmp(texNames{s.tex}, {'faceL', 'houseR'}));
        pr = design.fixDotValidPairs(s.pair, :);
        baseL = design.images.(pairNames{ip, 1}); baseR = design.images.(pairNames{ip, 2});
        dotL = design.images.(sprintf('%s_dot_%d', pairNames{ip, 1}, pr(1)));
        dotR = design.images.(sprintf('%s_dot_%d', pairNames{ip, 2}, pr(2)));
        fprintf('Trial: %s + %s, dots %d / %d\n', pairNames{ip, 1}, pairNames{ip, 2}, pr(1), pr(2));
        draw.stereo.blanks(ptb, design);
        tFix = Screen('Flip', ptb.window);
        texL = makeTex(dotL); texR = makeTex(dotR);
        draw.stereo.images(ptb, design, texL, texR);
        tOn = Screen('Flip', ptb.window, tFix + 1);
        draw.stereo.blanks(ptb, design);
        Screen('Flip', ptb.window, tOn + design.stimulusPresentationTime);
        Screen('Close', [texL, texR]);
        WaitSecs(0.5);
    end

    function line = localLine(s)
        line = '';
        if strcmp(s.mode, 'local') && design.hasField('fixDotLocal') && s.view < 3
            info = design.fixDotLocal; r = find(strcmp(info.names, texNames{s.tex}));
            line = sprintf(' | step per position %s = %s of the local mean %s', mat2str(round(info.step(r, :))), ...
                mat2str(round(info.weber(r, :) * 100) / 100), mat2str(round(info.Lloc(r, :))));
        end
    end

    function [imgL, imgR] = eyeImages(name, img, view)
        % view 1: both eyes; view 2: the texture's own eye, uniform grey in the other
        grey = uint8(design.defaultLuminance * ones(size(img)));
        if view == 1; imgL = img; imgR = img;
        elseif name(end) == 'L'; imgL = img; imgR = grey;
        else; imgL = grey; imgR = img;
        end
    end

    function present(imgL, imgR)
        texL = makeTex(imgL); texR = makeTex(imgR);
        draw.stereo.images(ptb, design, texL, texR);
        Screen('Flip', ptb.window);
        Screen('Close', [texL, texR]);
    end

    function tex = makeTex(img)
        if all(img(:) == design.defaultLuminance)   % uniform grey: no pink noise (it would fill the whole image)
            tex = Screen('MakeTexture', ptb.window, img);
        else
            tex = generate.makePinkNoiseTex(ptb.window, img, [], design);
        end
    end

    function img = allDots(name)
        base = design.images.(name); img = base;
        for q = 1:6
            dq = design.images.(sprintf('%s_dot_%d', name, q));
            changedPx = repmat(any(dq ~= base, 3), [1 1 size(img, 3)]);
            img(changedPx) = dq(changedPx);
        end
    end

    function res = detectionTest(s)
        if s.view == 3; s.view = 1; end
        levels = opts.levels;
        if strcmp(s.mode, 'texture'); levels = NaN; end   % 'texture': the texture's own contrast only
        % images per level (only the four textures and their six single-dot images)
        cache = cell(1, numel(levels));
        for li = 1:numel(levels)
            s2 = s; if ~isnan(levels(li)); s2.weber = levels(li); end
            rebuild(s2);
            for ti = 1:4
                cache{li}.(texNames{ti}){1} = design.images.(texNames{ti});
                for q = 1:6; cache{li}.(texNames{ti}){q + 1} = design.images.(sprintf('%s_dot_%d', texNames{ti}, q)); end
            end
        end
        % trial list [texture, position (0 = no dot), level index]
        [tt, pp, ll] = ndgrid(1:4, 1:6, 1:numel(levels));
        dotTrials = repmat([tt(:), pp(:), ll(:)], opts.reps, 1);
        nNo = round(size(dotTrials, 1) * opts.pNoDot / (1 - opts.pNoDot));
        noTrials = [randi(4, nNo, 1), zeros(nNo, 1), randi(numel(levels), nNo, 1)];
        trials = [dotTrials; noTrials];
        trials = trials(randperm(size(trials, 1)), :);
        n = size(trials, 1);
        fprintf('\nDetection test: %d trials (%d without dot), mode ''%s'', gain %.1f, luminance exponent %.2f, view %s\n', ...
            n, nNo, s.mode, s.gain, s.lumExp, viewNames{s.view});
        if strcmpi(participantInfo.language, 'german')
            txt = ['Gleich siehst du nacheinander kurz ein Bild.\n' ...
                'Manchmal ist darauf ein kleiner Punkt.\n\n' ...
                'Schau die ganze Zeit auf das Kreuz in der Mitte.\n\n' ...
                'Punkt gesehen: linke Taste\nKein Punkt: rechte Taste\n\n' ...
                'Drücke eine beliebige Taste, um zu beginnen.'];
        else
            txt = ['You will briefly see one image after another.\n' ...
                'Sometimes there is a small dot on it.\n\n' ...
                'Look at the cross in the centre the whole time.\n\n' ...
                'Dot seen: left key\nNo dot: right key\n\n' ...
                'Press any key to start.'];
        end
        display.stereo.instruction(ptb, design, txt, 0.5, false);
        res = struct('trial', num2cell((1:n)'), 'texture', '', 'position', 0, 'weber', NaN, ...
            'gain', s.gain, 'lumExp', s.lumExp, 'mode', s.mode, 'sigmaDeg', design.fixDotSigmaInDegrees, 'view', viewNames{s.view}, 'seen', NaN, 'rt', NaN);
        aborted = false;
        for i = 1:n
            ti = trials(i, 1); q = trials(i, 2); li = trials(i, 3);
            img = cache{li}.(texNames{ti}){q + 1};
            [imgL, imgR] = eyeImages(texNames{ti}, img, s.view);
            texL = makeTex(imgL); texR = makeTex(imgR);
            draw.stereo.blanks(ptb, design);
            tFix = Screen('Flip', ptb.window);
            draw.stereo.images(ptb, design, texL, texR);
            tOn = Screen('Flip', ptb.window, tFix + opts.fixDuration);
            draw.stereo.blanks(ptb, design);
            tOff = Screen('Flip', ptb.window, tOn + opts.duration - ptb.ifi / 2);
            Screen('Close', [texL, texR]);
            seen = NaN;
            while isnan(seen)
                [tKey, keyCode] = KbStrokeWait(-1);
                if keyCode(ptb.Keys.left); seen = 1;
                elseif keyCode(ptb.Keys.right); seen = 0;
                elseif keyCode(k.esc); aborted = true; break
                end
            end
            if aborted; res = res(1:i - 1); break; end
            res(i).texture = texNames{ti}; res(i).position = q; res(i).seen = seen; res(i).rt = tKey - tOff;
            if ~isnan(levels(li)); res(i).weber = levels(li); end
        end
        if isempty(res); return; end
        stamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HHmmss'));
        base = fullfile(myPaths.subjectDirectory, ['sub-' sub '_fixDotPilot_' stamp]);
        writetable(struct2table(res), [base '.csv']);
        settings = struct('opts', opts, 'state', s, 'textureContrasts', design.textureContrasts); %#ok<NASGU>
        save([base '.mat'], 'res', 'settings');
        printSummary(res, levels);
        fprintf('Saved %s.csv / .mat\n', base);
    end
end


function printSummary(res, levels)
seen = [res.seen]; pos = [res.position]; w = [res.weber]; tex = {res.texture};
names = {'houseL', 'faceL', 'houseR', 'faceR'};
fprintf('\nFalse alarms (no dot, "seen"): %d / %d\n', sum(seen(pos == 0)), sum(pos == 0));
fprintf('Hit rate per texture (rows) and Weber level (columns %s):\n', mat2str(levels));
for ti = 1:4
    row = '';
    for li = 1:numel(levels)
        sel = strcmp(tex, names{ti}) & pos > 0 & (isequaln(levels(li), NaN) | w == levels(li));
        row = [row sprintf('  %4.2f (%d)', mean(seen(sel)), sum(sel))]; %#ok<AGROW>
    end
    fprintf('  %-7s%s\n', names{ti}, row);
end
fprintf('Hit rate per texture (rows) and position 1-6 (columns), all levels together:\n');
for ti = 1:4
    row = '';
    for q = 1:6
        sel = strcmp(tex, names{ti}) & pos == q;
        row = [row sprintf('  %4.2f', mean(seen(sel)))]; %#ok<AGROW>
    end
    fprintf('  %-7s%s\n', names{ti}, row);
end
end


function s = setDefault(s, f, v)
if ~isfield(s, f) || isempty(s.(f)); s.(f) = v; end
end

function str = bigStr(b)
if isequal(b, true); str = 'big dot'; else; str = 'small dot'; end
end

function v = wOr(w)
if isempty(w); v = 0.39; else; v = w; end
end

function str = wStr(w)
if isempty(w); str = 'c-scaled'; else; str = sprintf('%.2f', w); end
end

function str = posStr(p)
if p == 0; str = 'all'; else; str = num2str(p); end
end

function closeScreen()
ListenChar(0);
sca;
end
