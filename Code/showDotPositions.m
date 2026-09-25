function showDotPositions(ptb, design)

image1 = design.stimuli.house;
image2 = design.stimuli.face;

draw.stereo.imagesNoReport(ptb,design,image1,image2,design.fixDotValidPairs,design.fixDotTransparency);
Screen('Flip',ptb.window);

KbWait;
Screen('CLoseAll')
end
