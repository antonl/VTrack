function [v,h] = pt_gui()
%PT_GUI Create the GUI and return the handle to the created handle in h
%   

% Contains position of the screen as [pos_left pos_right width height]
sz = get(0, 'ScreenSize');

% Default size of figure window
dim = [800 700];
conf = 200;
% Create a hidden figure that will be populated with ui controls.
h = figure('Visible', 'off', 'Position', [(sz(3)-dim(1))/2 (sz(4)-dim(2))/2 dim], ...
    'Toolbar', 'none', 'MenuBar', 'none', 'NumberTitle', 'off', 'Renderer', 'ZBuffer', ...
    'Name', 'ParticleTrack', 'Resize', 'off');
% Create an axes component that will contain the preview image
ax = axes('Parent', h, 'HandleVisibility', 'Callback', 'NextPlot', 'replacechildren', ...
    'DataAspectRatio', [1 1 1], 'Visible', 'off', 'Layer', 'top'); 

p2 = uipanel(h, 'Title', 'Capture Parameters', 'Units', 'pixels', 'Position', [0 0 dim(1) conf]);

% Contains ui elements
global ctrl;
ctrl = [];

ctrl(1) = uicontrol(p2, 'style', 'text', 'String', 'Exposure', 'Units', 'pixels', ...
    'Position', [40 150 100 20], 'HorizontalAlignment', 'left');
ctrl(2) = uicontrol(p2, 'style', 'popupmenu', 'String', ...
    ['1/10000|1/5000|1/2500|1/1111|1/526|1/256|1/128|1/64|1/32|1/16|1/8|1/4'], ...
    'Units', 'pixels', 'Position', [150 150 100 20], 'Callback', @exp_callback);
ctrl(3) = uicontrol(p2, 'style', 'text', 'String', 'Gain', 'SliderStep', [1 1], ... 
    'Units', 'pixels', 'Position', [40 110 100 20], 'HorizontalAlignment', 'left');
ctrl(4) = uicontrol(p2, 'style', 'slider', 'Max', 63, 'Min', 16, 'Value', 32, ...
    'Units', 'pixels', 'Position', [150 110 100 20], 'Callback', @gain_callback);
ctrl(5) = uicontrol(p2, 'style', 'pushbutton', 'Units', 'pixels', ...
    'Position', [40 20 100 20], 'Callback', @btn1_callback, 'String', 'Start Preview');
ctrl(6) = uicontrol(p2, 'style', 'pushbutton', 'Units', 'pixels', ...
    'Position', [40 20 100 20], 'Callback', @btn2_callback, 'String', 'Stop Preview', ...
    'Enable', 'off');
ctrl(7) = uicontrol(p2, 'style', 'text', 'String', 'Frame Rate', 'Units', 'pixels', ...
    'Position', [40 60 100 20], 'HorizontalAlignment', 'left');
ctrl(8) = uicontrol(p2, 'style', 'popupmenu', 'String', ['60.0|30.0|15.0|7.5|5'], ...
    'Units', 'pixels', 'Position', [40 90 120 20], 'Callback', @fps_callback);

ctrl(9) = uicontrol(p2, 'style', 'pushbutton', 'String', 'Set ROI', 'Position', ...
    [300 150 100 30], 'Callback', @roi_callback);

ctrl(10) = uicontrol(p2, 'style', 'pushbutton', 'String', 'Start Capture', 'Position', ...
    [300 100 100 30], 'Callback', @scap_callback);
ctrl(11) = uicontrol(p2, 'style', 'edit', 'Position', [500 150 100 30], 'Callback', @frms_callback);
ctrl(12) = uicontrol(p2, 'style', 'text', 'Position', [400 150 100 30], 'String', 'Frames to Capture');

set(ctrl(3:12), 'Visible', 'off');

align([ctrl(1) ctrl(3) ctrl(6)], 'Left', 'Fixed', 30);
align([ctrl(1:2) ctrl(9) ctrl(11:12)], 'Fixed', 40, 'None')
%align(ctrl(1:2), 'Fixed', 40, 'Middle');
%align(ctrl(3:4), 'Fixed', 40, 'Middle');
%align(ctrl(5:6), 'Fixed', 20, 'Middle');
%align(ctrl(7:8), 'Fixed', 20, 'Middle');
%align([ctrl(1:2) ctrl(9)], 'None', 'Middle');
%align([ctrl(9) ctrl(11:12)], 'Fixed', 20, 'Bottom');
%align([ctrl(1) ctrl(11:12)], 'None', 'Middle');
%align([ctrl(1) ctrl(3) ctrl(7)], 'Left', 'None');
% Make the figure visible
set(h, 'Visible', 'on');

% Declare Video Capture object global
%global v img;
%[v img] = video_init();
%set(ax, 'Units', 'pixels', 'Position', [dim(1)-vRes(1) (dim(2)-conf-vRes(2))/2+conf vRes]); 

set(ctrl(9), 'Enable', 'off');
end

% Start capture callback
function scap_callback(h,e)

end

function [v img] = video_init()
v = videoinput('winvideo', 1, 'Y800_744x480');
vRes = get(v, 'VideoResolution');
set(getselectedsource(v), 'ExposureMode', 'manual', 'GainMode', 'manual'); 
img = image('Parent', ax, 'CData', zeros(vRes(2), vRes(1)));
end

function exp_callback(h,e)
%EXP_CALLBACK Callback for the exposure control
global v;
val = get(h, 'Value');
% Exposure values run from -13 to -2, val is 1 to 12 
set(getselectedsource(v), 'Exposure', val-14);
end

function gain_callback(h, eventdata) 
%GAIN_CALLBACK Callback for the gain control
global v;
val = get(h, 'Value');
set(getselectedsource(v), 'Gain', val);
end

function btn1_callback(h, e)
global v ctrl img;
set(h, 'Enable', 'off');
set(ctrl(6), 'Enable', 'on');

preview(v,img);
end

function btn2_callback(h, e)
global v ctrl;
set(h, 'Enable', 'off');
set(ctrl(5), 'Enable', 'on');

stoppreview(v);
end

function roi_callback(h, e)
% Change the axes button down callback 
global img clk;
% Click Number
clk = 0;
set(img, 'ButtonDownFcn', {@roi_draw_callback});
end

function roi_draw_callback(h, e)
global clk pos;

%switch(clk)
%case 0:
%    pos = [

end

function new = process_clicks(pos)
    left = min([pos(1) pos(3)]);
    top = max([pos(2) pos(4)]);
    bot = min([pos(2) pos(4)]);
    right = max([pos(1) pos(3)]);
    new = [left top right bot];
end

function fps_callback(h, e)
global v;
s = getselectedsource(v);
% Get the structure that contains information about FrameRate
fr= propinfo(s, 'FrameRate');
val = get(h, 'Value');
s.FrameRate = fr.ConstraintValue{val};
end
