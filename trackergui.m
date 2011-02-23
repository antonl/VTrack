function TrackerGUI(src, e, func)
%% A single entry-point for the gui code. Every callback is called through this function
% Procedure taken from mathworks blog on the switchyard pattern.
% http://www.mathworks.com/company/newsletters/news_notes/win00/prog_patterns.html

    persistent gui; % Contains structure with handles to important bits 

    % Make sure multiple instances aren't run at the same time
    if(nargin == 0 & isfield(gui, 'Window') & ishandle(gui.Window))
        throw(MException('TrackerGUI:MultipleInstances', 'Cannot run multiple instances of this GUI'));
    end

    if nargin == 0
        gui = initialize; % Create the gui
        
        try
            create_video(gui.Window);
        catch e
            fprintf('Failed to create video capture device handle.\n');
            close(gui.Window);
            rethrow(e);
        end

        set_callbacks(gui);    

        set(gui.Window, 'CloseRequestFcn', {@TrackerGUI @TrackerGUIDelete_Callback});
        set(gui.Window, 'Visible', 'on');
    else
        gui = getappdata(gui.Window, 'gui_struct');
        
        try
            hgfeval(func, src, e, gui);
        catch e
            rethrow(e);
        end
    end
end

function TrackerGUIDelete_Callback(src, e, gui)
    if(isappdata(gui.Window, 'video'))
        v = getappdata(gui.Window, 'video');
        stop(v);
        
        if(strcmp(get(v, 'Previewing'), 'on'))
            close(gui.PreviewFig);
        end
    end

    imaqreset;
    delete(src);
end

function set_callbacks(gui)
%% Attach buttons and things to function callbacks

% Attach preview window
v = getappdata(gui.Window, 'video'); % Get video object handle
input = getselectedsource(v);

pr = propinfo(input);

% Enable Gain, Exposure, and FrameRate controls, and set their callbacks
if(isfield(pr, 'Gain'))
    set(input, 'GainMode', 'Manual');
    set(gui.GainCtrl, 'Enable', 'on', 'Callback', {@TrackerGUI @GainCtrl_Callback});
else
    set(gui.GainCtrl, 'Enable', 'off');
end

if(isfield(pr, 'Exposure'))
    set(input, 'ExposureMode', 'Manual');
    set(gui.ExposureCtrl, 'Enable', 'on', 'Callback', {@TrackerGUI @ExposureCtrl_Callback});
else
    set(gui.ExposureCtrl, 'Enable', 'off');
end

if(isfield(pr, 'FrameRate'))
    set(gui.FrameRateCtrl, 'Enable', 'on', 'Callback', {@TrackerGUI @FrameRateCtrl_Callback});
else
    set(gui.FrameRateCtrl, 'Enable', 'off');
end

% Start Preview Callback 
set(gui.StartPreviewBtn, 'Callback', {@TrackerGUI @StartPreviewBtn_Callback});

setappdata(gui.Window, 'gui_struct', gui);
end

function StartPreviewBtn_Callback(src, e, gui)

if(~isappdata(gui.Window, 'video'))
    throw(MException('VideoError:VideoNotExist', 'Should not be previewing on a nonexistent videoinput object!'));
else
    v = getappdata(gui.Window, 'video');
end

if(strcmp(get(v, 'Previewing'), 'on')) % Preview is Running
    %closepreview(v); % This is done in the close fcn for this figure
    close(gui.PreviewFig);
    set(gui.StartPreviewBtn, 'String', 'Start Preview');
    setappdata(gui.Window, 'gui_struct', gui);
else
%    margins = [20 20];
%    sz = get(0, 'ScreenSize');
    
%    vRes = get(v, 'VideoResolution');

%    dim = vRes + margins;

%    gui.PreviewFig = figure('Visible', 'off', 'Name', 'Preview', 'NumberTitle', 'off', 'MenuBar', 'none', ...
%        'CloseRequestFcn', {@TrackerGUI @PreviewCloseFcn}, 'Resize', 'off');
    %ax = axes('Parent', gui.PreviewFig, 'XLim', [0 vRes(1)], 'YLim', [0 vRes(2)]);
    %gui.PreviewImage = image('Parent', ax, 'CData', zeros(vRes(2), vRes(1), 1));
    %truesize(gui.PreviewFig, [vRes(2) vRes(1)]);

    % Create image for preview callback
    %setappdata(gui.PreviewImage, 'UpdatePreviewWindowFcn', @VideoPreview_Callback);
    
    %preview(v, gui.PreviewImage);
    gui.PreviewImage = preview(v);

    gui.PreviewFig = ancestor(gui.PreviewImage, 'figure');

    set(gui.PreviewFig, 'CloseRequestFcn', {@TrackerGUI @PreviewCloseFcn}, 'Resize', 'off');
    set(gui.StartPreviewBtn, 'String', 'Stop Preview');
    %set(gui.PreviewFig, 'Visible', 'on');
    
    %set(ax, 'Visible', 'on', 'Color', 'black');
    setappdata(gui.Window, 'gui_struct', gui);
end
end

function GainCtrl_Callback(src, e, gui)
    v = getappdata(gui.Window, 'video');
    
    val = get(gui.GainCtrl, 'Value');
    
    set(getselectedsource(v), 'Gain', val);
