function out = simObserver(cmd, varargin)
% simObserver  Simulated observer of tests/dryRunCalibration (used by the mocks
% questplus.runTrial / questplus.captureRawStimuli). [re-created 2026-11-06: the
% file was missing from Code/tests]
%
%   simObserver('reset', observer)        % observer struct of dryRunCalibration, counter = 0
%   raw = simObserver('raw')              % synthetic house/face images (fields houseL faceL houseR faceR)
%   r   = simObserver('respond', L, R)    % 'house' | 'face' | 'mixed' for the two images on screen
%   obs = simObserver('get')              % the observer struct
%   tE  = simObserver('thetaE', n)        % eye balance at house/face trial(s) n
%
% The observer measures x = log2(c_house / c_face) from the two images (SD of
% the image / SD of the raw image, i.e. the contrast questplus.applyContrast
% applied), finds the eye of the house by correlation with the raw house image
% and answers with questplus.model (thetaS, thetaE(n), slope, lapse); a
% proportion pMixed of the trials is 'mixed' (not counted in n).
persistent obs n raw
switch cmd
    case 'reset'
        obs = varargin{1}; n = 0;
        raw = makeRaw();
        out = [];
    case 'raw'
        if isempty(raw); raw = makeRaw(); end
        out = raw;
    case 'get'
        out = obs;
    case 'thetaE'
        out = arrayfun(@(k) thetaEAt(obs, k), varargin{1});
    case 'respond'
        L = double(varargin{1}(:,:,1)); R = double(varargin{2}(:,:,1));
        h = double(raw.houseL(:,:,1)); f = double(raw.faceL(:,:,1));
        if corrOf(L, h) >= corrOf(R, h)
            houseEye = 1; cH = std(L(:)) / std(h(:)); cF = std(R(:)) / std(f(:));
        else
            houseEye = -1; cH = std(R(:)) / std(h(:)); cF = std(L(:)) / std(f(:));
        end
        x = log2(cH / cF);
        if rand < obs.pMixed
            out = 'mixed'; return
        end
        n = n + 1;
        p = questplus.model(x, houseEye, obs.thetaS, thetaEAt(obs, n), obs.slope, obs.lapse);
        if rand < p; out = 'house'; else; out = 'face'; end
    otherwise
        error('simObserver: unknown command %s', cmd);
end
end


function t = thetaEAt(obs, k)
if isa(obs.thetaE, 'function_handle'); t = obs.thetaE(k); else; t = obs.thetaE; end
t = t + obs.thetaEDrift * k;
end


function raw = makeRaw()
% two different random patterns (SD 15 around 128: no clipping up to contrast 2.2)
sz = [124 125];
hImg = 128 + 15 * zscore2(conv2(randn(sz + 8), ones(5) / 25, 'valid'), sz);
fImg = 128 + 15 * zscore2(conv2(randn(sz + 8), ones(3) / 9, 'valid'), sz);
hImg = uint8(round(repmat(hImg, [1 1 3])));
fImg = uint8(round(repmat(fImg, [1 1 3])));
raw = struct('houseL', hImg, 'houseR', hImg, 'faceL', fImg, 'faceR', fImg);
end


function z = zscore2(a, sz)
a = a(1:sz(1), 1:sz(2));
z = (a - mean(a(:))) / std(a(:));
end


function c = corrOf(a, b)
a = a(:) - mean(a(:)); b = b(:) - mean(b(:));
c = (a' * b) / sqrt((a' * a) * (b' * b) + eps);
end
