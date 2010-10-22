function [v f] = prac()
% Contains position of the screen as [pos_left pos_right width height]
sz = get(0, 'ScreenSize');

% Default size of figure window
dim = [800 700];
conf = 200;

% Create a hidden figure that will be populated with ui controls.
h = figure('Visible', 'off', 'Position', [(sz(3)-dim(1))/2 (sz(4)-dim(2))/2 dim], ...
    'Toolbar', 'none', 'MenuBar', 'none', 'NumberTitle', 'off', 'Renderer', 'ZBuffer', ...
    'Name', 'ParticleTrack', 'Resize', 'off', 'DeleteFcn', @destroy_callback, ...
    'DoubleBuffer', 'on');
vbox = uiextras.VBox('Parent', h);

ax = axes('Parent', vbox, 'HandleVisibility', 'Callback', ...
    'Visible', 'off');
p = uiextras.Panel('Parent', vbox, 'Title', 'Capture Parameters');
set(vbox, 'Sizes', [-1 conf]);

vbox2 = uiextras.VBox('Parent', p);
uiextras.Empty('Parent', vbox2);
grid = uiextras.Grid('Parent', vbox2, 'Spacing', 10);
uiextras.Empty('Parent', vbox2);
set(vbox2,'Sizes', [15 -1 15]); 

% Array to hold ui components
global ctrl;

ctrl = [];
% Fill the first column with empty space 
uiextras.Empty('Parent', grid);
uiextras.Empty('Parent', grid);
uiextras.Empty('Parent', grid);
uiextras.Empty('Parent', grid);
uiextras.Empty('Parent', grid);

% Labels
ctrl(1) = uicontrol('Parent', grid, 'style', 'text', 'String', 'Exposure', ...
    'HorizontalAlignment', 'left');
ctrl(2) = uicontrol('Parent', grid, 'style', 'text', 'String', 'Gain', ...
    'HorizontalAlignment', 'left');
ctrl(3) = uicontrol('Parent', grid, 'style', 'text', 'String', 'Frame Rate', ...
    'HorizontalAlignment', 'left');
uiextras.Empty('Parent', grid);
uiextras.Empty('Parent', grid);

% Edit, slider controls
ctrl(4) = uicontrol('Parent', grid, 'style', 'popupmenu', 'String', ...
    ['1/10000|1/5000|1/2500|1/1111|1/526|1/256|1/128|1/64|1/32|1/16|1/8|1/4'], ...
    'Callback', @exp_callback);
ctrl(5) = uicontrol('Parent', grid, 'style', 'slider', 'Max', 63, 'Min', 16, ...
    'Value', 32, 'SliderStep', [1 1], 'Position', [0 0 1 0.3], 'Callback', @gain_callback);
ctrl(6) = uicontrol('Parent', grid, 'style', 'popupmenu', 'String', ['60.0|30.0|15.0|7.5|5'], ...
    'Callback', @fps_callback);
btnbox = uiextras.HButtonBox('Parent', grid, 'VerticalAlignment', 'Top', 'Spacing', 10);
ctrl(7) = uicontrol('Parent', btnbox, 'style', 'pushbutton', 'Callback', {@btn1_callback}, ...
    'String', 'Start Preview');
ctrl(8) = uicontrol('Parent', btnbox, 'style', 'pushbutton', 'Callback', {@btn2_callback}, ...
    'String', 'Stop Preview', 'Enable', 'off');
uiextras.Empty('Parent', grid);

% More spacers
uiextras.Empty('Parent', grid);
uiextras.Empty('Parent', grid);
uiextras.Empty('Parent', grid);
uiextras.Empty('Parent', grid);
uiextras.Empty('Parent', grid);

% Capture Labels
ctrl(9) = uicontrol('Parent', grid, 'style', 'text', 'String', '# of Frames to Cap', ...
    'HorizontalAlignment', 'left');
%uiextras.Empty('Parent', grid);
btnbox2 = uiextras.HButtonBox('Parent', grid, 'VerticalAlignment', 'Top', 'Spacing', 10);
ctrl(16) = uicontrol('Parent', btnbox2, 'style', 'pushbutton', 'Callback', {@set_kernel_callback, ax}, ...
    'String', 'Kernel');
ctrl(17) = uicontrol('Parent', btnbox2, 'style', 'pushbutton', 'Callback', {@set_roi_callback, ax}, ...
    'String', 'ROI');
ctrl(14) = uicontrol('Parent', grid, 'style', 'text', 'String', 'Frames Processed', ...
    'HorizontalAlignment', 'left');
ctrl(10) = uicontrol('Parent', grid, 'style', 'text', 'String', 'Resolution', ...
    'HorizontalAlignment', 'left');
uiextras.Empty('Parent', grid);

% Capture Controls
ctrl(11) = uicontrol('Parent', grid, 'style', 'edit', 'Callback', @framestocap_callback, ...
    'String', '30');
btnbx2 = uiextras.VButtonBox('Parent', grid, 'ButtonSize', [100 30], 'VerticalAlignment', 'Top');
ctrl(12) = uicontrol('Parent', btnbx2, 'style', 'pushbutton', 'Callback', @startcap_callback, ...
    'String', 'Capture!');
