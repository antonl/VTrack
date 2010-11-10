function g = gaussian(X, Y, pos, rho, I0) 
%% Calculate Gaussian distribution with variance rho
% xp and yp are the sampling points, pos(1:2) are the particle
% location, I is the peak intensity
g = I0 * exp(-((X - pos(1)).^2 + (Y - pos(2)).^2)./(4*rho^2));
end
