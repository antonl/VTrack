close all;
% Load image from file
img = imread('fft_test.bmp');
img = rgb2gray(img);
% Show image
imshow(img);
truesize(gcf);
kern = imrect(gca);
kern.setColor('r');

kimg = imcrop(img, kern.getPosition);
dat = normxcorr2(kimg, img);
figure, imshow(dat), colorbar;

s = regionprops(dat > 0.2, dat, 'basic');
hold on;
cm = s.Centroid;
plot(cm(1), cm(2), 'r*');

pos = kern.getPosition;
cm = cm - pos(3:4)./2;
figure(1), hold on, plot(cm(1), cm(2), 'r*');
cm

