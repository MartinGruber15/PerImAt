function image_dir(rootDir,monCalDir,ptb)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Applies gamma conversion on all images of all subfolders (depth 1) of the
% given directory.
%
% Input:
%   rootDir: the directory
%   monCalDir: the path to the file for gamma correction
%   ptb: the struct containing window settings + the window that drawn on
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch ptb.SetUp
    case 'CIN-personal'
        LUT = repmat(0:255,3,1)';
    case 'CIN-experimentroom'
        load(monCalDir);
        LUT = round(cal.iGammaTable*255);
    case 'MPI'
        LUT = repmat(0:255,3,1)';
    otherwise
        error('No valid setup choise')
end
items = dir(rootDir);
% loop over all folders in the rootDir
for i = 1:length(items)

    item = items(i);

    if item.isdir && ~strcmp(item.name, '.') && ~strcmp(item.name, '..')
        subfolderPath = fullfile(rootDir, item.name);
        outputFolderName = [item.name '_gamma_corrected'];
        outputFolderPath = fullfile(rootDir, outputFolderName);
        if ~exist(outputFolderPath, 'dir')
            mkdir(outputFolderPath);
        end
        files = dir(subfolderPath);
        % loop over all images within the subfolder
        for j = 1:length(files)
            f = files(j);
            if f.isdir
                continue;
            end
            [~, ~, ext] = fileparts(f.name);
            extLower = lower(ext);

            if ismember(extLower, {'.png'})

                inputPath  = fullfile(subfolderPath, f.name);
                outputPath = fullfile(outputFolderPath, f.name);
                img = imread(inputPath);
                % apply gamma conversion on the image
                img_processed = img_gammaConvert(LUT,img);

                imwrite(img_processed, outputPath);

                fprintf('Processed: %s\n', inputPath);
            end
        end
    end
end

fprintf('Done.\n');
end