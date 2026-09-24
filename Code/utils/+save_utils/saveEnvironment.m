function saveEnvironment(log,ptb,design,myPaths)
logData = struct(log);
ptbData = struct(ptb);
designData = struct(design);

timestamp = char(datetime('now','Format','yyyy-MM-dd_HHmmss'));
save(fullfile(myPaths.subjectDirectory, ['ptb_' timestamp '.mat']),'ptbData');
save(fullfile(myPaths.subjectDirectory, ['log_' timestamp '.mat']),'logData');
save(fullfile(myPaths.subjectDirectory, ['design_' timestamp '.mat']),'designData');
end