function visible = visibleMask(design, nRows, nCols)
% generate.visibleMask  Pixels of a stimulus image that are visible through the frame. [added 2026-11-10]
%
%   visible = generate.visibleMask(design, nRows, nCols)
%
% For an nRows x nCols image drawn into design.destinationRect (as every
% rivalry texture is), true where the pixel centre lies inside the
% transparent circular aperture of the frame texture
% (generate.createOApertureXFrame: radius apertureDiameterInPixels/2 *
% (1 - frameThickness)) or outside the frame texture. Moved here from
% generate.makePinkNoiseTex (visibleThroughFrame), which now calls it, so
% that the pink-noise background, the contrast reference of the textures
% (generate.contrastReferenceMask) and createFMRIStimuli ('visible')
% use the same definition of "visible".
dst = design.destinationRect;      % where the stimulus image is drawn
frm = design.frameRect;            % where the frame texture is drawn
texW = design.frameSizeInPixelsX;  % frame texture size (texture pixels)
texH = design.frameSizeInPixelsY;

% Screen coordinates of the centres of the stimulus pixels
x = dst(1) + ((1:nCols) - 0.5) .* (dst(3) - dst(1)) ./ nCols;
y = dst(2) + ((1:nRows) - 0.5) .* (dst(4) - dst(2)) ./ nRows;
[X, Y] = meshgrid(x, y);

% ... expressed in (1-based) frame-texture pixel coordinates
u = (X - frm(1)) ./ ((frm(3) - frm(1)) / texW) + 0.5;
v = (Y - frm(2)) ./ ((frm(4) - frm(2)) / texH) + 0.5;

% Transparent aperture exactly as in generate.createOApertureXFrame
radiusInner = design.apertureDiameterInPixels / 2 * (1 - design.frameThickness);
inCircle    = hypot(u - (texW + 1) / 2, v - (texH + 1) / 2) < radiusInner;
insideFrame = u >= 0.5 & u <= texW + 0.5 & v >= 0.5 & v <= texH + 0.5;

visible = inCircle | ~insideFrame;   % outside the frame nothing covers it
end
