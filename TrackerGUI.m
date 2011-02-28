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
            delete(gui.Window);
            imaqreset;
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
    if(isfield(gui, 'Window') & isappdata(gui.Window, 'video'))
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
    hgfeval(@GainCtrl_Callback, [], [], gui);
else
    set(gui.GainCtrl, 'Enable', 'off');
end

if(isfield(pr, 'Exposure'))
    set(input, 'ExposureMode', 'Manual');
    set(gui.ExposureCtrl, 'Enable', 'on', 'Callback', {@TrackerGUI @ExposureCtrl_Callback});
    hgfeval(@ExposureCtrl_Callback, [], [], gui);
else
    set(gui.ExposureCtrl, 'Enable', 'off');
end

if(isfield(pr, 'FrameRate'))
    set(gui.FrameRateCtrl, 'Enable', 'on', 'Callback', {@TrackerGUI @FrameRateCtrl_Callback});
    hgfeval(@FrameRateCtrl_Callback, [], [], gui);
else
    set(gui.FrameRateCtrl, 'Enable', 'off');
end

set(gui.SetRoiBtn, 'Callback', {@TrackerGUI @SetRoiBtn_Callback});
set(gui.SetKernBtn, 'Callback', {@TrackerGUI @SetKernBtn_Callback});
set(gui.FramesToCapCtrl, 'Callback', {@TrackerGUI @FramesToCapCtrl_Callback});
set(gui.TrackingCtrl, 'Callback', {@TrackerGUI @TrackingCtrl_Callback});

% Start Preview Callback 
set(gui.StartPreviewBtn, 'Callback', {@TrackerGUI @StartPreviewBtn_Callback});

setappdata(gui.Window, 'gui_struct', gui);
end

function SetRoiBtn_Callback(src, e, gui)
if(~(get(gui.TrackingCtrl, 'Value') == 1))
    return % Not tracking, shouldn't be here
end

try
    fn = makeConstrainToRectFcn('imrect', get(gui.Axes, 'XLim'), get(gui.Axes, 'YLim'));
    roi = imrect(gui.Axes, 'PositionConstraintFcn', fn);

    if(~isfield(gui, 'RoiRect') || (isfield(gui, 'RoiRect') & ~ishandle(gui.RoiRect)))
        gui.RoiRect = rectangle('Parent', gui.Axes, 'Position', round(roi.getPosition), 'EdgeColor', 'g');
    else
        set(gui.RoiRect, 'Position', round(roi.getPosition));
    end

    delete(roi);
    setappdata(gui.Window, 'gui_struct', gui);
catch e
    if(ishandle(roi))
        delete(roi); % perhaps the person turned off tracking without drawing ROI
    end
    rethrow(e);
end
end

function SetKernBtn_Callback(src, e, gui)
if(~(get(gui.TrackingCtrl, 'Value') == 1))
    return % Not tracking, shouldn't be here
end

try
    fn = makeConstrainToRectFcn('imrect', get(gui.Axes, 'XLim'), get(gui.Axes, 'YLim'));
    roi = imrect(gui.Axes, 'PositionConstraintFcn', fn);

    if(~isfield(gui, 'KernRect') || (isfield(gui, 'KernRect') & ~ishandle(gui.KernRect)))
        gui.KernRect = rectangle('Parent', gui.Axes, 'Position', round(roi.getPosition), 'EdgeColor', 'r');
    else
        set(gui.KernRect, 'Position', round(roi.getPosition));
    end

    setappdata(gui.Window, 'gui_struct', gui);
    delete(roi);
catch e
    if(ishandle(roi))
        delete(roi); % perhaps the person turned off tracking without drawing ROI
    end

    rethrow(e);
end
end

function StartPreviewBtn_Callback(src, e, gui)

if(~isappdata(gui.Window, 'video'))
    throw(MException('VideoError:VideoNotExist', 'Should not be previewing on a nonexistent videoinput object!'));
else
    v = getappdata(gui.Window, 'video');
end

if(strcmpi(get(v, 'Previewing'), 'on')) % Preview is Running
    %closepreview(v); % This is done in the close fcn for this figure
    close(gui.PreviewFig);

    set(gui.TrackingCtrl, 'Value', 0);
    set(gui.SetKernBtn, 'Enable', 'off');
    set(gui.SetRoiBtn, 'Enable', 'off');
    set(gui.StartPreviewBtn, 'String', 'Start Preview');
    setappdata(gui.Window, 'gui_struct', gui);
else

    gui = create_preview(gui); % Create a preview window

    set(gui.StartPreviewBtn, 'String', 'Stop Preview');
    setappdata(gui.PreviewImage, 'UpdatePreviewWindowFcn', @VideoPreview_Callback);
    
    set(gui.PreviewFig, 'Visible', 'on');
    
    setappdata(gui.Window, 'gui_struct', gui);
    setappdata(gui.PreviewImage, 'main_h', gui.Window);

    preview(v, gui.PreviewImage);
end
end

