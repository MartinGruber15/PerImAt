function [design] = getInstructions(design, participantInfo)
% getInstructions: is called and contains all instructions for the subject
%   input:
%       design - struct containing information about experimental design,
%       like number of runs, trials and durations
%   output:
%       design - updating the design input struct with instructions
if nargin < 2 || isempty(design)
    design = struct;
end
% design
if ~isfield(design, 'stimulusPresentationTime')
    design.stimulusPresentationTime = 1;
end
if ~isfield(design, 'ITI')
    design.ITI = 10;
end
if ~isfield(participantInfo, 'language')
    participantInfo.language = 'english';
end

if strcmp (participantInfo.language, 'german')
    %% general instructions
    design.Introduction = [
        'Vielen Dank, dass du an unserer Binocular Rivalry Studie teilnimmst.\n\n'...
        'Drücke eine beliebige Taste um fortzufahren.'
        ];
    % fixation cross
    design.fixOnFixCross = [
        'Zwischen den Trials fixiere bitte das Fixationskreuz.\n\n' ...
        'Drücke einen beliebige Taste um fortzufahren.'
        ];
    design.waitTillStart = [
        'Wir starten in ' num2str(round(design.waitTillStartDuration)) 's.\n\n'
        ];

    design.RunIsOver = [
        'Der Durchlauf ist vorbei.\n\n' ...
        'Drücke eine beliebige Taste und wende dich an den Versuchsleiter.'
        ];

    %% Onset Training messages
    design.OnsetInstructionsOnsetTraining = [
      'Wir beginnen mit ein paar Übungsdurchläufen.\n\n'...
      'Drücke eine beliebige Taste um fortzufahren.'
    ];

    design.OnsetInstructionsOnsetTrainingEnd = [
      'Die Übungsdurchläufe sind abgeschlossen\n' ...
      'und das Hauptexperiment beginnt.\n\n'...
      'Drücke eine beliebige Taste um fortzufahren.'
    ];

    %% Consent Form
    design.consent = [
        'Hiermit bestätige ich, dass:\n' ...
        'Ich über die Studie und den Versuchsablauf aufgeklärt worden bin.\n' ...
        'Ich willige ein, an dieser Studie über visuelle Wahrnehmung,\n' ...
        'Sofern ich Fragen zu dieser vorgesehenen Studie hatte, wurden sie\n' ...
        'vom Versuchsleitenden vollständig und zu meiner Zufriedenheit beantwortet.\n\n' ...
        'Drücke eine beliebige Taste um zu bestätigen.'
        ];

    design.cueTextPerception = ['P'];
    design.cueTextAttention = ['A'];
    design.cueTextImagery = ['I'];
    design.cueTextBaseline = ['+'];
    %design.finalQuestion = ['Wie gut haben Sie die Aufgabe erledigt?'];
    design.finalQuestion = [' 1 - 5?'];
else

%% general instructions
    design.Introduction = [
        'Thank you for participating in our Binocular Rivalry study.\n\n'...
        'Press any key to continue.'
        ];
    % fixation cross
    design.fixOnFixCross = [
        'Between the trials, please fixate on the fixation cross.\n\n' ...
        'Press any key to continue.'
        ];
    design.waitTillStart = [
        'We will start in ' num2str(round(design.waitTillStartDuration)) 's.\n\n'
        ];

    design.RunIsOver = [
        'The run is over.\n\n' ...
        'Press any key and contact the experimenter.'
        ];
    
    %% Onset Training
    design.OnsetInstructionsOnsetTraining = [
        'We will start with a few practice trials.\n\n' ...
        'Press any key to continue.'
    ];

    design.OnsetInstructionsOnsetTrainingEnd = [
        'The practice trials are complete,\n' ...
        'and the main experiment is about to begin.\n\n' ...
        'Press any key to continue.'
    ];

     %% Consent Form
    design.consent = [
         'I hereby confirm that:\n' ...
        'I have been informed about the study and the test procedure.\n' ...
        'I agree to participate in this study on visual perception,\n' ...
        'Any questions I had about this planned study were\n' ...
        'answered fully and to my satisfaction by the study leader.\n\n' ...
        'Press any key to confirm.'
        ];

    design.cueTextPerception = ['P'];
    design.cueTextAttention = ['A'];
    design.cueTextImagery = ['I'];
    design.cueTextBaseline = ['+'];
    %design.finalQuestion = ['How well did you work on the task?'];
    design.finalQuestion = [' 1 - 5?'];

end
end
