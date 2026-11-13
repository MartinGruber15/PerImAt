function [out, s] = schedule(action, s, varargin)
% questplus.schedule  Balanced, shuffled order of the eye configurations.
%
%   s           = questplus.schedule('init', blockSize)
%   [houseEye,s]= questplus.schedule('next', s)
%   [~, s]      = questplus.schedule('requeue', s, houseEye)
%
% Each block contains blockSize/2 trials with house->left/face->right
% (houseEye = +1) and blockSize/2 trials with face->left/house->right
% (houseEye = -1) in random order. A trial with a 'mixed' response is put
% back into the remaining queue at a random position (not as the very next
% trial if avoidable), so that the house/face (valid) trials remain balanced
% between the two eye configurations.

switch lower(action)
    case 'init'
        blockSize = s;
        assert(mod(blockSize, 2) == 0 && blockSize >= 2, 'questplus:schedule', 'blockSize must be even.');
        out = struct('blockSize', blockSize, 'queue', zeros(1, 0), 'mixedSinceUpdate', zeros(0, 2));
        s = out;
    case 'next'
        if isempty(s.queue)
            block = repmat([1 -1], 1, s.blockSize / 2);
            s.queue = block(randperm(numel(block)));
        end
        out = s.queue(1);
        s.queue(1) = [];
    case 'requeue'
        houseEye = varargin{1};
        n = numel(s.queue);
        if n == 0
            pos = 1;
        else
            pos = 1 + randi(n);          % 2..n+1: not immediately repeated
        end
        s.queue = [s.queue(1:pos-1), houseEye, s.queue(pos:end)];
        out = [];
    otherwise
        error('questplus:schedule', 'Unknown action "%s".', action);
end
end
