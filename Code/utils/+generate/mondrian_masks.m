function masks = mondrian_masks(sz_x,sz_y,n_masks,shape,selection)
% MAKE_MONDRIAN_MASKS
%
% This function creates Mondrian masks that can be used for continuous
% flash suppression.
%
% New:
%   shape = 4 : even mix of rectangles and circles
%              (rectangles are ~2:1 aspect ratio)
%   Output masks are shifted so overall mean luminance ~= 0.5
%
% Input variables:
%   sz_x:      Size of mask in x-dimension
%   sz_y:      Size of mask in y-dimension (large difference to sz_x may cause error)
%   n_masks:   Number of masks to be created
%   [shape]:   Shape of elements:
%              1 = square
%              2 = circular
%              3 = diamond
%              4 = even mix rectangles + circles
%   [selection]: Color style (1 = BRGBYCMW, 2 = grayscale, 3-15 other schemes)
%
% Output variable:
%   masks:     n_masks x 1 cell array, containing the Mondrian masks
%
% (c) 2009 Martin Hebart (original)
% Additions (mixed rectangles+circles, mean luminance 0.5) by <you>.

sizes = 0.04:0.01:0.18; % in percent of x-dimension
sizes = sizes.*1.2;

% how many shapes should be drawn?
loop_nr = round(8*(sz_y/sz_x)/mean(sizes.^2)); % if area is filled 8 times, this is normally sufficient

% Select colors in subfunction at bottom of this function
colors = select_colors(selection);

masks  = cell(n_masks,1); % init
sizes  = ceil(sizes * sz_x); % sizes relative to x-dimension
levels = colors;

% background starting value is mid-grey
mask = 0.5*ones(sz_y+max(sizes),sz_x+max(sizes),3);

maskindex = mask;
maskindex(1:numel(mask)) = 1:numel(mask);

sizes_templates       = cell(length(sizes),1); % for classic shapes
sizes_templates_rect  = cell(length(sizes),1); % for rectangles (shape=4)
sizes_templates_circ  = cell(length(sizes),1); % for circles (shape=4)

switch shape
    case 1 % square shape
        for i = 1:length(sizes)
            template = 0*mask;
            square   = ones(sizes(i),sizes(i),3);
            template(1:size(square,2),1:size(square,1),:) = square;
            sizes_templates{i} = find(template)-1;
        end
        
    case 2 % circle shape
        for i = 1:length(sizes)
            template = 0*mask;
            [cx,cy]  = meshgrid(linspace(-sizes(i)/2+0.5,sizes(i)/2-0.5,sizes(i)));
            cz       = sqrt(cx.^2+cy.^2);
            circle   = cz < sizes(i)/2;
            template(1:sizes(i),1:sizes(i),:) = repmat(circle,[1 1 3]);
            sizes_templates{i} = find(template)-1;
        end
        
    case 3 % diamond shape
        for i = 1:length(sizes)
            template = 0*mask;
            square   = ones(sizes(i),sizes(i));
            squarerot = imrotate(square,45);
            template(1:size(squarerot,2),1:size(squarerot,1),:) = repmat(squarerot,[1 1 3]);
            sizes_templates{i} = find(template)-1;
        end
        
    case 4 % *** NEW: mix of rectangles and circles ***
        for i = 1:length(sizes)
            % --- circle template (like case 2) ---
            template_c = 0*mask;
            [cx,cy]    = meshgrid(linspace(-sizes(i)/2+0.5,sizes(i)/2-0.5,sizes(i)));
            cz         = sqrt(cx.^2+cy.^2);
            circle     = cz < sizes(i)/2;
            template_c(1:sizes(i),1:sizes(i),:) = repmat(circle,[1 1 3]);
            sizes_templates_circ{i} = find(template_c)-1;
            
            % --- rectangle template (2:1 aspect ratio, wider than tall) ---
            template_r = 0*mask;
            w = sizes(i);                          % width
            h = max(1, round(sizes(i)/2));         % height (half the width)
            rect2d     = ones(h,w);
            template_r(1:h,1:w,:) = repmat(rect2d,[1 1 3]);
            sizes_templates_rect{i} = find(template_r)-1;
        end
