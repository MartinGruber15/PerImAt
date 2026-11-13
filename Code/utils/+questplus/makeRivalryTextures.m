function [leftTex, rightTex] = makeRivalryTextures(ptb, design, leftImg, rightImg)
% questplus.makeRivalryTextures  Stimulus images -> PTB textures on pink noise.
%
%   [leftTex, rightTex] = questplus.makeRivalryTextures(ptb, design, leftImg, rightImg)
%
% Same compositing as in trialProcedurePerImAtOffline (generate.makePinkNoiseTex
% with an empty mask, as the base images in design.masks are empty).
% Close the textures with Screen('Close', [leftTex rightTex]) after use.
leftTex  = generate.makePinkNoiseTex(ptb.window, leftImg,  [], design);
rightTex = generate.makePinkNoiseTex(ptb.window, rightImg, [], design);
end
