classdef MainWindow < handle
    properties (SetAccess = private)
        Window
        Preview
        ExposureCtrl
        GainCtrl
        FrameRateCtrl
        TrackingCtrl
        FramesToCapCtrl
        BackgroundSubCtrl
        ContrastCtrl
        StartPreviewBtn
        SetBackgroundBtn
        SetRoiBtn
        SetKernBtn
        CaptureBtn
    end

    methods
        function gui = MainWindow(parent)
            sz = get(0, 'ScreenSize');
            dim = [250 500]; % Size of figure window
            
            gui.Window = figure('Visible', 'off', 'Position', [(sz(3)-dim(1))/2 (sz(4)-dim(2))/2 dim], ...
                'Toolbar', 'none', 'MenuBar', 'none', 'NumberTitle', 'off', ...
                'Name', 'VTrack', 'Resize', 'off', 'CloseRequestFcn', @gui.CloseMainWindow_Callback);

            v1 = uiextras.VBox('Parent', gui.Window, 'Spacing', 5);

            p1 = uiextras.BoxPanel('Parent', v1, 'Title', 'Camera Settings');

            % Camera parameters grid

            g1 = uiextras.Grid('Parent', p1, 'Padding', 10, 'Spacing', 5);
            uicontrol('Parent', g1, 'style', 'text', 'String', 'Exposure', 'HorizontalAlignment', 'Left');
            uicontrol('Parent', g1, 'style', 'text', 'String', 'Gain','HorizontalAlignment', 'Left');
            uicontrol('Parent', g1, 'style', 'text', 'String', 'Frame Rate', 'HorizontalAlignment', 'Left');
            gui.ExposureCtrl = uicontrol('Parent', g1, 'style', 'popupmenu', 'String', ['1/10000|1/5000|1/2500|1/1111|1/526|1/256|1/128|1/64|1/32|1/16|1/8|1/4'], 'HorizontalAlignment', 'Right', 'Enable', 'off');
            gui.GainCtrl = uicontrol('Parent', g1, 'style', 'slider', 'Max', 63, 'Min', 16, 'Value', 32, 'SliderStep', [1 1], 'Position', [0 0 1 0.3], 'Enable', 'off');
            gui.FrameRateCtrl = uicontrol('Parent', g1, 'style', 'popupmenu', 'String', ['60.0|30.0|15.0|7.5|5'], 'Enable', 'off');

            set(g1, 'ColumnSizes', [-1 -1], 'RowSizes', [-1 -1 -1]);


            % Tracking/Preview Grid
            p2 = uiextras.BoxPanel('Parent', v1, 'Title', 'Tracking/Preview Settings');
            g2 = uiextras.Grid('Parent', p2, 'Padding', 10, 'Spacing', 5);

            gui.StartPreviewBtn = uicontrol('Parent', g2, 'style', 'pushbutton', 'String', 'Start Preview');
            gui.BackgroundSubCtrl = uicontrol('Parent', g2, 'style', 'checkbox', 'String', 'Background Sub', 'HorizontalAlignment', 'Right');
            gui.TrackingCtrl = uicontrol('Parent', g2, 'style', 'checkbox', 'String', 'Tracking', 'HorizontalAlignment', 'Right');
            gui.SetRoiBtn = uicontrol('Parent', g2, 'style', 'pushbutton', 'String', 'Set ROI', 'Enable', 'off');

            gui.ContrastCtrl = uicontrol('Parent', g2, 'style', 'checkbox', 'String', 'Contrast Stretch', 'HorizontalAlignment', 'Right');
            gui.SetBackgroundBtn = uicontrol('Parent', g2, 'style', 'pushbutton', 'Enable', 'off', 'String', 'Set Background');
            uiextras.Empty('Parent', g2);
            gui.SetKernBtn = uicontrol('Parent', g2, 'style', 'pushbutton', 'Enable', 'off', 'String', 'Set Kernel');
            set(g2, 'RowSizes', [-1 -1 -1 -1], 'ColumnSizes', [-1 -1]);

            % Capture Grid
            p3 = uiextras.BoxPanel('Parent', v1, 'Title', 'Capture Settings');
            g3 = uiextras.Grid('Parent', p3, 'Padding', 10, 'Spacing', 5);

            uicontrol('Parent', g3, 'style', 'text', 'String', 'Frames to Cap', 'HorizontalAlignment', 'Left');
            gui.CaptureBtn = uicontrol('Parent', g3, 'style', 'pushbutton', 'String', 'Capture');
            gui.FramesToCapCtrl = uicontrol('Parent', g3, 'style', 'edit', 'String', '30');
            uiextras.Empty('Parent', g3);

            set(g3, 'RowSizes', [-1 -1], 'ColumnSizes', [-1 -1]);

            set(v1, 'Sizes', [-1 -2 -1]);

            % Wait until video object is created
            addlistener(parent, 'VideoObjectReady', @gui.VideoObjectReady_Callback);
        end

        function CloseMainWindow_Callback(obj, src, e)
            notify(obj, 'ClosedMainWindow', event.EventData);
        end

        function VideoObjectReady_Callback(obj, src, e)
            v = e.Video;
            obj.Preview = PreviewWindow(v.VideoResolution, v.NumberOfBands);

            addlistener(obj.Preview, 'ClosedPreview', @obj.ClosedPreview_Callback);

            % Create callbacks for controls

            pr = propinfo(v);

            if(isfield(pr, 'Gain'))
                % Turn off automatic gain adjustment
                set(v, 'GainMode', 'Manual');
                set(obj.GainCtrl, 'Enable', 'on', 'Callback', @obj.GainCtrl_Callback);
            else
            	fprintf('Warning: Couldn''t turn off automatic gain adjustment.\n');
                set(obj.GainCtrl, 'Enable', 'off');
            end
            
            if(isfield(pr, 'Exposure'))
                set(v, 'ExposureMode', 'Manual');
                set(obj.ExposureCtrl, 'Enable', 'on', 'Callback', @obj.ExposureCtrl_Callback);
            else
            	fprintf('Warning: Can''t control exposure.\n');
                set(obj.ExposureCtrl, 'Enable', 'off');
            end

            if(isfield(pr, 'FrameRate'))
                set(obj.FrameRateCtrl, 'Enable', 'on', 'Callback', @obj.FrameRateCtrl_Callback);
            else
            	fprintf('Warning: Can''t control frame rate.\n');
                set(obj.FrameRateCtrl, 'Enable', 'off');
            end

            set(obj.SetRoiBtn, 'Callback', @obj.SetRoiBtn_Callback);
            set(obj.SetKernBtn, 'Callback', @obj.SetKernBtn_Callback);
            set(obj.TrackingCtrl, 'Callback', @obj.ChangedState_Callback);

            set(obj.BackgroundSubCtrl, 'Callback', @obj.ChangedState_Callback);
            set(obj.SetBackgroundBtn, 'Callback', @obj.ChangedState_Callback);

            % Start Preview Callback 
            set(obj.StartPreviewBtn, 'Callback', @obj.StartPreviewBtn_Callback);
            % Capture Btn
            set(obj.CaptureBtn, 'Callback', @obj.CaptureBtn_Callback);

            set(obj.ContrastCtrl, 'Callback', @obj.ChangedState_Callback);

             
            %set(v, 'FramesAcquiredFcn', @obj.FramesAcquiredFcn_Callback);
            %set(v, 'FramesAcquiredFcnCount', 1); % Do this every frame

            % Set windows visible
            set(obj.Window, 'Visible', 'on');

            % Software is now ready to be used 
        end

        function ClosedPreview_Callback(obj, src, e)
            delete(obj.Preview);
        end

        function StartPreviewBtn_Callback(obj, src, e)
            notify(obj, 'ChangedPreviewState');
        end

        function CaptureBtn_Callback(obj, src, e) 
            notify(obj, 'WantCapture');
        end

        function ChangedState_Callback(obj, src, e) 
            % Called when most control values are modified in the GUI
            notify(obj, 'ChangedOptions', ChangedOptionsEvent(src));
        end

        function delete(obj)
            try
                % The try block is here to suppress warnings caused by the window being 
                % already deleted for whatever reason
                delete(obj.Preview);
                fprintf('Closed main window.\n');
                delete(obj.Window);
            end
        end
    end

    events
        ClosedMainWindow
        ChangedOptions
        ChangedPreviewState
        WantCapture
    end
end

