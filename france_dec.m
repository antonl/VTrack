clear all;
close all;

thresh = 0.8;

% Load all images
path = 'FranceStage\';
%path = 'timage_jump\';
%imgs = dir([path 'img*']);
imgs = dir([path '5nmstep*']); % Select proper series with wildcards
% Space in the name above is important

global kern roi;
global h; % handles array

% NOTE: dir returns a struct array
try
    % Determine kernel and roi
    img = imread([path imgs(1).name]);
    h = figure; imshow(img);

    krect = imrect; % kernel position
    krect.setColor('g');
    krect.setResizable(false);

    rrect = imrect; % roi position
    rrect.setColor('r');
    rrect.setResizable(false);

    p_roi = round(rrect.getPosition);
    p_kern = round(krect.getPosition);
catch
    error('Failed to draw ROI and things');
end

kern = imcrop(img, p_kern); % Set initial kernel

close(h); % Close figure
xy = zeros(length(imgs)-1,2); % x-positions

accum = [0 0]; % Accumulated movement
prev = round([-p_roi(1)+p_kern(1)+p_kern(3)/2 -p_roi(2)+p_kern(2)+p_kern(4)/2]); % Previous calculated center of mass
% Initial guess - center of kernel

for i = 2:length(imgs) % Process each image
    try
        img = imread([path imgs(i).name]); % Width, Height
    catch 
        % Handle could not load image problem here
    end
    roi = img(p_roi(2):p_roi(2)+p_roi(4), p_roi(1):p_roi(1)+p_roi(3)); 
    % this gives all pixels fully and partially enclosed
   
    % Do correlation
    try
        dat = conv2(double(roi), double(rot90(kern,2)), 'same');
        if(isempty(dat))
            throw('Could not calculate convolution');
        end
    catch % Do a little error handling
        error('Could not calculate convolution');
    end

    % Normalize
    mval = max(dat(:));
    dat = dat./mval; % Normalize

    try
        s = regionprops(dat > thresh, dat, 'WeightedCentroid');
        if(isempty(s))
            error('Could not calculate region props');
        end
        cent = s.WeightedCentroid; % Center of mass is relative to the edge of the ROI box
    catch
    end
   
    % Get accumuated movement, update previous cm
    assert(all(cent > 0) && all(prev > 0), 'Cent or Prev negative');
    
    % Cm is relative to p_roi location
    if(i >2) % The first shift is due to a guess of the position center. Don't accumulate that 
        accum = accum + cent - prev;
    end

    fprintf(1, 'Accum: (%3.2f, %3.2f)\tCent: (%3.2f, %3.2f)\tPrev: (%3.2f, %3.2f)\n',...
        accum(1), accum(2), cent(1), cent(2), prev(1), prev(2));
    %fprintf(1, '\tp_roi: (%3.2f, %3.2f)\tp_kern: (%3.2f, %3.2f)\n',...
    %    p_roi(1), p_roi(2), p_kern(1), p_kern(2));

    prev = cent;

    xy(i-1, 1:2) = p_roi(1:2) + cent;

    if(max(abs(accum)) >= 1)
        fprintf(1, '%3d:\tMoved kernel by (%3.2f, %3.2f)\n', i, round(accum(1)), ...
            round(accum(2)));
        p_kern(1:2) = p_kern(1:2) + round(accum); % Accum is relative to both p_kern 
        % original position and p_roi. It is RELATIVE shift 
        accum = accum - round(accum); % Retain the fractional part of the movement
        
        % Update kernel when it is moved by a fractional amount
        %kern = img(p_kern(2):p_kern(2)+p_kern(4), p_kern(1):p_kern(1)+p_kern(3)); 
    end
    
    % Recenter Kernel
%    if( max(abs(accum)) > max(p_kern(3:4)./8) ) 
%        fprintf(1, '\t\t Moved ROI by (%3.2f, %3.2f)\n', round(accum(1)), round(accum(2)));
%        p_roi(1:2) = p_roi(1:2) + round(accum); % center ROI on CM 
%        accum = [0 0]; % Reset accum
%    end

    % Recenter ROI
    %if( max(abs(accum)) > 1 ) 
    %end

    % Paste correlation image into original image
    sz = size(img);
    dsz = size(dat);
    img(sz(1) - dsz(1)+1:sz(1), sz(2) - dsz(2)+1:sz(2)) = dat.*255;
    
    imshow(img); 
    rectangle('Position', p_roi, 'EdgeColor', 'g');
    rectangle('Position', p_kern, 'EdgeColor', 'r');
    rectangle('Position', [sz(2)-dsz(2)+1 sz(1)-dsz(1)+1 dsz(2) dsz(1)], 'EdgeColor', 'w');

    pause(0.1);
    % Note, the x and y are reversed
%    kern = img(p_kern(2):p_kern(2)+p_kern(4), p_kern(1):p_kern(1)+p_kern(3)); 
end

%figure, plot(x, y, 'r');
figure, scatter(1:length(xy), xy(:,1), 'r');
hold on, plot(1:length(xy), xy(:,1), 'k');
%hold on, scatter(1:length(y), y), 'g';
