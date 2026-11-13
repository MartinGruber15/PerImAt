function choice = chooseContrasts(vs, qp, qpSet)
% questplus.chooseContrasts  Experimenter chooses the contrasts to save after the run. [added 2026-11-06]
%
%   choice = questplus.chooseContrasts(vs, qp, qpSet)
%
% Lists questplus.contrastCandidates (current estimate from all trials, end of
% the calibration (= tested in validation 1), contrasts tested in each validation, with the predicted
% P(house) / P(left eye first)) and asks for a number; Enter = the default
% (last passed validation, otherwise the estimate from all trials).
% choice: the chosen candidate (label, u, contrasts, pHouse, pLeft) + index.
% The values are then shown once more by input.adaptStimuli (Enter keeps a
% value; Enter again saves them).
[cand, iDef] = questplus.contrastCandidates(vs, qp, qpSet);
fprintf('\n=================================================\n');
fprintf('  WHICH CONTRASTS SHALL BE SAVED?\n');
fprintf('=================================================\n');
questplus.printCandidates(cand, iDef);
try FlushEvents('keyDown'); catch; end
while true
    s = strtrim(input(sprintf('Number of the contrasts to save (Enter = %d): ', iDef), 's'));
    if isempty(s); k = iDef; break; end
    k = str2double(s);
    if isscalar(k) && ~isnan(k) && k == round(k) && k >= 1 && k <= numel(cand); break; end
    fprintf('Please type a number between 1 and %d, or press Enter.\n', numel(cand));
end
choice = cand(k);
choice.index = k;
fprintf('-> %d: %s\n   %s\n', k, choice.label, questplus.contrastText(choice.contrasts, true));
end
