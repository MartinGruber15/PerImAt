function Psi = mixFeatures(g, cfg)
% mixFeatures  Design matrix of the mixed-percept model: [1 z z^2], z = (g-gMid)/gHalf.
z = (g(:) - cfg.gMid) / cfg.gHalf;
Psi = [ones(numel(z), 1), z, z.^2];
end
