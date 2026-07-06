function [log, ptb,design] = levelAndSideSetup(ptb, design, log)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reads in a condition file and sets the condition (high level stimuli vs 
% low level stimuli) as well as the key assignment based on the subject
% number. 
% The condtion also depends on the run number.
%
% Requires: 
% log.conditionTableBrascamp: the loaded condition table 
% log.runNr: number of the current run
% log.sub:   subject number
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% for better in-code readability set constants for the left and right
% buffer
log.leftBuffer = 0;
log.rightBuffer = 1;

% Read the table at run and subject id modulo 8
conditionTableBrascamp = log.conditionTableBrascamp;
group = strcat('group-', num2str(mod(str2double(log.sub), 8) + 1));
keyboardCondtionHigh = conditionTableBrascamp.keyboard_high{strcmp(conditionTableBrascamp.Var1, group)};
keyboardCondtionLow = conditionTableBrascamp.keyboard_low{strcmp(conditionTableBrascamp.Var1, group)};
if isfield(log, 'runNr')
% set condition
if isfield(log, 'runNr')
    run = strcat('Run_',num2str(log.runNr));
    design.levelCondition = conditionTableBrascamp.(run){strcmp(conditionTableBrascamp.Var1, group)};
else
    design.levelCondition = 'high';
end

% key assignment
if  strcmp(keyboardCondtionHigh, 'inv')
    ptb.Keys.house = ptb.Keys.right;
    ptb.Keys.face = ptb.Keys.left;
else
    ptb.Keys.house = ptb.Keys.left;
    ptb.Keys.face = ptb.Keys.right;
end
if strcmp(keyboardCondtionLow, 'inv')
    ptb.Keys.rect = ptb.Keys.right;
    ptb.Keys.circle = ptb.Keys.left;
else
    ptb.Keys.rect = ptb.Keys.left;
    ptb.Keys.circle = ptb.Keys.right;
end

end