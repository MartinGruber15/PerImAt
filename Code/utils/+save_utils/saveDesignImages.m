function saveDesignImages(design,outputDir)
% Save every image in design.images as a PNG for debugging.

if nargin < 2 || isempty(outputDir)
    outputDir = fullfile(pwd,'designImageDebug');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

names = fieldnames(design.images);
for k = 1:numel(names)
    name = names{k};
    image = design.images.(name);
    if isempty(image), continue; end
    filename = fullfile(outputDir,[name '.png']);
    imwrite(image,filename);
end

fprintf('Saved %d image fields to %s\n',numel(names),outputDir);
end