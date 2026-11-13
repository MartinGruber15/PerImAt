function printSummary(r, titleStr)
% questplus.printSummary  Console summary of a calibration run (both versions).
if nargin < 2; titleStr = 'QUEST+ CALIBRATION RESULT'; end
est = r.est; f = est.final; c = f.contrasts;
fprintf('\n=================================================\n');
fprintf('   %s\n', titleStr);
fprintf('=================================================\n');
fprintf('Trials: %d valid (house/face) of %d (%d mixed); stop: %s\n', r.nValid, r.nTotal, r.nTotal - r.nValid, r.stopReason);
if isfield(r, 'verification') && ~isempty(r.verification)
    fprintf('Validations (fixed contrasts = estimate; exact binomial tests against 0.5):\n');
    for k = 1:numel(r.verification)
        b = r.verification(k);
        if isfield(b, 'house')
            fprintf(['  validation %d at x = %+.2f / %+.2f: HouseL %d/%d, FaceR %d/%d | FaceL %d/%d, HouseR %d/%d\n' ...
                '    house %d/%d = %.2f [%.2f %.2f] p %.3f | left eye %d/%d = %.2f [%.2f %.2f] p %.3f -> %s\n'], ...
                b.validation, b.xVerify, b.nHouse(1), b.nValid(1), b.nValid(1) - b.nHouse(1), b.nValid(1), ...
                b.nValid(2) - b.nHouse(2), b.nValid(2), b.nHouse(2), b.nValid(2), ...
                b.house.k, b.house.n, b.house.p, b.house.ci95, b.house.pValue, ...
                b.leftEye.k, b.leftEye.n, b.leftEye.p, b.leftEye.ci95, b.leftEye.pValue, ...
                ternaryStr(b.passed, 'PASSED', 'FAILED'));
        else   % runs saved with the earlier likelihood-ratio validation
            fprintf('  validation %d at x = %+.2f / %+.2f: left eye %d/%d (earlier LR-test version)\n', ...
                b.validation, b.xVerify, b.nLeft, sum(b.nValid));
        end
    end
    if isfield(r, 'verified') && ~r.verified
        fprintf(2, 'WARNING: the contrasts are NOT verified (see above). Check fusion/head position and repeat the calibration.\n');
    end
end
fprintf('\nPosterior on the QUEST+ grid (mean, SD, 95%% CI; log2 units):\n');
fprintf('  thetaS (log2 house/face at balance) %+.3f  SD %.3f  [%+.2f %+.2f]  -> house/face ratio %.3f\n', ...
    est.thetaS.mean, est.thetaS.sd, est.thetaS.ci95, 2^est.thetaS.mean);
fprintf('  thetaE (log2 left/right at balance) %+.3f  SD %.3f  [%+.2f %+.2f]  -> left/right ratio %.3f\n', ...
    est.thetaE.mean, est.thetaE.sd, est.thetaE.ci95, 2^est.thetaE.mean);
fprintf('  slope %.2f / log2 unit, lapse %.3f\n', est.slope.mean, est.lapse.mean);
fprintf('  balance points: HouseL+FaceR %+.3f (SD %.3f), FaceL+HouseR %+.3f (SD %.3f) log2\n', ...
    est.uA.mean, est.uA.sd, est.uB.mean, est.uB.sd);
if est.thetaS.mean > 0; s = 'FACE'; else; s = 'HOUSE'; end
if est.thetaE.mean > 0; e = 'RIGHT'; else; e = 'LEFT'; end
fprintf('  -> the %s is the more dominant stimulus, the %s eye the more dominant eye\n', s, e);
note = '';
if r.mlFit.slopeAtBound; note = ' (slope at bound: data perfectly separated?)'; end
fprintf('ML refit (cross-check): thetaS %+.3f, thetaE %+.3f, slope %.2f%s\n', r.mlFit.thetaS, r.mlFit.thetaE, r.mlFit.slope, note);
note = '';
if isfield(r, 'verified') && r.verified; note = ' (= the validated contrasts)'; end
fprintf('\nRecommended contrasts%s:\n', note);
fprintf('  House %.4f  Face %.4f  | Left eye %.4f  Right eye %.4f\n', c.houseContrast, c.faceContrast, c.leftEyeContrast, c.rightEyeContrast);
fprintf('  Textures: HouseL %.4f  FaceL %.4f  HouseR %.4f  FaceR %.4f\n', c.textures.HouseL, c.textures.FaceL, c.textures.HouseR, c.textures.FaceR);
fprintf('Predicted P(house) with these contrasts (posterior mean [95%% CI]):\n');
fprintf('  HouseL+FaceR: %.3f [%.2f %.2f]\n', f.pHouse.mean(1), f.pHouse.ci95(1, :));
fprintf('  FaceL+HouseR: %.3f [%.2f %.2f]\n', f.pHouse.mean(2), f.pHouse.ci95(2, :));
fprintf('  overall P(house) %.3f, P(left-eye stimulus first) %.3f\n', f.pHouseOverall, f.pLeftEyeWins);
if any(f.outOfRange)
    configNames = {'HouseL+FaceR', 'FaceL+HouseR'};
    fprintf(2, ['WARNING: the balance point lies outside the allowed contrast range [%.2f %.2f] ' ...
        '(%s). The contrasts were clipped to the range limit.\n'], r.qpSet.minTextureContrast, ...
        r.qpSet.maxTextureContrast, strjoin(configNames(f.outOfRange), ', '));
end
if isfield(r, 'stability') && ~isempty(r.stability.parts)
    st = r.stability;
    fprintf('\nChange over the run (house/face trials in %d consecutive parts, each estimated alone; slope/lapse fixed):\n', st.nParts);
    for k = 1:numel(st.parts)
        q = st.parts(k);
        fprintf('  trials %3d-%3d: thetaS %+.2f +- %.2f   thetaE %+.2f +- %.2f\n', q.trials, ...
            q.thetaS.mean, q.thetaS.sd, q.thetaE.mean, q.thetaE.sd);
    end
    fprintf('  equal across parts? thetaS p = %.3f, thetaE p = %.3f (chi-square)\n', st.pThetaS, st.pThetaE);
    if st.pThetaE < 0.05
        fprintf(2, ['  NOTE: the eye balance changed during the run (largest difference %.2f log2). The saved\n' ...
            '  contrasts match the average over the run; check fusion/head position before the main experiment.\n'], st.maxDiffThetaE);
    end
end
if isfield(r, 'trials') && ~isempty(r.trials)
    fprintf('\n');
    questplus.carryover(r.trials, true);
end
fprintf('=================================================\n');
end


function out = ternaryStr(c, a, b)
if c; out = a; else; out = b; end
end
