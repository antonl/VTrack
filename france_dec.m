clear all;
close all;

thresh = 0.92;

% Load all images
path = 'FranceStage\';
imgs = dir([path '5nmstep *']); % Select proper series with wildcards
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

close(h); % Close figure
x = zeros(1,length(imgs)-1); % x-positions
y = zeros(1,length(imgs)-1); % y-positions
for i = 2:length(imgs) % Process each image
%for i = 2:4
    disp(sprintf('reading img %d', i));
    
    img = imread([path imgs(i).name]);
    roi = imcrop(img, p_roi);    

    % Do correlation
    dat = conv2(single(roi), single(rot90(kern,2)), 'valid');

    % Normalize
    mval = max(dat(:));
    dat = dat./mval; % Normalize

    s = regionprops(dat > thresh, dat, 'WeightedCentroid');
    %figure(1), imshow(dat > thresh), colorbar;
    cent = s.WeightedCentroid;
    %figure(2), hold on, plot(cent(1), cent(2), '*r');
    x(i-1) = cent(1);
    y(i-1) = cent(2);
    kern = imcrop(img, p_kern);
    %pause
end

figure, plot(x, y, '.r');
figure, plot(1:length(x), x, 'r');
hold on, plot(1:length(y), y), 'g';

