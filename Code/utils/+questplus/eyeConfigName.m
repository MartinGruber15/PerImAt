function name = eyeConfigName(houseEye)
% questplus.eyeConfigName  +1 -> 'HouseL_FaceR', -1 -> 'FaceL_HouseR'
if houseEye == 1; name = 'HouseL_FaceR'; else; name = 'FaceL_HouseR'; end
end
