function txt = instructionText(ptb, participantInfo, taskMode, design)
% questplus.instructionText  Instruction screen for the QUEST+ calibration/test run.
%
%   txt = questplus.instructionText(ptb, participantInfo, taskMode, design)
%
% taskMode 'report' (default) or 'dual' (report + no-report fixation dots).
% The percept question / "mixed" rule (design.perceptRule) and the
% fixation-dot rule (design.fixDotRule) are those of the main experiment
% (getInstructions), so subjects get the same criterion in both parts.
% "Mixed" is the lower key (ptb.Keys.accept).
if nargin < 3 || isempty(taskMode); taskMode = 'report'; end
dual = strcmpi(taskMode, 'dual');
german = isfield(participantInfo, 'language') && strcmp(participantInfo.language, 'german');
if german
    intro = ['Du siehst ein Haus und ein Gesicht, auf jedem Auge eines.\n' ...
        'Antworte spätestens 2 Sekunden nach den Bildern.\n\n'];   % [changed 2026-11-10] qpSet.responseDeadline
    fix  = 'Schau die ganze Zeit auf das Fixationskreuz.\n\n';
    cont = 'Drücke eine beliebige Taste, um fortzufahren.';
else
    intro = ['You see a house and a face, one in each eye.\n' ...
        'Answer at the latest 2 seconds after the images.\n\n'];   % [changed 2026-11-10] qpSet.responseDeadline
    fix  = 'Look at the fixation cross the whole time.\n\n';
    cont = 'Press any key to continue.';
end
if dual
    txt = [intro design.perceptRule design.fixDotRule cont];
else
    txt = [intro design.perceptRule fix cont];
end
end
