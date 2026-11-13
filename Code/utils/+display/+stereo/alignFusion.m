function [participantInfo] = alignFusion(ptb, participantInfo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % alignFusion: Find the disparity that creates fusion in the subject
    %   Draw a frame with text on both sides of the screen
    %   The subject can move the frame in any direction until it is fused
    %   returns: the offset in x and y 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargin < 2
        participantInfo = struct;
    end
    
    % the ACCEPT key (ptb.Keys.accept) is called "lower key" in all instructions
    if isfield(participantInfo, 'language') && strcmp(participantInfo.language, 'german')
        FusionText = ['Drücke links und rechts,\n' ...
            'bis du nur einen Rahmen siehst.\n' ...
            'Dann drücke die untere Taste.'];
    else
        FusionText = ['Press left and right\n' ...
            'until you see one frame.\n' ...
            'Then press the lower key.'];
    end
    %ListenChar(2);
    
    % Check if horizontalOffset and verticalOffset are present in get
    if isfield(participantInfo, 'horizontalOffset') && isfield(participantInfo, 'verticalOffset')
        horizontalOffset = participantInfo.horizontalOffset;
        verticalOffset = participantInfo.verticalOffset;
    else
        horizontalOffset = 0;
        verticalOffset = 0;
    end

    % The key that ended the previous screen (e.g. the break text) may still be
    % held: wait until all keys are released (+ 0.2 s), otherwise the KbCheck
    % below sees the 'accept' key and ends the alignment immediately.
    KbReleaseWait(-1);
    WaitSecs(0.2);

    change = 0.003;
    framesize = max([ptb.screenXpixels, ptb.screenYpixels])/3; 

    SetStereoSideBySideParameters(ptb.window, [0+horizontalOffset, 0+verticalOffset], ...
        [1, 1], [1-horizontalOffset, 0-verticalOffset], [1, 1]);

    % variable that if true calls SetStereoSideBySideParameters
    updateStereo = false;
    while true
        if updateStereo
            SetStereoSideBySideParameters(ptb.window, [0+horizontalOffset, 0+verticalOffset], ...
                [1, 1], [1-horizontalOffset, 0-verticalOffset], [1, 1]);
            updateStereo = false;
        end

        % Select left-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', ptb.window, 0);
        Screen('FrameRect', ptb.window, ptb.FontColor, CenterRectOnPoint([0 0 framesize framesize], ptb.xCenter, ptb.yCenter), 10);

        DrawFormattedText(ptb.window, FusionText, 'center', 'center', ...
            ptb.FontColor, 20, [], [], [], [], CenterRectOnPoint([0 0 framesize framesize], ...
            ptb.xCenter, ptb.yCenter));

        % Select right-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', ptb.window, 1);
        Screen('FrameRect', ptb.window, ptb.FontColor, CenterRectOnPoint([0 0 framesize framesize], ...
            ptb.xCenter, ptb.yCenter), 10);

        DrawFormattedText(ptb.window, FusionText,'center', 'center', ...
            ptb.FontColor, 20, [], [], [], [], CenterRectOnPoint([0 0 framesize framesize], ...
            ptb.xCenter, ptb.yCenter)); % is this needed?

        % Tell PTB drawing is finished for this frame:
        Screen('DrawingFinished', ptb.window);

        Screen('Flip', ptb.window);

        [KeyIsDown, ~, keyCode, ~] = KbCheck;

        if KeyIsDown
            if keyCode(ptb.Keys.left)
                horizontalOffset = horizontalOffset-change;
                updateStereo = true;
            elseif keyCode(ptb.Keys.right)
                horizontalOffset = horizontalOffset+change;
                updateStereo = true;
            elseif keyCode(ptb.Keys.accept)
                break
            end
        end
    end

    participantInfo.horizontalOffset = horizontalOffset;
    participantInfo.verticalOffset = verticalOffset;

    %ListenChar(0);
end