function gui_struct = create_preview(gui)
    v = getappdata(gui.Window, 'video');
    vRes = get(v, 'VideoResolution');
    sz = get(0, 'ScreenSize');

    % Height of status bar in characters
    statusCharHeight = 1.5;

    timeSecWidth = 20;
    resSecWidth = 20;
    stretchSecWidth = 30;

    stretchXOffset = timeSecWidth + resSecWidth;

    normText = [0 0 1 1];

    % Figure to hold preview image
    gui.PreviewFig = figure('Visible', 'off', 'MenuBar', 'none', 'Toolbar', 'none', 'NumberTitle', 'off', 'Name', 'Preview', ...
        'CloseRequestFcn', {@TrackerGUI @PreviewCloseFcn}, 'Resize', 'off', 'Units', 'characters', 'Renderer', 'zbuffer', ...
        'DoubleBuffer', 'off');
    
    figPos = get(gui.PreviewFig, 'Position');

    % Panel to hold status information
    gui.StatusPanel = uipanel('Parent', gui.PreviewFig, 'Units', 'characters', 'BorderType', 'none', ...
        'Position', [0 0 figPos(3) statusCharHeight]);
    
    gui.TimePanel = uipanel('Parent', gui.StatusPanel, 'Units', 'characters', 'Position', [0 0 timeSecWidth statusCharHeight]);
    gui.TimeField = uicontrol('Parent', gui.TimePanel, 'Style', 'text', 'String', 'Time Stamp', 'Units', 'normalized', ...
       'Position', normText);

    gui.ResPanel = uipanel('Parent', gui.StatusPanel, 'Units', 'characters', 'Position', [timeSecWidth 0 resSecWidth statusCharHeight]);
    gui.ResField = uicontrol('Parent', gui.ResPanel, 'Style', 'text', 'String', 'Resolution', 'Units', 'normalized', ...
        'Position', normText);

    gui.StretchPanel = uipanel('Parent', gui.StatusPanel, 'Units', 'characters', 'Position', ...
        [stretchXOffset 0 stretchSecWidth statusCharHeight]);
    gui.StretchField = uicontrol('Parent', gui.StretchPanel, 'Style', 'text', 'String', 'Contrast Stretching Off', 'Units', 'normalized', ...
        'Position', normText);

    % Panel to hold preview image
    gui.ImagePanel = uipanel('Parent', gui.PreviewFig, 'Units', 'characters', 'BorderType', 'none', ...
        'Position', [0 statusCharHeight figPos(3) figPos(4)-statusCharHeight]);

    set(gui.ImagePanel, 'Units', 'normalized');

    gui.Axes = axes('Parent', gui.ImagePanel);

    data = zeros(vRes(2), vRes(1), 1);

    gui.PreviewImage = image(data, 'Parent', gui.Axes);

   
    set(gui.Axes, 'Units', 'pixels');
    
    set(gui.Axes, 'XLim', [1 vRes(1)], 'YLim', [1 vRes(2)], 'Position', [0 0 vRes(1) vRes(2)]);

    % Resize figure so that no rescaling needs to be done
    set(gui.StatusPanel, 'Units', 'pixels');
    statusPos = get(gui.StatusPanel, 'Position');
    set(gui.StatusPanel, 'Units', 'normalized');

    set(gui.PreviewFig, 'Units', 'pixels');
    figWidth = vRes(1);
    figHeight = vRes(2) + statusPos(4);
    set(gui.PreviewFig, 'Position', [(sz(3)-figWidth)/2 (sz(4)-figHeight)/2 figWidth figHeight]);

    set(gui.Axes, 'Visible', 'on', 'CLimMode', 'manual', 'CLim', [0 255],...
        'ALimMode', 'manual', 'XLimMode', 'manual', 'YLimMode', 'manual', ...
        'ZLimMode', 'manual', 'XTickMode', 'manual', 'YTickMode', 'manual', ...
        'ZTickMode', 'manual');
    setappdata(gui.Window, 'gui_struct', gui);
    gui_struct = gui;
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

    val = get(gui.FrameRateCtrl, 'Value');
    
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
    delete(src);
end

