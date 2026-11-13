function [leftTex, rightTex] = makeRivalryTextures(ptb, design, leftImg, rightImg) %#ok<INUSL>
% MOCK of questplus.makeRivalryTextures (tests/dryRunCalibration): returns
% the images themselves instead of PTB textures (read by the mock runTrial).
leftTex  = struct('img', leftImg);
rightTex = struct('img', rightImg);
end
