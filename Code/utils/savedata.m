function log = savedata(log, ptb, design, participantInfo, myPaths)
    %.............................GET RESPONSES...........................%
    % Regardless of HOW the experiment ended.
    % Stop KbQueue data collection
    KbQueueStop(ptb.Keyboard2); 
    KbQueueStop(ptb.Keyboard1);     
    
    % the exact times of which button was pressed at which point. Cannot be
    % preallocated because we do not know how many switches may occur
    log.data.idDown     = [];
    log.data.timeDown   = [];
    log.data.idUp       = [];
    log.data.timeUp     = [];
    % Extract events
    while KbEventAvail(ptb.Keyboard2)
        [evt, ~] = KbEventGet(ptb.Keyboard2);
        
        if evt.Pressed == 1
            log.data.idDown   = [log.data.idDown; evt.Keycode];
            log.data.timeDown = [log.data.timeDown; evt.Time];
        else
            log.data.idUp   = [log.data.idUp; evt.Keycode];
            log.data.timeUp = [log.data.timeUp; evt.Time];
        end
    end
    % filename dependent on task [objects|gratings] and run [1-6]
    fileName = ['sub-' log.sub '_task-' log.task sprintf('_run-%02d',log.runNr)];
    
    % get the file
    if design.useET 
        try
            fprintf('Receiving data file ''%s''\n',  log.edfFile);
            status=Eyelink('ReceiveFile');
            WaitSecs(2);
            if status > 0
                fprintf('ReceiveFile status %d\n', status);
            end
            if exist(log.edfFile, 'file') == 2
                fprintf('Data file ''%s'' can be found in ''%s''\n',  log.edfFile, pwd );
            end
        catch rdf
            fprintf('Problem receiving data file ''%s''\n', log.edfFile );
            rethrow(rdf);
        end
    end

    if strcmp(log.end,'Finished with errors') % PRG: save in just one file.
        save(fullfile(myPaths.subjectDirectory, [fileName '_' char(datetime) '_ptb_error']),'ptb');
        save(fullfile(myPaths.subjectDirectory, [fileName '_' char(datetime) '_log_error']),'log');
        save(fullfile(myPaths.subjectDirectory, [fileName '_' char(datetime) '_design_error']),'design');
        save(fullfile(myPaths.subjectDirectory, 'participantInfo'),'participantInfo');
        if design.useET
            unixStr=['mv ' log.edfFile ' ' fullfile(log.subjectDirectory, [fileName '_error.edf'])];
            unix(unixStr);
        end
    elseif strcmp(log.end,'Escape')
        save(fullfile(myPaths.subjectDirectory, [fileName '_' char(datetime) '_ptb_cancelled']),'ptb');
        save(fullfile(myPaths.subjectDirectory, [fileName '_' char(datetime) '_log_cancelled']),'log'); 
        save(fullfile(myPaths.subjectDirectory, [fileName '_' char(datetime) '_design_cancelled']),'design');
        save(fullfile(myPaths.subjectDirectory, 'participantInfo'),'participantInfo');
        if design.useET
            unixStr=['mv ' log.edfFile ' ' fullfile(log.subjectDirectory, [fileName '_cancelled.edf'])];
            unix(unixStr);
        end
        fprintf('\n Saved cancelled data.... \n');
    elseif strcmp(log.end,'Success')
        %save(fullfile(myPaths.subjectDirectory, [fileName '_' char(datetime) '_ptb']),'ptb');
        %save(fullfile(myPaths.subjectDirectory, [fileName '_' char(datetime) '_log']),'log'); 
        %save(fullfile(myPaths.subjectDirectory, [fileName '_' char(datetime) '_design']),'design');
        %save(fullfile(myPaths.subjectDirectory, 'participantInfo'),'participantInfo');
        fprintf('\n Saved success data.... \n');
        if design.useET
            unixStr=['mv ' log.edfFile ' ' fullfile(myPaths.subjectDirectory, [fileName '.edf'])];
            unix(unixStr);
        end
        [resultsTable, success] = formatResponses(log,ptb);
        if success
            % save table as csv file
            writetable(resultsTable, fullfile(myPaths.subjectDirectory, [fileName '.csv']));
        else
            fprintf('Could not save results table');
        end
    end 
        
end