end

% in the bottom additional area no shape may be started, otherwise error
excluded = maskindex(:,end-max(sizes)+1:end,1);
if shape == 3 % for diamond special case
    excluded = maskindex(:,end-round(1.5*max(sizes))+1:end,1);
end
maskindex = maskindex(:,:,1);
maskindex = setdiff(maskindex(:),excluded(:));

for i_mask = 1:n_masks
    
    curr_maskindex = maskindex(ceil(length(maskindex)*rand(loop_nr,1))); % random positions
    
    for i = 1:loop_nr
        
        csize = ceil(length(sizes)*rand); % current size, randomly defined
        
        randpos = curr_maskindex(i);      % random starting position
        
        % --- choose which template to use ---
        if shape == 4
            % even mix of rectangles and circles
            if rand < 0.5
                currindex = sizes_templates_rect{csize}(:) + randpos;
            else
                currindex = sizes_templates_circ{csize}(:) + randpos;
            end
        else
            currindex = sizes_templates{csize}(:) + randpos;
        end
        
        tmp       = ones(length(currindex)/3,1)'; % vector of ones
        currlevel = levels(ceil(rand*size(levels,1)),:);
        
        mask(currindex) = [currlevel(1)*tmp currlevel(2)*tmp currlevel(3)*tmp]; % fill shape in mask
        
    end
    
    % crop mask to requested size
    thisMask = mask((1:sz_y) + ceil(max(sizes)/2), ...
                    (1:sz_x) + ceil(max(sizes)/2), :);
    
    % --- enforce mean luminance ~ 0.5 ---
    % luminance approximated as mean over all channels/pixels
    currMean = mean(thisMask(:));
    shift    = 0.5 - currMean;
    thisMask = thisMask + shift;          % shift intensities
    thisMask = max(min(thisMask,1),0);    % clip to [0,1]
    
    masks{i_mask} = thisMask;
end

% If no output, show masks
if nargout == 0
   
    h = figure;
    
    for i_mask = 1:n_masks
        imshow(masks{i_mask})
        pause(0.09)
    end    
    
    pause(0.5)
    close(h)
end


% ------------------ Color selection subfunction -------------------------
function colors = select_colors(selection)