ctrl(15) = uicontrol('Parent', grid, 'style', 'text', 'String', '0', 'HorizontalAlignment', 'left');
ctrl(13) = uicontrol('Parent', grid, 'style', 'text', 'String', 'NxN');
uiextras.Empty('Parent', grid);

% Final Spacers
uiextras.Empty('Parent', grid);
uiextras.Empty('Parent', grid);
uiextras.Empty('Parent', grid);
uiextras.Empty('Parent', grid);
uiextras.Empty('Parent', grid);

set(grid, 'ColumnSizes', [20 70 170 -1 100 100 80], 'RowSizes', [30 30 30 30 -1]);
global v img;
try
    v = vid_init();
    vRes = get(v, 'VideoResolution');
    set(ctrl(13), 'String', sprintf('%dx%d', vRes(1), vRes(2)));
    img = image('Parent', ax, 'CData', zeros(vRes(2), vRes(1), 3), 'Visible', 'on');
    setappdata(img, 'UpdatePreviewWindowFcn', @preview_callback);
catch e
    disp(e.identifier);
    rethrow(e);
    %error('pt_track:top:FailVideoInit', 'Could not initialize video. Please check settings.');
end

set(h, 'Visible', 'on');
end

function v = vid_init()
v = videoinput('winvideo', 1, 'Y800_744x480');
vRes = get(v, 'VideoResolution');
%set(v, 'FrameGrabInterval', 10);
set(getselectedsource(v), 'ExposureMode', 'manual', 'GainMode', 'manual');
set(v, 'TimerFcn', @plot_callback, 'TimerPeriod', 0.5);
global roi_pos;
roi_pos = [0 0 vRes(1) vRes(2)];
end

function startcap_callback(h, e)
global v roi_pos ctrl total_processed rect_kernel rect_roi;

if(~isempty(rect_kernel) && ~isempty(rect_roi))
    rect_kernel.setResizable(false);
    rect_roi.setResizable(false);
end

filename = [datestr(now, 'yyyymmdd-HHMMSS') '.avi'];


vid_log = avifile(filename);
vid_log.Colormap = gray(256);
total_processed = 0;
set(ctrl(15), 'String', '0');
set(v, 'LoggingMode', 'disk&memory', 'DiskLogger', vid_log, 'StopFcn', @stop_callback);
start(v);
set(h, 'Enable', 'off');
end

function preview_callback(v, event, hImage)
%event.Data = imcomplement(event.Data);
set(hImage, 'CData', event.Data);
end

function plot_callback(v, event) 
global total_processed;

ac = get(v, 'FramesAcquired');
av = get(v, 'FramesAvailable');

[data timing] = getdata(v, av);

% Data analysis section %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global rect_kernel rect_roi;
if(~isempty(rect_kernel) && ~isempty(rect_roi))
    for i = 1:5:av
        roi = imcrop(data(:,:,1,i), rect_roi.getPosition);
        kern = imcrop(data(:,:,1,i), rect_kernel.getPosition);

        dat = normxcorr2(roi, kern);
        [max_cc, imax] = max(abs(dat(:)));
        [ypeak, xpeak] = ind2sub(size(dat),imax(1));
        
        figure, hold on, imshow(roi);
        scatter(xpeak, ypeak);
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

total_processed = total_processed + av;
global ctrl;
set(ctrl(15), 'String', num2str(total_processed));
end


function mem_mon(v, e)
end

function stop_callback(v, e)
plot_callback(v,e);
global ctrl rect_kernel rect_roi;
s = close(v.DiskLogger);
set(ctrl(12), 'Enable', 'on');
if(~isempty(rect_kernel) && ~isempty(rect_roi))
    rect_kernel.setResizable(true);
    rect_roi.setResizable(true);
end
end

function destroy_callback(h, e)
global v;
delete(v);
clear v;
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
set(ctrl(8), 'Enable', 'on');
preview(v,img);
end

function btn2_callback(h, e)
global v ctrl;
set(h, 'Enable', 'off');
set(ctrl(7), 'Enable', 'on');

stoppreview(v);
end

function framestocap_callback(h, e)
global v;
frm = str2num(get(h, 'String'));
if(~isnan(frm))
    set(v, 'FramesPerTrigger', frm)
else
    warning('Must have an integer value for frames to cap');
end
end

function set_kernel_callback(h, e, ax)
global rect_kernel;
if(~isempty(rect_kernel))
    rect_kernel.delete;
end
r = imrect(ax);
r.setColor('r');
r.addNewPositionCallback(@roi_pos_callback);
rect_kernel = r;
end

function set_roi_callback(h, e, ax)
% Change the axes button down callback 
% Click Number
%set(img, 'ButtonDownFcn', {@roi_draw_callback});
global rect_roi;
if(~isempty(rect_roi))
    rect_roi.delete;
end
r = imrect(ax);
r.setColor('g');
r.addNewPositionCallback(@roi_pos_callback);
rect_roi = r;
end

function roi_pos_callback(pos, str)
end
function kernel_pos_callback(pos, str)
end

function fps_callback(h, e)
global v;
s = getselectedsource(v);
% Get the structure that contains information about FrameRate
fr= propinfo(s, 'FrameRate');
val = get(h, 'Value');
s.FrameRate = fr.ConstraintValue{val};
end
