clear all;
close all;

img = imread('FranceStage\2nmstep  0.tif');
figure, imhist(img);

img_hist = imadjust(img, [0.3 0.9], []);
%img_hist = histeq(img, 128);
figure, imhist(img_hist);
figure, imshow(img);
figure, imshow(img_hist);