end

function ExposureCtrl_Callback(src, e, gui)
    v = getappdata(gui.Window, 'video');

    val = get(gui.ExposureCtrl, 'Value');

    % Exposure values run from -13 to -2, val is 1 to 12 
    set(getselectedsource(v), 'Exposure', val-14);
end

function FrameRateCtrl_Callback(src, e, gui)
    v = getappdata(gui.Window, 'video');

    val = get(gui.ExposureCtrl, 'Value');
    
    % Get the structure that contains information about FrameRate
    fr= propinfo(getselectedsource(v), 'FrameRate');
    set(getselectedsource(v), 'FrameRate', fr.ConstraintValue{val});
end

function PreviewCloseFcn(src, e, gui)
    % Somebody wants the preview window closed
    if(~isappdata(gui.Window, 'video'))
        throw(MException('VideoError:VideoNotExist', 'Should not be previewing on a nonexistent videoinput object!'));
    else
        v = getappdata(gui.Window, 'video');
    end

    if(strcmp(get(v, 'Previewing'), 'on')) % Preview is Running
        closepreview(v);
    end
   
    set(gui.StartPreviewBtn, 'String', 'Start Preview');
    %delete(src);
end

function VideoPreview_Callback(v, e, hImage)
%% Callback called when video is open
    set(hImage, 'CData', e.Data);
end

function g = initialize
%% Creates components for default layout of the gui
sz = get(0, 'ScreenSize');
dim = [250 500]; % Size of figure window

% Hold handles in a struct
g = struct();

% Main Window
g.Window = figure('Visible', 'off', 'Position', [(sz(3)-dim(1))/2 (sz(4)-dim(2))/2 dim], ...
    'Toolbar', 'none', 'MenuBar', 'none', 'NumberTitle', 'off', ...
    'Name', 'ParticleTrack', 'Resize', 'off');

p1 = uiextras.BoxPanel('Parent', g.Window, 'Title', 'Capture Parameters');

g1 = uiextras.Grid('Parent', p1, 'Padding', 10, 'Spacing', 5);

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
g.ExposureCtrl = uicontrol('Parent', g1, 'style', 'popupmenu', 'String', ['1/10000|1/5000|1/2500|1/1111|1/526|1/256|1/128|1/64|1/32|1/16|1/8|1/4'], 'HorizontalAlignment', 'Right', 'Enable', 'off');
g.GainCtrl = uicontrol('Parent', g1, 'style', 'slider', 'Max', 63, 'Min', 16, 'Value', 32, 'SliderStep', [1 1], 'Position', [0 0 1 0.3], 'Enable', 'off');
g.FrameRateCtrl = uicontrol('Parent', g1, 'style', 'popupmenu', 'String', ['60.0|30.0|15.0|7.5|5'], 'Enable', 'off');
g.ContrastCtrl = uicontrol('Parent', g1, 'style', 'checkbox', 'String', 'Contrast Stretch', 'HorizontalAlignment', 'Right');

uiextras.Empty('Parent', g1);

uicontrol('Parent', g1, 'style', 'checkbox', 'String', 'Tracking', 'HorizontalAlignment', 'Right');
g.SetKernBtn = uicontrol('Parent', g1, 'style', 'pushbutton', 'String', 'Set Kernel');
g.FramesToCapCtrl = uicontrol('Parent', g1, 'style', 'edit', 'String', '30');
uiextras.Empty('Parent', g1);
uiextras.Empty('Parent', g1);

set(g1, 'RowSizes', [30 30 30 30 30 30 30 30 -1 30], 'ColumnSizes', [-1 -1]);
% End Grid
end

function v = create_video(h, aId, dId)
%% Initializes the video capture device using image acquisition toolkit and stores video object in h appdata
% h is the Main Figure Handle
% aId is the adaptor id
% dId is the device id

if(nargin == 1) % Show dialog box 
    gui = AdaptorGUI;
    set(gui.Window, 'Visible', 'on');
    % Upon a close request, save the gui structure in 
    set(gui.Window, 'CloseRequestFcn', {@AdaptorGUI_CloseCallback gui.Window h}); 

    uiwait(gui.Window);
   
    if(~isappdata(h, 'video'))
        % Video was not successfully set
        throw(MException('VideoError:SelectionCanceled', 'No device was selected through the GUI. Did you cancel the dialog?'));
    end
elseif(nargin == 3)
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
        setappdata(h, 'video', v);
    catch 
        throw(MException('VideoError:CannotCreateVideo', 'Could not open selected video device. Are you sure it exists?'));
    end
else
    throw(MException('VideoError:WrongNumberOfArguments', 'Got the wrong number of arguments!'));
end 

end
    
function AdaptorGUI_CloseCallback(src, e, adapt_h, main_h)
%% Close function for the adaptor device chooser gui
% Copies the created video structure from main_gui
try
    gui_struct = getappdata(adapt_h, 'gui_struct');
catch
    delete(src); % Not actually sure if src is the figure. Let's hope...
end

if(isfield(gui_struct, 'Video'))
    % Video was successfully created
    % Copy it to main gui appdata
    setappdata(main_h, 'video', gui_struct.Video);
end
delete(adapt_h); % Actually close the figure
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
    close(gui.Window);
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
