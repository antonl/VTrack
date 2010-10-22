
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
