function texture = createFixDotTexture( ...
    ptb, frameSize, dotSize, frameColor, frameLineWidth, dotColor)

% RGB image
image = zeros(frameSize, frameSize, 3, 'uint8');
center = (frameSize + 1) / 2;

%% Frame
frameMask = false(frameSize, frameSize);

frameMask(1:frameLineWidth, :) = true;
frameMask(end-frameLineWidth+1:end, :) = true;
frameMask(:, 1:frameLineWidth) = true;
frameMask(:, end-frameLineWidth+1:end) = true;
frameColor255 = uint8(round(frameColor * 255));
for c = 1:3
    channel = image(:,:,c);
    channel(frameMask) = frameColor255(c);
    image(:,:,c) = channel;
end

%% Fixation dot
[X, Y] = meshgrid(1:frameSize, 1:frameSize);
dotMask = ...
    (X - center).^2 + ...
    (Y - center).^2 <= (dotSize/2)^2;

dotColor255 = uint8(round(dotColor));
for c = 1:3
    channel = image(:,:,c);
    channel(dotMask) = dotColor255(c);
    image(:,:,c) = channel;
end

%% Make everything outside the frame transparent
%
% We need an alpha channel so that the rectangular texture does not
% obscure the stimulus. The frame and dot themselves are opaque.
alpha = uint8((frameMask | dotMask) * 255);
image = cat(3, image, alpha);
%% Create PTB texture
texture = Screen('MakeTexture', ptb.window, image);

end
