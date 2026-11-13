function [texLeft, texRight] = createStereoGaussianNoiseTextures(ptb, design)

% Create one pair of coarse Gaussian-noise textures, one for each eye.
%
% The noise is generated at low resolution and enlarged by the GPU when
% drawn into design.destinationRect.
%
% Output:
% texLeft - PTB texture for the left eye
% texRight - PTB texture for the right eye

% ---------------------------------------------------------------------
% Settings
% ---------------------------------------------------------------------

noiseMean = 128;
noiseSD   = 30;

% Approximate size of one square noise element in physical pixels.
noiseElementSizePx = 4;

% ---------------------------------------------------------------------
% Stimulus geometry
% ---------------------------------------------------------------------

stimulusWidth  = design.destinationRect(3) - ...
    design.destinationRect(1);

stimulusHeight = design.destinationRect(4) - ...
    design.destinationRect(2);

% Number of independent noise values.
noiseColumns = ceil(stimulusWidth  / noiseElementSizePx);
noiseRows    = ceil(stimulusHeight / noiseElementSizePx);

% ---------------------------------------------------------------------
% Generate independent Gaussian noise for each eye
% ---------------------------------------------------------------------

noiseLeft = noiseMean + noiseSD * ...
    randn(noiseRows, noiseColumns);

noiseRight = noiseMean + noiseSD * ...
    randn(noiseRows, noiseColumns);

% Clip before conversion to uint8.
noiseLeft = uint8(max(0, min(255, noiseLeft)));
noiseRight = uint8(max(0, min(255, noiseRight)));

% ---------------------------------------------------------------------
% Upload to GPU
% ---------------------------------------------------------------------

texLeft  = Screen('MakeTexture', ptb.window, noiseLeft);
texRight = Screen('MakeTexture', ptb.window, noiseRight);


end