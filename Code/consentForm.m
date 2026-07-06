function log = consentForm(log, ptb, design, participantInfo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Displays a consent form.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[log, ptb, design] = levelAndSideSetup(ptb, design, log);
design.waitTillStartDuration = 3;
design = getInstructions(log,design,ptb,participantInfo);
displayStereoInstruction(ptb, log, design.consent, 0, false);
log.consent = 1;
Screen('CloseAll');
end