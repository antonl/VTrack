% Create test image sequence

path = 'timage\';

% Size of images to generate
sz = [400 400];

% Length of sequence
len = 50;

% Background value
bg = 10; % Between 255 and 0

% Peak intensity value
i0 = 1;
% Size of particle, radius
part = 20;

% Motion of the particle, (y, x)
pos = @(t) [100 + 5*t, 200];  

% % % % % % % % % % % % % % 
% Start image generation

t = 0;

img = zeros(sz);
imshow(img), colorbar;

% Gaussian is symmetric, generate one quadrant
cpos = pos(t);
[X,Y] = meshgrid((cpos(1)-2*part):cpos(1),(cpos(2)-2*part):cpos(2));
quad = gaussian(X, Y, cpos(1), cpos(2), part/3, 255);
imshow(quad, 'InitialMagnification', 400), colorbar;

gimg = zeros(4*part+2); 
gimg(1:2*part+1, 1:2*part+1) = quad;
gimg(2*part+2:4*part+2, 2*part+2:4*part+2) = rot90(quad, 2);
gimg(1:2*part+1, 2*part+2:4*part+2) = rot90(quad, 3);
gimg(2*part+2:4*part+2, 1:2*part+1) = rot90(quad, 1);

%imshow(gimg, 'InitialMagnification', 400), colorbar;
for t = 1:len
    img = zeros(sz);
    p = pos(t);
    img(p(1)-2*part:p(1)+2*part + 1, p(2)-2*part:p(2)+2*part + 1) =  gimg;
    imwrite(img, sprintf('%simg%3d.tif', path, t), 'tiff');
end
