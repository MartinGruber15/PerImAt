function saveEnvironment(log,ptb,design,myPaths)
log = struct(log);
ptb = struct(ptb);
design = struct(design);
if isfield(log,'runNr')
    run = num2str(log.runNr);
else
    run = 'x';
end
if isfield(log,'suffix')
    cond = log.suffix;
else
    cond = '';
end
timestamp = char(datetime('now','Format','yyyy-MM-dd_HHmmss'));
save(fullfile(myPaths.subjectDirectory, ['ptb.mat']),'ptb');
save(fullfile(myPaths.subjectDirectory, ['log_' 'run-' run '_' cond '_' timestamp '.mat']),'log');
save(fullfile(myPaths.subjectDirectory, ['design.mat']),'design'); % design and ptb are invariant to condition and run
end