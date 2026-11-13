function participantInfo = consentForm(log, ptb, design, myPaths, participantInfo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% consentForm: fusion alignment, then the consent text (design.consent,
% getInstructions) in the participant's language; a key press confirms. The confirmation is
% stored in <subject>/sub-XX_consent_<time>.mat and in participantInfo.
% (An on-screen confirmation does not replace written consent if your
% ethics approval requires a signature.)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [added 2026-11-10] Fusion alignment before the consent text: the text is
% then shown fused, and the offsets are saved to participantInfo.mat, so the
% first alignment of the session is done here and every later task (BR
% training, calibration, ...) starts from these offsets.
participantInfo = display.stereo.alignFusion(ptb, participantInfo);
questplus.saveFusionOffsets(participantInfo, myPaths);
KbQueueStop(ptb.Keyboard2); KbEventFlush(ptb.Keyboard2);
display.stereo.instruction(ptb, design, design.consent, 1, false);   % min. 1 s, then any key
consent.confirmed = true;
consent.time = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
consent.text = design.consent;
consent.language = 'english';
if isfield(participantInfo, 'language'); consent.language = participantInfo.language; end
consent.sub = log.sub;
file = fullfile(myPaths.subjectDirectory, ['sub-' log.sub '_consent_' ...
    char(datetime('now', 'Format', 'yyyy-MM-dd_HHmmss')) '.mat']);
save(file, 'consent');
participantInfo.consentConfirmed = consent.time;
fprintf('Consent confirmed at %s, saved to\n%s\n', consent.time, file);
Screen('CloseAll');
end
