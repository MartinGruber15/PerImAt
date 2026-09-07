function masktex = gaussianMask(window, color, width, height, falloff)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% creates gaussian noise texturethat is stronger towards the edges and 
% clear in the center
% input:
%   window: the window for which the texture is generated 
%   color: the color of the noise
%   width, height: the dimensions of the noise
%   falloff: scaling of steepness. Higher values -> stronger falloff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[x, y] = meshgrid(linspace(-width/2, width/2, width), linspace(-height/2, height/2, height));

xsd = width / 6;
ysd = height / 6;

gauss = 1 - exp(- (x.^2)/(2*xsd^2) - (y.^2)/(2*ysd^2));

% Apply nonlinear shaping: higher falloff -> steeper edges
alpha = uint8(round((gauss .^ falloff) * 255));
%alpha = uint8(round((1 - exp(- (x.^2)/(2*xsd^2) - (y.^2)/(2*ysd^2))) * 255));
colorUint8 = uint8(round(color(:)' * 255));

maskblob = zeros(height, width, 4, 'uint8');
maskblob(:,:,1) = colorUint8(1);  % R
maskblob(:,:,2) = colorUint8(2);  % G
maskblob(:,:,3) = colorUint8(3);  % B
maskblob(:,:,4) = alpha;          % Alpha

% Create texture
masktex = Screen('MakeTexture', window, maskblob);
end