classdef MainWindow < handle
    properties (SetAccess = private, Hidden)
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
        function gui = MainWindow
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

            gui.Preview = PreviewWindow([480, 640], 3);
        end

        function CloseMainWindow_Callback(obj, src, e)
            notify(obj, 'ClosedMainWindow', event.EventData);
        end

        function delete(obj)
            try
                % The try block is here to suppress warnings caused by the window being 
                % already deleted for whatever reason
                delete(obj.Preview);
                delete(obj.Window);
            end
        end
    end

    events
        ClosedMainWindow
    end
end

