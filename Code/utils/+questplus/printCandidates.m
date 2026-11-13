function printCandidates(cand, iDefault)
% questplus.printCandidates  Console table of questplus.contrastCandidates. [added 2026-11-06]
fprintf('Contrasts as they are entered in the settings (stimulus factor x eye factor = texture contrast):\n');
for k = 1:numel(cand)
    c = cand(k);
    mark = ' '; if k == iDefault; mark = '*'; end
    fprintf('%s %d  %s\n', mark, k, c.label);
    fprintf('      %s\n', questplus.contrastText(c.contrasts, true));
    fprintf('      x = %+.3f / %+.3f log2 | predicted (all trials): P(house) %.2f / %.2f, P(left eye first) %.2f\n', ...
        c.u, c.pHouse, c.pLeft);
end
end
