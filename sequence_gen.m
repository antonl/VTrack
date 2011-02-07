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
part = 10;

% Motion of the particle, (x, y)
pos = @(t) [100 + 0.05.*floor(0.2.*t), 200];  

% % % % % % % % % % % % % % 
% Start image generation

%imshow(gimg, 'InitialMagnification', 400), colorbar;
for t = 0:len-1
    [X, Y] = meshgrid(1:sz(1), 1:sz(2));
    img = gaussian(X, Y, pos(t), part, i0); 
    %disp(pos(t));
    %imshow(img);
    %pause
    xy(t+1, 1:2) = pos(t);
    imwrite(img, sprintf('%simg%3d.tif', path, t), 'tiff');
end

save([path 'pos.csv'], 'xy', '-ascii'); % Save real positions to file
