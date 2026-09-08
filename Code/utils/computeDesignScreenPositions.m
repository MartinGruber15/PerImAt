function design = computeDesignScreenPositions(ptb, design)
% computeDesignScreenPositions
%
% Computes all screen-related design parameters from the visual-angle
% definitions stored in design and the display properties stored in ptb.
%
% INPUTS
%   ptb     - PTB/display parameters, including:
%             .PixPerDegWidth
%             .PixPerDegHeight
%             .centerX
%             .centerY
%
%   design  - Design structure containing visual-angle definitions:
%             .stimSizeInDegrees
%             .fusionMaskInDegrees
%             .fixCrossInDegrees
%             .fixDotSizeInDegrees
%
% OUTPUT
%   design  - Design structure with all corresponding pixel values,
%             positions, and rectangles added.
%% Screen center
design.centerX = ptb.centerX;
design.centerY = ptb.centerY;

%% Convert visual degrees to pixels
% Stimulus size
design.stimSizeInPixelsX = round(ptb.PixPerDegWidth * design.stimSizeInDegrees);
design.stimSizeInPixelsY = round(ptb.PixPerDegHeight * design.stimSizeInDegrees);
% Fusion mask size
design.fusionMaskInPixelsX = round(ptb.PixPerDegWidth * design.fusionMaskInDegrees);
design.fusionMaskInPixelsY = round(ptb.PixPerDegHeight * design.fusionMaskInDegrees);
% Fixation cross size
design.fixCrossInPixelsX = round(ptb.PixPerDegWidth * design.fixCrossInDegrees);
design.fixCrossInPixelsY = round(ptb.PixPerDegHeight * design.fixCrossInDegrees);
% Fixation dot(s) size
design.fixDotSizeInPixels = round(ptb.PixPerDegWidth * design.fixDotSizeInDegrees);

%% Fixation cross
% Fixation cross coordinates relative to its center
design.fixCrossCoords = [
    -design.fixCrossInPixelsX/2 design.fixCrossInPixelsX/2 0 0; ...
    0 0 -design.fixCrossInPixelsY/2 design.fixCrossInPixelsY/2];

%% Fixation dots
% Distance of fixation dots from the center
design.fixDotDistanceInPixels = min( ...
    design.stimSizeInPixelsX / 3, ...
    design.stimSizeInPixelsY / 3) / 2;

%% Fixation-dot positions

d = design.fixDotDistanceInPixels;

% Position numbering:
%
%   1 = left
%   2 = top
%   3 = right
%   4 = bottom
%   5 = top-left
%   6 = top-right
%   7 = bottom-left
%   8 = bottom-right

design.fixDotPositions = [
    design.centerX - d, design.centerY;      % 1 = left
    design.centerX,     design.centerY - d;  % 2 = top
    design.centerX + d, design.centerY;      % 3 = right
    design.centerX,     design.centerY + d;  % 4 = bottom
    design.centerX - d, design.centerY - d;  % 5 = top-left
    design.centerX + d, design.centerY - d;  % 6 = top-right
    design.centerX - d, design.centerY + d;  % 7 = bottom-left
    design.centerX + d, design.centerY + d   % 8 = bottom-right
];


%% Valid fixation-dot pairs

% Cardinal pairs
design.fixDotCardinalPairs = [];
for i = 1:4
    for j = 1:4
        if i ~= j
            design.fixDotCardinalPairs(end+1,:) = [i j];
        end
    end
end
% Diagonal pairs
design.fixDotDiagonalPairs = [];
for i = 5:8
    for j = 5:8
        if i ~= j
            design.fixDotDiagonalPairs(end+1,:) = [i j];
        end
    end
end
design.fixDotFadeDuration = 0.2;
design.fixDotFadeFrames = round(design.fixDotFadeDuration / ptb.ifi);

%% Destination rectangle
% Rectangle in which the stimulus is drawn
design.destinationRect = [ ...
    design.centerX - design.stimSizeInPixelsX/2, ...
    design.centerY - design.stimSizeInPixelsY/2, ...
    design.centerX + design.stimSizeInPixelsX/2, ...
    design.centerY + design.stimSizeInPixelsY/2];
end
