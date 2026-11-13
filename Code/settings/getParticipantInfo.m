function participantInfo = getParticipantInfo(keys, subject_dir, sub)

% Check if subject folder already exists
if isfolder(subject_dir)
    disp('-> Subject folder already EXISTS.')
else
    % create subject folder
    mkdir(subject_dir);
    disp('-> Subject folder CREATED.')
end


% Create participantInfo.mat if not existent
if exist(fullfile(subject_dir, 'participantInfo.mat'),'file') ~= 2
    participantInfo.id = sub;
    participantInfo.date = datetime;
    participantInfo = input.participantInformation(keys, participantInfo);

    % participantInfo.mat speichern
    save(fullfile(subject_dir, 'participantInfo'),'participantInfo');
else
    fprintf('-> participantInfo.mat for subject %s exists.\n', sub);
    load(fullfile(subject_dir, 'participantInfo.mat'));
end
end