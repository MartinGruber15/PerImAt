function saveEnvironment(log,ptb,design,myPaths, participantInfo)
timestamp = char(datetime('now','Format','yyyy-MM-dd_HHmmss'));
save(fullfile(myPaths.subjectDirectory, ['ptb_' timestamp '.mat']),'ptb');
save(fullfile(myPaths.subjectDirectory, ['log_' timestamp '.mat']),'log');
save(fullfile(myPaths.subjectDirectory, ['design_' timestamp '.mat']),'design');
save(fullfile(myPaths.subjectDirectory, 'participantInfo.mat'), 'participantInfo');
end