% Create test image sequence

path = 'timage_jump\';

% Size of images to generate
sz = [400 400];

% Length of sequence
len = 50;

% Background value
bg = 10; % Between 255 and 0

% Peak intensity value
i0 = 1;
% Size of particle, radius
part = 5;

% Motion of the particle, (x, y)
pos = @(t) [100 + floor(0.1.*t) + 0.1*rand(1), 200];  

% % % % % % % % % % % % % % 
% Start image generation

%imshow(gimg, 'InitialMagnification', 400), colorbar;
for t = 0:len
    [X, Y] = meshgrid(1:sz(1), 1:sz(2));
    img = gaussian(X, Y, pos(t), part, i0); 
    
    %imshow(img);
    %pause
    imwrite(img, sprintf('%simg%3d.tif', path, t), 'tiff');
end
