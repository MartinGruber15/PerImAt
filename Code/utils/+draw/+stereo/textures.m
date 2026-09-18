function textures(ptb, design, leftTexture, rightTexture)
    % Select left-eye image buffer for drawing
    Screen('SelectStereoDrawBuffer', ptb.window, ptb.leftBuffer);
    Screen('DrawTexture', ptb.window, design.backGroundTexture);        % Image background
    Screen('DrawTexture', ptb.window, leftTexture, [], ...          % Draw the image
            design.destinationRect);
    % Grey frame + circular aperture + ring + corner Xs
    Screen('DrawTexture',ptb.window,design.frameTexture,[],design.frameRect);
    Screen('DrawLines',ptb.window,design.fixCrossCoords, ...
    design.fixCrossLineWidth,design.fixCrossColor,[design.centerX design.centerY]);
    if ptb.usedatapixx
        Screen('FillRect', ptb.window, [0, 0, 255], design.blueRectLeftOn);
        Screen('FillRect', ptb.window, [0, 0, 0], design.blueRectLeftOff);
    end
    
    % Select right-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, ptb.rightBuffer);
    Screen('DrawTexture', ptb.window, design.backGroundTexture);        % Image background
    Screen('DrawTexture', ptb.window, rightTexture, [], ...        % Draw the image
            design.destinationRect);
    % Grey frame + circular aperture + ring + corner Xs
    Screen('DrawTexture',ptb.window,design.frameTexture,[],design.frameRect);
    Screen('DrawLines',ptb.window,design.fixCrossCoords, ...
    design.fixCrossLineWidth,design.fixCrossColor,[design.centerX design.centerY]);
    if ptb.usedatapixx
        Screen('FillRect', ptb.window, [0, 0, 255], design.blueRectRightOn);
        Screen('FillRect', ptb.window, [0, 0, 0], design.blueRectRightOff);
    end
    % Tell PTB drawing is finished for this frame:       
    Screen('DrawingFinished', ptb.window);
end