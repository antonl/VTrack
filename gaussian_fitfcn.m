function z = gaussian_fitfcn(param, pos)
% Make sure pos is a 3d matrix, with slice 1 being meshgrid result x,
% 2 is meshgrid result for y
A = param(1);
B = param(2);
x0 = param(3);
y0 = param(4);

X = pos(:, :, 1);
Y = pos(:, :, 2);

z = A*exp(-((X-x0).^2 + (Y - y0).^2)/B);

end
