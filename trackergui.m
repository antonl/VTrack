function TrackerGUI(func)
%% A single entry-point for the gui code. Every callback is called through this function
% Procedure taken from mathworks blog on the switchyard pattern.
% http://www.mathworks.com/company/newsletters/news_notes/win00/prog_patterns.html

    persistent gui; % Contains structure with handles to important bits 

    if nargin == 0
        gui = initialize; % Create the gui
        
        try
            gui.Video = create_video;
        catch
            fprintf('Failed to create video capture device handle.\n\n');
            disp(lasterr);
            return
        end

        %set_callbacks;    

        set(gui.Window, 'Visible', 'on');
    else
        try
            feval(func, gui);
        catch
            disp(lasterr);
        end
    end
end

function g = initialize
%% Creates components for default layout of the gui
%
sz = get(0, 'ScreenSize');
dim = [1000 500]; % Size of figure window

% Hold handles in a struct
g = struct();

% Main Window
g.Window = figure('Visible', 'off', 'Position', [(sz(3)-dim(1))/2 (sz(4)-dim(2))/2 dim], ...
    'Toolbar', 'none', 'MenuBar', 'none', 'NumberTitle', 'off', 'Renderer', 'ZBuffer', ...
    'Name', 'ParticleTrack', 'Resize', 'on', 'DoubleBuffer', 'on');

hbox1 = uiextras.HBox('Parent', g.Window);

% Video Box
bp1 = uiextras.BoxPanel('Parent', hbox1, 'Title', 'Video Preview');

g.Preview = axes('Parent', bp1, 'XLim', [0 800], 'YLim', [0 600], ...
    'ActivePositionProperty', 'Position');
%uiextras.Empty('Parent', hbox1);
p1 = uiextras.BoxPanel('Parent', hbox1, 'Title', 'Capture Parameters');
set(hbox1, 'Sizes', [-5 -2]);

g1 = uiextras.Grid('Parent', p1);

% Column 1 of Grid
uicontrol('Parent', g1, 'style', 'text', 'String', 'Exposure', 'HorizontalAlignment', 'Left');
uicontrol('Parent', g1, 'style', 'text', 'String', 'Gain','HorizontalAlignment', 'Left');
uicontrol('Parent', g1, 'style', 'text', 'String', 'Frame Rate', 'HorizontalAlignment', 'Left');
g.StartPreviewBtn = uicontrol('Parent', g1, 'style', 'pushbutton', 'String', 'Start Preview');
uiextras.Empty('Parent', g1);

uicontrol('Parent', g1, 'style', 'text', 'String', 'Tracking/Capture Settings:', 'HorizontalAlignment', 'Left');
g.SetRoiBtn = uicontrol('Parent', g1, 'style', 'pushbutton', 'String', 'Set ROI');
uicontrol('Parent', g1, 'style', 'text', 'String', 'Frames to Cap', 'HorizontalAlignment', 'Left');

uiextras.Empty('Parent', g1);
g.CaptureBtn = uicontrol('Parent', g1, 'style', 'pushbutton', 'String', 'Capture');

% Column 2 of Grid
g.ExposureCtrl = uicontrol('Parent', g1, 'style', 'popupmenu', 'String', ['1/10000|1/5000|1/2500|1/1111|1/526|1/256|1/128|1/64|1/32|1/16|1/8|1/4'], 'HorizontalAlignment', 'Right');
g.GainCtrl = uicontrol('Parent', g1, 'style', 'slider', 'Max', 63, 'Min', 16, 'Value', 32, 'SliderStep', [1 1], 'Position', [0 0 1 0.3]);
g.FramerateCtrl = uicontrol('Parent', g1, 'style', 'popupmenu', 'String', ['60.0|30.0|15.0|7.5|5']);
g.ContrastCtrl = uicontrol('Parent', g1, 'style', 'checkbox', 'String', 'Contrast Stretch', 'HorizontalAlignment', 'Right');

uiextras.Empty('Parent', g1);

uicontrol('Parent', g1, 'style', 'checkbox', 'String', 'Tracking', 'HorizontalAlignment', 'Right');
g.SetKernBtn = uicontrol('Parent', g1, 'style', 'pushbutton', 'String', 'Set Kernel');
g.FramesToCapCtrl = uicontrol('Parent', g1, 'style', 'edit', 'String', '30');
uiextras.Empty('Parent', g1);
uiextras.Empty('Parent', g1);

set(g1, 'RowSizes', [30 30 30 30 30 30 30 30 -1 30], 'ColumnSizes', [-1 -1]);
% End Grid

%set(g.Window, 'Visible', '');
end

function v = create_video
%% Initializes the video capture device using image acquisition toolkit

i_a = imaqhwinfo;
i_b = imaqhwinfo(i_a.InstalledAdaptors{1});
i_c = imaqhwinfo(i_a.InstalledAdaptors{1}, i_b.DeviceIDs{1});

fprintf('Using adapter "%s", Device "%s"\n', i_a.InstalledAdaptors{1}, i_c.DeviceName);
fprintf('Supported formats: \n');

for i = 1:numel(i_c.SupportedFormats);
    fprintf('%s\t', i_c.SupportedFormats{i});
    if(mod(i, 4) == 0)
        fprintf('\n');
    end
end
fprintf('\n');

v = videoinput(i_a.InstalledAdaptors{1}, i_b.DeviceIDs{1});
end