switch selection
    
    case 1  % original colors for breaking, too
        colors = [0 0 0;...
            1 0 0;...
            0 1 0;...
            0 0 1;...
            1 1 0;...
            1 0 1;...
            0 1 1;...
            1 1 1];
        
    case 2  % grayscale
        colors = [0 0 0;...
            0.3 0.3 0.3;...
            0.5 0.5 0.5;...
            0.7 0.7 0.7;...
            1 1 1];
        
    case 3 % all relevant colors (works quite well):
        colors = [1 0 0;...   % red
            0.5 0 0;...       % dark red
            0 1 0;...         % green
            0 0.5 0;...       % dark green
            0 0 1;...         % blue
            0 0 0.5;...       % dark blue
            0.1 0.6 1;...     % light blue
            1 1 0;...         % yellow
            0.5 0.5 0;...     % dark yellow
            1 0 1;...         % magenta
            0 1 1;...         % cyan
            0 0.5 0.5;...     % dark cyan
            1 1 1;...         % white
            0 0 0;...         % black
            0.5 0.5 0.5;...   % gray
            0.3 0.1 0.5;...   % dark purple
            1 0.7 0];         % orange
        
    case 4 % works quite well
        colors = [
            1 0 0;...           % red
            0.5 0 0;...         % dark red
            0 0 1;...           % blue
            0 0 0.5;...         % dark blue
            0.1 0.6 1;...       % light blue
            1 0 1;...           % magenta
            0 0.5 0.5;...       % dark cyan
            0 0 0;...           % black
            0.3 0.1 0.5;...     % dark purple
            1 0.7 0;...         % orange
            ];
        
    case 5 % purples: works quite well
        colors = [0.4 0 0.8;...
            0.4 0.2 0.6;...
            0.2 0 0.5;...
            0.6 0.3 0.9;...
            0.7 0.5 0.9];
        
    case 6 % reds: works quite well
        colors = [0.5 0 0;...
            1.0 0.1 0.6;...
            0.5 0 0.3;...
            0.8 0.4 0.6;...
            0.5 0.2 0.4;...
            0.5 0.2 0.2;...
            0.8 0.1 0.5;...
            1.0 0.3 0;...
            0.5 0.1 0;...
            0.8 0.1 0.6;...
            0.5 0.1 0.3;...
            0.7 0.1 0.1;...
            0.5 0.1 0.1;...
            1.0 0 0;...
            0.5 0 0;...
            0.5 0.2 0.1];
        
    case 7 % blues: works quite well
        colors = [0.5 0.2 0.9;...
            0.4 0.6 0.6;...
            0.4 0.6 0.9;...
            0 0 0.5;...
            0 0.5 0.5;...
            0.3 0.2 0.5;...
            0 0.7 1.0;...
            0 0.6 0.8;...
            0 0.4 0.5;...
            0.1 0.3 0.5;...
            0.5 0.4 1.0;...
            0.4 0.8 0.7;...
            0 0 0.8;...
            0.5 0.4 0.9;...
            0.1 0.1 0.4;...
            0 0 0.5;...
            0.2 0.3 0.5;...
            0.4 0.4 0.8;...
            0.3 0.2 0.5;...
            0 0 1.0;...
            0 0.5 0.5];
        
    case 8 % Professional 1
        colors = [0 0 0.4;...
            1.0 1.0 1.0;...
            0.8 0.8 0.8;...
            0 0 0.8;...
            0.6 0.4 0;...
            0.4 0 0;...
            0.2 0 0];
        
    case 9 % Professional 2 (I like it)
        colors = [0 0.2 0.2;...
            0 0.4 0.4;...
            1.0 1.0 1.0;...
            0.4 0 0.2;...
            0.4 0.6 0.6;...
            0.4 0.2 0.2;...
            0 0 0];
        
    case 10 % Appetizing: tasty
        colors = [0.6 0 0;...
            1.0 0.8 0.6;...
            0.8 0.4 0.2;...
            0.4 0 0;...
            0 0.4 0.2;...
            0.8 0.2 0];
        
    case 11 % Electric (adjusted)
        colors = [0 1.0 0;...
            1.0 0 0.6;...
            0.8 1.0 0;...
            0 0 0;...
            1.0 0.7 0.2;...
            1.0 1.0 1.0];
        
    case 12 % Dependable 1
        colors = [0 0.2 0.2;...
            1.0 1.0 1.0;...
            0 0.4 0.2;...
            0.6 0.6 0.6;...
            0.2 0 0];
        
    case 13 % Dependable 2
        colors = [0.4 0.2 0.2;...
            0.4 0.4 0.4;...
            0 0 0.4;...
            0.2 0 0;...
            0.8 0.8 0.8;...
            0 0 0.6];
        
    case 14 % Earthy Ecological Natural
        colors = [0 0.4 0.2;...
            1.0 1.0 0.8;...
            0.4 0.2 0;...
            0.8 0.8 0.4;...
            0.6 0.4 0;...
            0 0.8 0.2;...
            0.4 0.6 0.2;...
            0 0 0];
        
    case 15  % Feminine
        colors = [0.8 0.6 0.2;...
            0.4 0 0.6;...
            0.8 0 0.6;...
            0 0.8 0.8;...
            0.6 0 0.4;...
            1.0 1.0 1.0;...
            0 0 0];
        
end
