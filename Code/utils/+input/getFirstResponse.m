function [resp, rt] = getFirstResponse(ptb, tStart, tEnd)
resp = NaN;
rt   = 0;

while GetSecs < tEnd
    [pressed, firstPress] = KbQueueCheck(ptb.Keyboard2);
    % Store only the first valid response
    if pressed && isnan(resp)
        valid = firstPress;
        valid(valid < tStart) = 0;
        if any(valid)
            tPress = min(valid(valid > 0));
            resp   = find(firstPress == tPress,1);
            rt     = tPress - tStart;
            %fprintf('Response recorded: %d (RT = %.3f s)\n', resp, rt);
        end
    end
    WaitSecs(0.001);   % reduces CPU load
end
if isnan(resp); resp=0;end
end