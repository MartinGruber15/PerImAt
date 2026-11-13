function s = datetime(varargin)
% Octave stand-in for MATLAB datetime (tests only): returns the time stamp text.
s = datestr(now, 'yyyy-mm-dd_HHMMSS');
end
