function c = split(s, delim)
% Octave stand-in for MATLAB split (tests only): char -> cell column.
c = strsplit(char(s), delim)';
end
