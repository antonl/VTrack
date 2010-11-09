clear all;
close all;

thresh = 0.9;

% Load all images
path = 'timage\';
imgs = dir([path 'img*']); % Select proper series with wildcards
% Space in the name above is important

global kern roi;
global h; % handles array

% NOTE: dir returns a struct array

% Determine kernel and roi
img = imread([path imgs(1).name]);
h = figure; imshow(img);

krect = imrect; % kernel position
krect.setColor('g');
krect.setResizable(false);

rrect = imrect; % roi position
rrect.setColor('r');
rrect.setResizable(false);

kern = imcrop(img, krect.getPosition); % Set initial kernel

p_roi = rrect.getPosition;
p_kern = krect.getPosition;
accum = [0 0]; % Accumulated difference in center of mass
prevc = p_roi(1:2) + p_roi(3:4)./2; % Previous center of mass

close(h); % Close figure
x = zeros(1,length(imgs)-1); % x-positions
y = zeros(1,length(imgs)-1); % y-positions
for i = 2:length(imgs) % Process each image
%for i = 2:4
    disp(sprintf('reading img %d', i));
    
    img = imread([path imgs(i).name]);
    roi = imcrop(img, p_roi);    

    % Do correlation
    dat = conv2(single(roi), single(rot90(kern,2)), 'same');

    % Normalize
    mval = max(dat(:));
    dat = dat./mval; % Normalize

    s = regionprops(dat > thresh, dat, 'WeightedCentroid');
    if mod(i,5) == 0
        figure(2), image(dat > thresh), colorbar;
    end

    cent = s.WeightedCentroid; % Center of mass is relative to the edge of the ROI box

    %figure(2), hold on, plot(cent(1), cent(2), '*r');
    x(i-1) = cent(1);
    y(i-1) = cent(2);

    tmp = p_kern(1:2); 
    % Recenter Kernel
    p_kern(1:2) = p_roi(1:2) + cent./2; 
    %disp(sprintf('CM (%g, %g) Delta (%g, %g) PKern (%g, %g)', cent(1), cent(2), cent(1)-prevc(1), cent(2)-prevc(2), p_kern(1), p_kern(2)));

    p_roi(1:2) = tmp - p_kern(1:2) + p_roi(1:2); 
    
    imshow(img); rectangle('Position', p_roi, 'EdgeColor', 'g'), rectangle('Position', p_kern, 'EdgeColor', 'r');
    kern = imcrop(img, p_kern);
end

figure, plot(x, y, '.r');
figure, plot(1:length(x), x, 'r');
hold on, plot(1:length(y), y), 'g';

%dat = importdata('particletrack.dat', ' ');
%p = dat(:, 2:3);
%figure, plot(p(:,1), p(:,2), '.r');
%figure, hold on, plot(1:length(p(:,1)), p(:,1), 'r'), plot(1:length(p(:,2)), p(:,2), 'g');
