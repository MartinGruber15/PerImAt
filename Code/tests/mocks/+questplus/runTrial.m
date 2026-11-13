function [res, abort] = runTrial(ptb, design, qpSet, leftTex, rightTex) %#ok<INUSL>
% MOCK of questplus.runTrial (tests/dryRunCalibration): no screen, the
% simulated observer (simObserver) answers. leftTex/rightTex are the structs
% of the mock questplus.makeRivalryTextures (field img).
abort = false;
r = simObserver('respond', leftTex.img, rightTex.img);
obs = simObserver('get');
keys = struct('house', ptb.Keys.house, 'face', ptb.Keys.face, 'mixed', ptb.Keys.(qpSet.mixedKeyField));
t0 = 0;
res.response = r;
res.responseKey = keys.(r);
res.rt = obs.rt;
res.responseTime = t0 + qpSet.maskDuration + qpSet.blankDuration + obs.rt;
res.respondedDuringRivalry = obs.rt < qpSet.rivalryDuration;
res.keySequence = keys.(r);
res.ambiguous = false;
res.maskOnset = t0;
res.blankOnset = t0 + qpSet.maskDuration;
res.rivalryOnset = res.blankOnset + qpSet.blankDuration;
res.rivalryOffset = res.rivalryOnset + qpSet.rivalryDuration;
end
