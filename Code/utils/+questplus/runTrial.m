function [res, abort] = runTrial(ptb, design, qpSet, leftTex, rightTex)
% questplus.runTrial  One onset-rivalry trial of the QUEST+ calibration / test run.
%
%   [res, abort] = questplus.runTrial(ptb, design, qpSet, leftTex, rightTex)
%
% Sequence (durations from getQuestPlusSettings):
%   1. dynamic noise mask        qpSet.maskDuration      (2 s): the coarse Gaussian
%      noise of the main experiment's ITI (mean 128, SD 30, 4-px elements, new
%      image every 100 ms, independent per eye, inside the circular aperture),
%      made exactly as in trialProcedurePerImAtOffline:
%      generate.createStereoGaussianNoiseTextures + draw.stereo.textures for the
%      first frame, then display.stereo.gaussianNoise.
%   2. blank                     qpSet.blankDuration     (1 s, frame + fixation cross)
%   3. onset rivalry             qpSet.rivalryDuration   (3 s, leftTex -> left eye,
%                                                         rightTex -> right eye)
%   4. response screen           grey aperture + fixation cross until a response
%      (house / face / mixed), at most qpSet.responseDeadline s after rivalry
%      offset ([added 2026-11-10] 2 s, as maxReportTime in the main experiment;
%      Inf = wait as before). With qpSet.acceptResponsesDuringRivalry the
%      first key pressed from rivalry onset on counts (as in the main
%      experiment); the response screen then ends immediately.
%      No key by the deadline: res.response = 'mixed' and res.missed = true,
%      so the trial is put back into the block like a mixed response.
% No fixation dots (no-report part) are shown.
%
% res: response ('house'|'face'|'mixed'), missed (no key by the deadline), responseKey, rt (s from rivalry
% onset), respondedDuringRivalry, keySequence (all valid keys until the
% response / rivalry offset), ambiguous (more than one distinct key),
% maskOnset, blankOnset, rivalryOnset, rivalryOffset, responseTime.
% abort = true if the experimenter pressed ESCAPE.

res = struct();
abort = false;
houseKey = ptb.Keys.house;
faceKey  = ptb.Keys.face;
mixedKey = ptb.Keys.(qpSet.mixedKeyField);
validKeys = [houseKey, faceKey, mixedKey];
events = struct('Time', {}, 'Keycode', {});
KbEventFlush(ptb.Keyboard2);

%% 1. Noise mask (as the ITI in trialProcedurePerImAtOffline) ---------------
[leftNoise, rightNoise] = generate.createStereoGaussianNoiseTextures(ptb, design);
draw.stereo.textures(ptb, design, leftNoise, rightNoise);
maskOnset = Screen('Flip', ptb.window);
display.stereo.gaussianNoise(ptb, design, maskOnset, qpSet.maskDuration, leftNoise, rightNoise); % closes the textures
if escapePressed(ptb); abort = true; return; end

%% 2. Blank ----------------------------------------------------------------
draw.stereo.blanks(ptb, design);
blankOnset = Screen('Flip', ptb.window, maskOnset + qpSet.maskDuration - ptb.ifi / 2);

%% 3. Onset rivalry --------------------------------------------------------
draw.stereo.images(ptb, design, leftTex, rightTex);
rivalryOnset = Screen('Flip', ptb.window, blankOnset + qpSet.blankDuration - ptb.ifi / 2);
rivalryEnd = rivalryOnset + qpSet.rivalryDuration;
while GetSecs < rivalryEnd - 0.01
    events = input.updateKeyboardEvents(ptb.Keyboard2, events);
    if escapePressed(ptb); abort = true; return; end
    WaitSecs(0.001);
end

%% 4. Response screen (until response) ---------------------------------------
draw.stereo.blanks(ptb, design);
rivalryOffset = Screen('Flip', ptb.window, rivalryEnd - ptb.ifi / 2);
if qpSet.acceptResponsesDuringRivalry
    tFrom = rivalryOnset;
else
    tFrom = rivalryOffset;
end
deadline = Inf;
if isfield(qpSet, 'responseDeadline') && ~isempty(qpSet.responseDeadline)
    deadline = rivalryOffset + qpSet.responseDeadline;   % [added 2026-11-10]
end
missed = false;
while true
    events = input.updateKeyboardEvents(ptb.Keyboard2, events);
    [firstKey, firstTime] = firstValid(events, validKeys, tFrom);
    if ~isempty(firstKey); break; end
    if escapePressed(ptb); abort = true; return; end
    if GetSecs >= deadline
        missed = true; firstKey = 0; firstTime = NaN;   % no key in time
        break
    end
    WaitSecs(0.001);
end
res.missed = missed;

%% Bookkeeping -------------------------------------------------------------
if firstKey == houseKey
    res.response = 'house';
elseif firstKey == faceKey
    res.response = 'face';
else
    res.response = 'mixed';
end
res.responseKey = firstKey;
res.responseTime = firstTime;
res.rt = firstTime - rivalryOnset;
res.respondedDuringRivalry = ~missed && firstTime < rivalryOffset;
tUntil = max(firstTime, rivalryOffset);
if missed; tUntil = deadline; end
if ~isempty(events)
    t = [events.Time]; k = [events.Keycode];
    sel = t >= tFrom & t <= tUntil & ismember(k, validKeys);
    res.keySequence = k(sel);
else
    res.keySequence = firstKey;
end
res.ambiguous = numel(unique(res.keySequence)) > 1;
res.maskOnset = maskOnset;
res.blankOnset = blankOnset;
res.rivalryOnset = rivalryOnset;
res.rivalryOffset = rivalryOffset;
end


function [key, time] = firstValid(events, validKeys, tFrom)
key = []; time = [];
if isempty(events); return; end
t = [events.Time]; k = [events.Keycode];
sel = find(t >= tFrom & ismember(k, validKeys));
if isempty(sel); return; end
[time, i] = min(t(sel));
key = k(sel(i));
end


function tf = escapePressed(ptb)
% polls all keyboards directly (independent of the KbQueues, which may not
% contain ESCAPE when only one keyboard is used)
[down, ~, keyCode] = KbCheck(-1);
tf = down && keyCode(ptb.Keys.escape);
end
