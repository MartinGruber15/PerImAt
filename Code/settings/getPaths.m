function myPaths = getPaths(myPaths,sub)
myPaths.conditionPath = fullfile('..','condition');
myPaths.stimuliLocation = fullfile('..','stimuli');
myPaths.rawdataPath = fullfile('..','rawdata');
myPaths.monCalDirPath = fullfile('..','monitor_calibration','EIZO_CIN5th_Brightness50_SpectraScan670_derived.mat');
myPaths.subjectDirectory = fullfile(myPaths.rawdataPath,['sub-', sub]);
myPaths.instructionFigurePath = fullfile('..','instructions','figures');   % [added 2026-11-10] task figures (getInstructions, display.stereo.figureInstruction)
end