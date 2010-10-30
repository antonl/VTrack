close all;
% Load image from file
img = imread('fft_circle.bmp');
img = rgb2gray(img);
% Show image
imshow(img);
truesize(gcf);
kern = imrect(gca);
kern.setColor('r');

kimg = imcrop(img, kern.getPosition);
dat = normxcorr2(kimg, img);
dat2 = conv2(img, rot90(kimg,2));
h1 = figure('Name', 'Normalized, unthresholded'), imshow(dat), colorbar;

mval = max(dat2(:));
dat2 = dat2./mval; % Normalize
h2 = figure('Name', 'Spacial Correlation'), imshow(dat2), colorbar;

s = regionprops(dat > 0.7, dat, 'basic');
s2 = regionprops(dat2 > 0.7, dat2, 'basic');

cm = s.Centroid;
cm2 = s2.Centroid;
figure(2), hold on, plot(cm(1), cm(2), '*r');
figure(3), hold on, plot(cm2(1), cm2(2), '*g');

pos = kern.getPosition;
cm = cm - pos(3:4)./2;
cm2 = cm2 - pos(3:4)./2;
figure(1), hold on, scatter(cm(1), cm(2), 'r');
figure(1), hold on, scatter(cm2(1), cm2(2), 'g');

disp(sprintf('FFT Conv: %g,%g\nSpace Conv: %g,%g', cm(1), cm(2), cm2(1), cm2(2)));

