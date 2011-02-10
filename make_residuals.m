% Run france_dec first
% Assume results are in xy

% load data for sequence gen
data = importdata('FranceStage\5nmstep.txt');
xy_real = data(:, 2:3);
%xy_real = importdata('timage_jump\pos.csv');
%xy_real(1,:) = []; % Delete first point, it isn't plotted in tracking

% Get mean, to subtract differences in absolute position
real_mx = mean(xy_real(:,1));
real_my = mean(xy_real(:,2));

xy_mx = mean(xy(:,1));
xy_my = mean(xy(:,2));

xy_real(:,1) = xy_real(:,1) - real_mx;
xy_real(:,2) = xy_real(:,2) - real_my;

xy(:,1) = xy(:,1) - xy_mx;
xy(:,2) = xy(:,2) - xy_my;


figure, hold on;
plot(xy_real(:,1), '-^r', 'MarkerSize', 7);
plot(xy(:,1), '-ob', 'MarkerSize', 7);

figure, hold on;

subplot(211);
stem(xy_real(:,1) - xy(:,1));
title('Residuals');
ylabel('X Residuals');

subplot(212);
stem(xy_real(:,2) - xy(:,2));
ylabel('Y Residuals');



