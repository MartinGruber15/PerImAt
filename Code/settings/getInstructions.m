function [design] = getInstructions(log,design,ptb, participantInfo)
% getInstructions: is called and contains all instructions for the subject
%   input:
%       log - a struct containing information about the subject, but also
%       about button assignments
%       design - struct containing information about experimental design,
%       like number of runs, trials and durations
%   output:
%       design - updating the design input struct with instructions
if nargin < 2 || isempty(design)
    design = struct;
end
if nargin < 1 || isempty(log)
    log = struct;
end

%% sanity check: are all the fields present in log and design?
% design
if ~isfield(design, 'stimulusPresentationTime')
    design.stimulusPresentationTime = 90;
end
if ~isfield(design, 'ITI')
    design.ITI = 10;
end
if ~isfield(design, 'numTrials')
    design.numTrials = 6;
end
% log
if ~isfield(log, 'subjectNr')
    log.subjectNr = 'test';
end
if ~isfield(participantInfo, 'language')
    participantInfo.language = 'english';
end

if strcmp (participantInfo.language, 'german')
    %% Determine response keys
    sides = {'rechts', 'links'};
    log.houseSide = sides{(ptb.Keys.house == ptb.Keys.left) + 1};
    log.faceSide = sides{(ptb.Keys.face == ptb.Keys.left) + 1};
    log.piecemeal = 'leertaste';
    log.stim1 = 'ein HAUS';
    log.sideStim1 = log.houseSide;
    log.stim2 = 'ein GESICHT';
    log.sideStim2 = log.faceSide;


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

    %% BR onset rivalry experiment
    design.OnsetInstructionBrascamp1 = [
        'In diesem Experiment wirst du für kurze Zeit zwei verschiedene Bilder\n' ...
        'präsentiert bekommen, eins auf jedes Auge. \n\n' ...
        'Drücke eine beliebige Taste um fortzufahren.'
        ];
    design.OnsetInstructionBrascamp2 = [
        'Deine Aufgabe ist es anzugeben, welches der Bilder du gesehen hast,\n' ...
        ' indem du eine Taste drückst.\n' ...
        'Wenn du ' log.stim1 ' siehst, drücke bitte ' upper(log.sideStim1) '.\n' ...
        'Siehst du ' log.stim2 ', drücke bitte die ' upper(log.sideStim2) '.\n\n' ...
        'Wenn du eine Mischung aus beiden Bildern gesehen hast,\n ' ...
        'drücke bitte die ' upper(log.piecemeal) '\n\n'...
        'Drücke eine beliebige Taste um fortzufahren.'
        ];
    design.OnsetInstructionsBrascamp3 = [
      'BEVOR diese beiden Bilder gezeigt werden, wird ganz kurz ein \n' ...
      'anderes Bild eingeblendet.\n'...
      'Dieses Bild ist nicht relevant für die Aufgabe.\n\n' ...
      'Drücke eine beliebige Taste um fortzufahren.'
    ];
       design.OnsetInstructionsBrascamp4 = [
        'Erinnerung:\n\n' ...
        upper(log.sideStim1) ' für ' log.stim1 '.\n' ...
        upper(log.sideStim2) ' für ' log.stim2 '.\n\n' ...
        'Bei nicht eindeutiger Wahrnehmung ' upper(log.piecemeal) ' drücken.\n\n' ...
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
    design.cueTextBaseline = [''];
    design.finalQuestion = ['Wie gut haben Sie die Aufgabe erledigt?'];

else
    %% determine response keys
    % English version of instructions
    sides = {'right', 'left'};
    log.houseSide = sides{(ptb.Keys.house == ptb.Keys.left) + 1};
    log.faceSide = sides{(ptb.Keys.face == ptb.Keys.left) + 1};
    log.rectSide = sides{(ptb.Keys.rect == ptb.Keys.left) + 1};
    log.circleSide = sides{(ptb.Keys.circle == ptb.Keys.left) + 1};
    log.piecemeal = 'space';
    log.stim1 = 'a HOUSE';
    log.sideStim1 = log.houseSide;
    log.stim2 = 'a FACE';
    log.sideStim2 = log.faceSide;

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

    %% BR onset rivalry experiment
    design.OnsetInstructionBrascamp1 = [
    'In this experiment, you will be briefly shown two different images,\n' ...
    'one to each eye. \n\n' ...
    'Press any key to continue.'
    ];

    design.OnsetInstructionBrascamp2 = [
        'Your task is to indicate which of the images you saw,\n' ...
        'by pressing a key.\n' ...
        'If you see ' log.stim1 ', please press ' upper(log.sideStim1) '.\n' ...
        'If you see ' log.stim2 ', please press ' upper(log.sideStim2) '.\n\n' ...
        'If you see a mixture of both images, please press ' upper(log.piecemeal) '.\n\n' ...
        'Press any key to continue.'
    ];

    design.OnsetInstructionsBrascamp3 = [
        'BEFORE these two images are shown a different image will be\n' ...
        'flashed briefly.\n' ...
        'This image are irrelevant to the task.\n\n' ...
        'Press any key to continue.'
    ];

    design.OnsetInstructionsBrascamp4 = [
        'Reminder:\n\n' ...
        upper(log.sideStim1) ' for ' log.stim1 '.\n' ...
        upper(log.sideStim2) ' for ' log.stim2 '.\n\n' ...
        'If your perception is unclear, press ' upper(log.piecemeal) '.\n\n' ...
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
    design.cueTextBaseline = [''];
    design.finalQuestion = ['How well did you work on the task?'];

end
end
