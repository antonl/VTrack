classdef PreviewWindow < handle
    properties
        Window
        PreviewImage
        TimeField
        ResField
        StretchField
    end

    methods
        function gui = PreviewWindow(resolution, numberOfBands)
        %% Creates preview window given a resolution of video to be displayed
        % Resolution is an 1x2 array of the form [width height]
        % NumberOfBands is an integer specifying the number of channels in the 
        %   video data returned by IMAQ toolkit
            vRes = resolution; 
            sz = get(0, 'ScreenSize');

            % Height of status bar in characters
            statusCharHeight = 1.4;

            timeSecWidth = 20;
            resSecWidth = 20;
            stretchSecWidth = 30;

            stretchXOffset = timeSecWidth + resSecWidth;

            normText = [0 0 1 1];

            % Figure to hold preview image
            gui.Window = figure('Visible', 'off', 'MenuBar', 'none', 'Toolbar', 'none', 'NumberTitle', 'off', 'Name', 'Preview', ...
                'CloseRequestFcn', @gui.PreviewCloseFcn, 'Resize', 'off', 'Units', 'characters', ...
                'DoubleBuffer', 'on');
            
            figPos = get(gui.Window, 'OuterPosition');

            % Panel to hold status information
            StatusPanel = uipanel('Parent', gui.Window, 'Units', 'characters', 'BorderType', 'none', ...
                'Position', [0 0 figPos(3) statusCharHeight]);
            
            TimePanel = uipanel('Parent', StatusPanel, 'Units', 'characters', 'Position', [0 0 timeSecWidth statusCharHeight]);
            gui.TimeField = uicontrol('Parent', TimePanel, 'Style', 'text', 'String', 'Time Stamp', 'Units', 'normalized', ...
            'Position', normText);

            ResPanel = uipanel('Parent', StatusPanel, 'Units', 'characters', 'Position', [timeSecWidth 0 resSecWidth statusCharHeight]);
            gui.ResField = uicontrol('Parent', ResPanel, 'Style', 'text', 'String', 'Resolution', 'Units', 'normalized', ...
                'Position', normText);

            StretchPanel = uipanel('Parent', StatusPanel, 'Units', 'characters', 'Position', ...
                [stretchXOffset 0 stretchSecWidth statusCharHeight]);
            gui.StretchField = uicontrol('Parent', StretchPanel, 'Style', 'text', 'String', 'Contrast Stretching Off', 'Units', 'normalized', ...
                'Position', normText);

            % Panel to hold preview image
            ImagePanel = uipanel('Parent', gui.Window, 'Units', 'characters', 'BorderType', 'none', ...
                'Position', [0 statusCharHeight figPos(3) figPos(4)-statusCharHeight]);
            set(ImagePanel, 'Units', 'normalized');

            Axes = axes('Parent', ImagePanel);

            set(Axes, 'Visible', 'on', 'CLimMode', 'manual', 'CLim', [0 255],...
                'ALimMode', 'manual', 'XLimMode', 'manual', 'YLimMode', 'manual', ...
                'ZLimMode', 'manual', 'XTickMode', 'manual', 'YTickMode', 'manual', ...
                'ZTickMode', 'manual');

            numBands = numberOfBands; 
            data = zeros(vRes(2), vRes(1), numBands);

            gui.PreviewImage = image(data, 'Parent', Axes);

            set(Axes, 'Units', 'pixels');
            
            set(Axes, 'XLim', [1 vRes(1)], 'YLim', [1 vRes(2)], 'Position', [0 0 vRes(1) vRes(2)]);

            % Resize figure so that no rescaling needs to be done
            set(StatusPanel, 'Units', 'pixels');
            statusPos = get(StatusPanel, 'Position');
            figWidth = vRes(1);
            figHeight = vRes(2) + statusPos(4); 
            set(gui.Window, 'Units', 'pixels');
            set(gui.Window, 'Position', [(sz(3)-figWidth)/2 (sz(4)-figHeight)/2 figWidth figHeight]);
        end
        
        function ReceiveData_Callback(obj, v, e, hImage) 
            %% Function is called when imaq updates a frame
            hImage = e.Data;
        end

        function PreviewCloseFcn(obj, src, e)
            notify(obj, 'ClosedPreview', event.EventData);
        end

        function delete(gui)
            try
                % The try block is here to suppress warnings caused by the window being 
                % already deleted for whatever reason
                delete(gui.Window)
            end
        end
    end

    events
        ClosedPreview
    end
end
