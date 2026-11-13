function pHouse = model(x, houseEye, thetaS, thetaE, slope, lapse)
% questplus.model  Psychometric function of the binocular-rivalry balance model.
%
%   pHouse = questplus.model(x, houseEye, thetaS, thetaE, slope, lapse)
%
% Probability that the FIRST dominant percept in onset rivalry is the house
% (given that the response is house or face, i.e. not mixed).
%
% Stimulus (one trial):
%   x         log2(c_house / c_face): log2 contrast ratio between the house
%             texture and the face texture that are on the screen.
%   houseEye  +1 : house -> left eye,  face -> right eye   (HouseL + FaceR)
%             -1 : house -> right eye, face -> left eye    (FaceL  + HouseR)
%
% Parameters:
%   thetaS    stimulus balance point: log2(houseContrast/faceContrast) at
%             which house and face are equally likely (eyes balanced).
%             > 0: the face is intrinsically more dominant.
%   thetaE    eye balance point: log2(leftEyeContrast/rightEyeContrast) at
%             which both eyes are equally likely to win.
%             > 0: the right eye is intrinsically more dominant.
%   slope     slope of the logistic function per log2 unit of contrast ratio
%   lapse     lapse rate; on these trials the report is random (house/face 50:50)
%
% Model:
%   With texture contrasts c(stim,eye) = c0 * 2^(+-ds/2) * 2^(+-de/2)
%   (ds = log2 house/face, de = log2 left/right) a HouseL+FaceR trial shows
%   x = ds + de and a FaceL+HouseR trial x = ds - de. The house advantage is
%       D = (ds - thetaS) + houseEye*(de - thetaE) = x - (thetaS + houseEye*thetaE)
%   and
%       P(house) = lapse/2 + (1 - lapse) * 1 / (1 + exp(-slope * D)).
%   Balanced eyes AND balanced stimuli <=> P(house) = 0.5 in both eye
%   configurations <=> x = thetaS + thetaE (HouseL/FaceR) and
%   x = thetaS - thetaE (FaceL/HouseR).
%
% All inputs may be arrays of compatible size (implicit expansion).
%
% The psychometric function returns P(outcome | x, parameters) as required
% by QUEST+ (Watson, 2017, J Vis 17(3):10, "Theory": psi(x, s)).

u = thetaS + houseEye .* thetaE;                 % balance point for this eye configuration
z = slope .* (x - u);
pHouse = lapse ./ 2 + (1 - lapse) ./ (1 + exp(-z));
end
