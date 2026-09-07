function participantInfo = inputParticipantInformation(ptb, participantInfo)
%inputSubID: get input from experimentor about subject information
%   input:
%       ptb - a struct containing key IDs with meaning
%       participantInfo - a struct where information about the subject is stored
%   output:
%       participantInfo

    safetynet = true;
    % TODO: make the language dependent on input in second while loop
    
    try
        while safetynet
            %% GET SUBJECT DATA
            checkinput = true;
            while checkinput
                participantInfo.isGerman = input('Does the subject understand german [y/n]? ','s');
                if strcmp (participantInfo.isGerman, KbName(ptb.Keys.yes))
                    participantInfo.language = 'german';
                    checkinput = false;
                elseif strcmp (participantInfo.isGerman, KbName(ptb.Keys.no))
                    participantInfo.language = 'english';
                    checkinput = false;
                else
                    fprintf('Please answer with "y" or "n".\n')
                end
            end
            
            checkinput = true;
            while checkinput
                participantInfo.handedness = input('Subjects handedness [l/r]? ','s');
                if strcmp (participantInfo.handedness, 'l')
                    participantInfo.handedness = 'left';
                    checkinput = false;
                elseif strcmp (participantInfo.handedness, 'r')
                    participantInfo.handedness = 'right';
                    checkinput = false;
                else
                    fprintf('Please answer with "l" or "r".\n')
                end
            end
            
            checkinput = true;
            while checkinput
                participantInfo.dominantEye = input('Subjects dominant eye [l/r]? ','s');
                if strcmp (participantInfo.dominantEye, 'l')
                    participantInfo.dominantEye = 'left';
                    checkinput = false;
                elseif strcmp (participantInfo.dominantEye, 'r')
                    participantInfo.dominantEye = 'right';
                    checkinput = false;
                else
                    fprintf('Please answer with "l" or "r".\n')
                end
            end
            
            checkinput = true;
            while checkinput
                participantInfo.subjectAge = input('Subjects age? ','s');
                [age, valid] = str2num(participantInfo.subjectAge);
                if valid
                    % check subject age and if accidentally a complex
                    % number was given
                    if (age >= 18) && (isreal(age))
                        participantInfo.subjectAge = age;
                        checkinput = false;
                    end
                else
                    fprintf('Please give a real number as input.\n')
                end
            end


            checkinput = true;
            while checkinput
                participantInfo.gender = input('Subjects gender [m/f/d]? ','s');
                if strcmp (participantInfo.gender, 'm')
                    participantInfo.gender = 'male';
                    checkinput = false;
                elseif strcmp (participantInfo.gender, 'f')
                    participantInfo.gender = 'female';
                    checkinput = false;
                elseif strcmp (participantInfo.gender, 'd')
                    participantInfo.gender = 'diverse';
                    checkinput = false;
                else
                    fprintf('Please answer with "m", "f" or "d".\n')
                end
            end

            checkinput = true;
            while checkinput
                participantInfo.color = input('Passed color Vision test? [y/n]','s');
                if strcmp (participantInfo.color, 'y')
                    participantInfo.color = 'ok';
                    checkinput = false;
                elseif strcmp (participantInfo.color, 'n')
                    participantInfo.color = 'not ok';
                    checkinput = false;
                else
                    fprintf('Please answer with "y" or "n".\n')
                end
            end

            checkinput = true;
            while checkinput
                visionInput = lower(strtrim(input( ...
                    'Vision [n = normal / c = corrected-to-normal / u = non-corrected]? ', 's')));
            
                if strcmp(visionInput, 'n')
                    participantInfo.vision = 'normal';
                    participantInfo.visionCorrection = 'none';
                    checkinput = false;
            
                elseif strcmp(visionInput, 'c')
                    participantInfo.vision = 'corrected-to-normal';
                    participantInfo.visionCorrection = strtrim(input( ...
                        'Which correction do you use (e.g., glasses or contact lenses)? ', 's'));
                    checkinput = false;
            
                elseif strcmp(visionInput, 'u')
                    participantInfo.vision = 'non-corrected';
                    participantInfo.visionCorrection = 'none';
                    checkinput = false;
            
                else
                    fprintf('Please answer with "n", "c", or "u".\n');
                end
            end
            checkinput = true;
            while checkinput
                participantInfo.eyecondition = input('Amblyopia (lazy-eye) or strabismus (crossed-eyes)? ','s');
                if strcmp (participantInfo.eyecondition, 'y')
                    participantInfo.eyecondition = 'ok';
                    checkinput = false;
                elseif strcmp (participantInfo.eyecondition, 'n')
                    participantInfo.eyecondition = 'not ok';
                    checkinput = false;
                else
                    fprintf('Please answer with "y" or "n".\n')
                end
            end

            fprintf('\n\n');
            fprintf ([...
                'You specified subject ' participantInfo.id '\n' ...
                'Language:      ' participantInfo.language '\n' ...
                'Handedness:    ' participantInfo.handedness '\n' ...
                'Dominant eye:  ' participantInfo.dominantEye '\n' ...
                'Age:           ' num2str(participantInfo.subjectAge) '\n' ...
                'Gender:        ' participantInfo.gender '\n' ...
                'Color:         ' participantInfo.color '\n' ...
                'Vision:        ' participantInfo.vision '\n' ...
                'Visual aid:    ' participantInfo.visionCorrection '\n' ...
                'Eye condition: ' participantInfo.eyecondition '\n'
                ])
            answer = input ('Are you sure you gave the right parameters? (y)','s');
            if strcmp (answer, 'y')
                safetynet = false;
            end
            checkinput = true;
        end
    catch INPUT_ERROR
        rethrow (INPUT_ERROR);
    end
end