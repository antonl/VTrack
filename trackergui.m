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

        set_callbacks(gui);    

        %set(gui.Window, 'Visible', 'on');
    else
        try
            feval(func, gui);
        catch
            disp(lasterr);
        end
    end
end

function set_callbacks(gui)
%% Attach buttons and things to function callbacks

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

function v = create_video(aId, dId)
%% Initializes the video capture device using image acquisition toolkit
% aId is the adaptor id
% dId is the device id

if(nargin < 2) % Show dialog box 
    gui = AdaptorGUI;
    set(gui.Window, 'Visible', 'on');

    uiwait(gui.Window);
    
    v = gui.Video;

    close(gui.Window);
elseif(nargin == 2)
    try
        i_a = imaqhwinfo;

        if(numel(i_a.InstalledAdaptors) < 1)
            throw(MException('VideoError:NoAdaptorsFound', 'No Adaptors found!'));
        end

        i_b = imaqhwinfo(i_a.InstalledAdaptors{aId});

        if(numel(i_b.DeviceIDs) < 1)
            throw(MException('VideoError:NoDevicesInAdaptor', 'The selected adaptor "%s" does not contain any devices! \nIs the video camera connected?', i_a.InstalledAdaptors{aId}));
        end

        i_c = imaqhwinfo(i_a.InstalledAdaptors{aId}, i_b.DeviceIDs{dId});

        fprintf('Using adapter "%s", Device "%s"\n', i_a.InstalledAdaptors{aId}, i_c.DeviceName);
        fprintf('Supported formats: \n');

        for i = 1:numel(i_c.SupportedFormats);
            fprintf('%s\t', i_c.SupportedFormats{i});
            if(mod(i, 4) == 0)
                fprintf('\n');
            end
        end
        fprintf('\n');

        v = videoinput(i_a.InstalledAdaptors{aId}, i_b.DeviceIDs{dId});
    catch 
        throw(MException('VideoError:CannotCreateVideo', 'Could not open selected video device. Are you sure it exists?'));
    end
else
    throw(MException('VideoError:WrongNumberOfArguments', 'Got the wrong number of arguments!'));
end 

end
    

function h = AdaptorGUI(src, e, func)
    persistent adapt_gui;

    if nargin == 0
        adapt_gui = initialize_adaptor_select; % Create the gui
        
        i_a = imaqhwinfo;

        if(numel(i_a.InstalledAdaptors) < 1)
            throw(MException('VideoError:NoAdaptorsFound', 'No Adaptors found!'));
        end
   
        ad_str = i_a.InstalledAdaptors{1};
       
        if(numel(i_a.InstalledAdaptors) > 1)
            for i = 2:numel(i_a.InstalledAdaptors)
                ad_str = [ad_str '|' i_a.InstalledAdaptors{i}];
            end
        end

        set(adapt_gui.AdaptorCtrl, 'String', ad_str, 'Callback', {@AdaptorGUI @AdaptorCtrl_Callback});
        set(adapt_gui.DeviceCtrl, 'Callback', {@AdaptorGUI @DeviceCtrl_Callback}, 'Enable', 'off');
        set(adapt_gui.VideoModeCtrl, 'Callback', {@AdaptorGUI @VideoModeCtrl_Callback}, 'Enable', 'off');
        set(adapt_gui.DoneBtn, 'Callback', {@AdaptorGUI @DoneBtn_Callback}, 'Enable', 'off');

        setappdata(adapt_gui.Window, 'gui_struct', adapt_gui); % Store structure as object attached to figure
        % Callbacks update user data
    else
        try
            adapt_gui = getappdata(adapt_gui.Window, 'gui_struct');

            hgfeval(func, src, e, adapt_gui);
        catch e
            rethrow(e);
        end
    end

    h = adapt_gui;
end

