function frameDurations = makeExponentialDurations(totalDur, stimInterval, ...
                                                   frameDur, expPortion, expSlope)
% Returns a 1 x N vector of frame durations (seconds).
% First part: constant stimInterval.
% Last part: exponential shortening down to frameDur (one frame).

    % ----- Split into constant and exponential parts -----
    constDur   = totalDur * (1 - expPortion);
    constN     = max(0, floor(constDur / stimInterval));
    constUsed  = constN * stimInterval;   % actual constant time used
    expDur     = totalDur - constUsed;    % time remaining for exponential part

    % If almost no time left for exponential, just do constant
    if expDur <= frameDur * 1.5
        frameDurations = repmat(stimInterval, 1, max(1, round(totalDur / stimInterval)));
        return;
    end

    % ----- Choose number of exp frames -----
    % Rough heuristic: average between base and minimum
    avgGuess = 0.5 * (stimInterval + frameDur);
    expN     = max(2, round(expDur / avgGuess));  % at least 2 frames

    % ----- Build exponential shape -----
    % We start high (~stimInterval) and shrink toward frameDur.
    k   = 0:expN-1;            % frame index within exp part
    raw = exp(-expSlope * k);  % 1, e^{-λ}, e^{-2λ}, ...

    % Map raw exponential into [frameDur, stimInterval] BEFORE rescaling
    dExp = frameDur + (stimInterval - frameDur) * raw;   % decreasing

    % Now scale whole set so that the sum == expDur,
    % while enforcing that the last frame duration = frameDur.
    % 1) Temporarily fix last frame to frameDur
    dExp(end) = frameDur;

    % 2) Rescale the first expN-1 frames to fill the remaining expDur
    if expN > 1
        sumFirst   = sum(dExp(1:end-1));
        targetFirst = expDur - frameDur;  % leave room for last frame
        scale      = targetFirst / sumFirst;
        dExp(1:end-1) = dExp(1:end-1) * scale;
    end

    % Constant + exponential segments
    frameDurations = [repmat(stimInterval, 1, constN), dExp];

    % Final small tidy: if numerical errors make total time off by a ms or so,
    % you could correct here if you really care.
end
