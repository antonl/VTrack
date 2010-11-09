function g = gaussian(X, Y, x0, y0, rho, I0) 
%% Calculate Gaussian distribution with variance rho
% xp and yp are the sampling points, x0 and y0 are the particle
% location, I is the peak intensity
g = I0 * exp(-((X - x0).^2 + (Y - y0).^2)./(4*rho^2));
end