function AdaptorCtrl_Callback(src, event, gui)
    %disp('In AdaptorCtrl');
    gui.aId = get(gui.AdaptorCtrl, 'Value');

    %disp(gui.aId)

    i_a = imaqhwinfo;
    gui.Adaptor = imaqhwinfo(i_a.InstalledAdaptors{gui.aId});

    %disp(gui.Adaptor)
    set(gui.DoneBtn, 'Enable', 'off');

    if(numel(gui.Adaptor.DeviceIDs) < 1)
        %disp('No devices available');
        set(gui.DeviceCtrl, 'String', 'None', 'Enable', 'off');
        return;
        % No devices available
    end
    
    dev_str = gui.Adaptor.DeviceInfo(1).DeviceName;

    if(numel(gui.Adaptor.DeviceIDs) > 1)
        for i = 2:numel(gui.Adaptor.DeviceIDs)
            dev = gui.Adaptor.DeviceInfo(i);
            dev_str = [dev_str '|' dev.DeviceName];
        end
    end

    set(gui.DeviceCtrl, 'String', dev_str, 'Enable', 'on');
    setappdata(gui.Window, 'gui_struct', gui);
end

function DeviceCtrl_Callback(src, event, gui)
    dId = get(gui.DeviceCtrl, 'Value');
    
    gui.dId = gui.Adaptor.DeviceIDs{dId};
    gui.Device = imaqhwinfo(gui.Adaptor.AdaptorName, gui.dId);
    
    set(gui.DoneBtn, 'Enable', 'off');

    if(numel(gui.Device.SupportedFormats) < 1)
        set(gui.VideoModeCtrl, 'Enable', 'off', 'String', 'None');
        return;
    end

    gui.Formats = gui.Device.SupportedFormats;

    format_str = gui.Formats{1};

    if(numel(gui.Formats) > 1)
        for i = 2:numel(gui.Formats)
            format_str = [format_str '|' gui.Formats{i}];
        end
    end

    set(gui.VideoModeCtrl, 'Enable', 'on', 'String', format_str);
    setappdata(gui.Window, 'gui_struct', gui);
end

function VideoModeCtrl_Callback(src, event, gui)
    fId = get(gui.VideoModeCtrl, 'Value');

    gui.SelectedFormat = gui.Formats{fId};
    
    set(gui.DoneBtn, 'Enable', 'on');

    setappdata(gui.Window, 'gui_struct', gui);
end

function DoneBtn_Callback(src, event, gui)
    gui.Video = videoinput(gui.Adaptor.AdaptorName, gui.dId, gui.SelectedFormat);
    setappdata(gui.Window, 'gui_struct', gui);
end

function g = initialize_adaptor_select 
%% Creates gui for selecting adaptor and gui
g = struct();

sz = get(0, 'ScreenSize');
dim = [250 170];

g.Window = figure('Visible', 'off', 'Position', [(sz(3)-dim(1))/2 (sz(4)-dim(2))/2 dim], ...
    'Toolbar', 'none', 'MenuBar', 'none', 'NumberTitle', 'off', 'Renderer', 'ZBuffer', ...
    'Name', 'Select Adaptor/Device', 'Resize', 'on', 'DoubleBuffer', 'on');

box = uiextras.VBox('Parent', g.Window);

g1 = uiextras.Grid('Parent', box);
uicontrol('Parent', g1, 'style', 'text', 'String', 'Adaptor', 'HorizontalAlignment', 'Left');
uicontrol('Parent', g1, 'style', 'text', 'String', 'Device', 'HorizontalAlignment', 'Left');
uicontrol('Parent', g1, 'style', 'text', 'String', 'Video Mode', 'HorizontalAlignment', 'Left');
g.AdaptorCtrl = uicontrol('Parent', g1, 'style', 'popupmenu', 'String', 'Empty');
g.DeviceCtrl = uicontrol('Parent', g1, 'style', 'popupmenu', 'String', 'Empty');
g.VideoModeCtrl = uicontrol('Parent', g1, 'style', 'popupmenu', 'String', 'Empty');
set(g1, 'RowSizes', [30 30 30], 'ColumnSizes', [-1 -1]);

g.DoneBtn = uicontrol('Parent', box, 'style', 'pushbutton', 'String', 'Done');

set(box, 'Sizes', [-1 30], 'Padding', 20);
end
