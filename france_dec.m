clear all;
close all;

thresh = 0.2;

% Load all images
path = 'timage_jump\';
imgs = dir([path 'img*']); % Select proper series with wildcards
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
catch
end

kern = imcrop(img, krect.getPosition); % Set initial kernel

p_roi = rrect.getPosition;
p_kern = krect.getPosition;

close(h); % Close figure
x = zeros(1,length(imgs)-1); % x-positions
y = zeros(1,length(imgs)-1); % y-positions

accum = [0 0]; % Accumulated movement
prev = [-p_roi(1)+p_kern(1)+p_kern(3)/2 -p_roi(2)+p_kern(2)+p_kern(4)/2]; % Previous calculated center of mass
% Initial guess - center of kernel

for i = 2:length(imgs) % Process each image
    img = imread([path imgs(i).name]);
    roi = imcrop(img, p_roi); % this gives all pixels fully and partially enclosed
    % Size is actually p_roi width +1,height +1
    
    % Do correlation
    try
        dat = conv2(single(roi), single(rot90(kern,2)), 'same');
        if(isempty(dat))
            error('Could not calculate convolution');
        end
    catch % Do a little error handling
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
    % Cm is relative to p_roi location
    accum = accum + cent - prev;
    assert(all(cent > 0) && all(prev > 0), 'Cent or Prev negative');

    fprintf(1, 'Accum: (%3.2f, %3.2f)\tCent: (%3.2f, %3.2f)\tPrev: (%3.2f, %3.2f)\n',...
        accum(1), accum(2), cent(1), cent(2), prev(1), prev(2));

    prev = cent;

    %figure(2), hold on, plot(cent(1), cent(2), '*r');
    x(i-1) = p_roi(1) + cent(1);
    y(i-1) = p_roi(2) + cent(2);

    if(max(abs(accum)) >= 1)
        fprintf(1, '%3d:\tMoved kernel by (%3.2f, %3.2f)\n', i, floor(accum(1)), ...
            floor(accum(2)));
        p_kern(1:2) = p_kern(1:2) + floor(accum); % Accum is relative to both p_kern 
        % original position and p_roi. It is RELATIVE shift 
        accum = accum - floor(accum); % Retain the fractional part of the movement
    end
    
    % Recenter Kernel
%    if( max(abs(accum)) > max(p_kern(3:4)./8) ) 
%        fprintf(1, '\t\t Moved ROI by (%3.2f, %3.2f)\n', floor(accum(1)), floor(accum(2)));
%        p_roi(1:2) = p_roi(1:2) + floor(accum); % center ROI on CM 
%        accum = [0 0]; % Reset accum
%    end

    % Recenter ROI
    %if( max(abs(accum)) > 1 ) 
    %end

    % Paste correlation image into original image
    sz = size(img);
    dsz = size(dat);
    img(sz(2) - dsz(1) + 1:sz(2), sz(1) - dsz(2) + 1:sz(1)) = dat.*255;
    
    imshow(img); 
    rectangle('Position', p_roi, 'EdgeColor', 'g');
    rectangle('Position', p_kern, 'EdgeColor', 'r');
   

    pause(0.1);
    kern = imcrop(img, p_kern);
end

%figure, plot(x, y, 'r');
%figure, scatter(1:length(x), x, 'r');
%hold on, scatter(1:length(y), y), 'g';