function VideoPreview_Callback(v, e, hImage)
%% Callback called when video is open
    main_h = getappdata(hImage, 'main_h');
    gui = getappdata(main_h, 'gui_struct');

    set(gui.TimeField, 'String', e.Timestamp);
    
    if(~strcmpi(e.Resolution, '')) % Apparently sometimes imaq forgets to set resolution?!
        set(gui.ResField, 'String', e.Resolution);
    end
    
    try
        if(get(gui.ContrastCtrl, 'Value') == 1)
            set(gui.StretchField, 'String', 'Contrast Stretching On');
            data = histeq(e.Data, 64);
        else
            set(gui.StretchField, 'String', 'Contrast Stretching Off');
            data = e.Data;
        end

        if(get(gui.TrackingCtrl,'Value') == 1)
            % Make sure rectangles exist
            if(validate_roi_kern(gui))
                % Do particle tracking
                rpos = get(gui.RoiRect, 'Position');
                kpos = get(gui.KernRect, 'Position');

                roi = e.Data(rpos(2):rpos(2)+rpos(4), rpos(1):rpos(1)+rpos(3)); 
                kern = e.Data(kpos(2):kpos(2)+kpos(4), kpos(1):kpos(1)+kpos(3)); 
                
                pos = get_approx_position(roi, kern);

                tstr = sprintf('(%3.1f, %3.1f)', pos(1), pos(2));


                if(isfield(gui, 'TrackingLabel') & ishandle(gui.TrackingLabel))
                    set(gui.TrackingLabel, 'String', tstr, 'Position', [kpos(1) kpos(2)+kpos(4)]);
                else
                    gui.TrackingLabel = text('Parent', gui.Axes, 'VerticalAlignment', 'top', ...
                        'String', tstr, 'Color', [0.2 0.2 0.2], 'Position', [kpos(1) kpos(2)+kpos(4)],...
                        'BackgroundColor', [0 0.9 0.2]);
                    setappdata(gui.Window, 'gui_struct', gui);
                end
            end
        end
    catch err
        data = e.Data;
        rethrow(err);
    end

    set(hImage, 'CData', data);
end

function pos = get_approx_position(roi, kern)
    pos = [200.141 205.13];
end


function valid = validate_roi_kern(gui)
    if((isfield(gui, 'RoiRect') & ishandle(gui.RoiRect)) & (isfield(gui, 'KernRect') & ishandle(gui.KernRect)))
        % Handles exist, that means the rectangles are being displayed

        % Ideally, make sure that kernel is in region-of-interest
        valid = true;
        return
    else
        valid = false;
    end
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
g.SetRoiBtn = uicontrol('Parent', g1, 'style', 'pushbutton', 'String', 'Set ROI', 'Enable', 'off');
uicontrol('Parent', g1, 'style', 'text', 'String', 'Frames to Cap', 'HorizontalAlignment', 'Left');

uiextras.Empty('Parent', g1);
g.CaptureBtn = uicontrol('Parent', g1, 'style', 'pushbutton', 'String', 'Capture');

% Column 2 of Grid
g.ExposureCtrl = uicontrol('Parent', g1, 'style', 'popupmenu', 'String', ['1/10000|1/5000|1/2500|1/1111|1/526|1/256|1/128|1/64|1/32|1/16|1/8|1/4'], 'HorizontalAlignment', 'Right', 'Enable', 'off');
g.GainCtrl = uicontrol('Parent', g1, 'style', 'slider', 'Max', 63, 'Min', 16, 'Value', 32, 'SliderStep', [1 1], 'Position', [0 0 1 0.3], 'Enable', 'off');
g.FrameRateCtrl = uicontrol('Parent', g1, 'style', 'popupmenu', 'String', ['60.0|30.0|15.0|7.5|5'], 'Enable', 'off');
g.ContrastCtrl = uicontrol('Parent', g1, 'style', 'checkbox', 'String', 'Contrast Stretch', 'HorizontalAlignment', 'Right');

uiextras.Empty('Parent', g1);

g.TrackingCtrl = uicontrol('Parent', g1, 'style', 'checkbox', 'String', 'Tracking', 'HorizontalAlignment', 'Right');
g.SetKernBtn = uicontrol('Parent', g1, 'style', 'pushbutton', 'Enable', 'off', 'String', 'Set Kernel');
g.FramesToCapCtrl = uicontrol('Parent', g1, 'style', 'edit', 'String', '30');
uiextras.Empty('Parent', g1);
uiextras.Empty('Parent', g1);

set(g1, 'RowSizes', [30 30 30 30 30 30 30 30 -1 30], 'ColumnSizes', [-1 -1]);
% End Grid
end

function TrackingCtrl_Callback(src, e, gui)
    if(get(src, 'Value') == 0)
        set(gui.SetRoiBtn, 'Enable', 'off');
        set(gui.SetKernBtn, 'Enable', 'off');

        if(isfield(gui, 'RoiRect') & ishandle(gui.RoiRect))
            delete(gui.RoiRect);
        end

        if(isfield(gui, 'KernRect') & ishandle(gui.KernRect))
            delete(gui.KernRect);
        end

        if(isfield(gui, 'TrackingLabel') & ishandle(gui.TrackingLabel))
            delete(gui.TrackingLabel);
        end
    else
        % Supposed to track
        if(isfield(gui, 'Axes') & ishandle(gui.Axes))
            set(gui.SetRoiBtn, 'Enable', 'on');
            set(gui.SetKernBtn, 'Enable', 'on');
        else
            set(src, 'Value', 0);
            throw(MException('GUIError:CannotTrackWithoutPreview', 'Cannot track without an open preview window'));
        end
    end
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

    try
        uiwait(gui.Window);
    catch
        disp(lasterr);         
    end

    if(~isappdata(h, 'video'))
        % Video was not successfully set
        throw(MException('VideoError:SelectionCanceled', 'No device was selected through the GUI. Did you cancel the dialog?'));
    end

elseif(nargin == 3) % Don't actually do this...
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
