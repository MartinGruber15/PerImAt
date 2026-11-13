function c = string(x)
% Octave stand-in for MATLAB string (tests only): cell array of char.
if ischar(x); c = {x}; elseif iscell(x); c = x; else; c = arrayfun(@num2str, x, 'UniformOutput', false); end
end
