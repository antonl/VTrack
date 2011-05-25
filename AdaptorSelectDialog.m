classdef AdaptorSelectDialog < handle
    properties (SetAccess = private, Hidden)
        Dialog
        AdaptorCtrl
        DeviceCtrl
        VideoModeCtrl
        DoneBtn
    end

    methods
        function gui = AdaptorSelectDialog
            sz = get(0, 'ScreenSize');
            dim = [250 170];
            
            % Create user interface elements
            gui.Dialog = figure('Visible', 'off', 'Position',  ...
                [(sz(3)-dim(1))/2 (sz(4)-dim(2))/2 dim], 'Toolbar', 'none', ...
                'MenuBar', 'none', 'NumberTitle', 'off', 'Name', 'Select Adaptor/Device', ...
                'Resize', 'off');

            box = uiextras.VBox('Parent', gui.Dialog);

            g1 = uiextras.Grid('Parent', box);

            uicontrol('Parent', g1, 'style', 'text', 'String', 'Adaptor', ...
                'HorizontalAlignment', 'Left');
            uicontrol('Parent', g1, 'style', 'text', 'String', 'Device', ...
                'HorizontalAlignment', 'Left');
            uicontrol('Parent', g1, 'style', 'text', 'String', 'Video Mode', ...
                'HorizontalAlignment', 'Left');

            gui.AdaptorCtrl = uicontrol('Parent', g1, 'style', 'popupmenu',  ...
                'String', 'Empty');
            gui.DeviceCtrl = uicontrol('Parent', g1, 'style', 'popupmenu', ...
                'String', 'Empty');
            gui.VideoModeCtrl = uicontrol('Parent', g1, 'style', 'popupmenu', ...
                'String', 'Empty');
            set(g1, 'RowSizes', [30 30 30], 'ColumnSizes', [-1 -1]);

            gui.DoneBtn = uicontrol('Parent', box, 'style', 'pushbutton', 'String', 'Done');

            set(box, 'Sizes', [-1 30], 'Padding', 20);
            
            % Create callbacks and things
            i_a = imaqhwinfo;

            if(numel(i_a.InstalledAdaptors) < 1)
                throw(MException('VTrack:Prereqs:NoAdaptorsFound', 'No Adaptors found!'));
            end
    
            ad_str = i_a.InstalledAdaptors{1};
        
            if(numel(i_a.InstalledAdaptors) > 1)
                for i = 2:numel(i_a.InstalledAdaptors)
                    ad_str = [ad_str '|' i_a.InstalledAdaptors{i}];
                end
            end

            set(AdaptorCtrl, 'String', ad_str, 'Callback', @AdaptorCtrl_Callback);
            set(DeviceCtrl, 'Callback', @DeviceCtrl_Callback, 'Enable', 'off');
            set(VideoModeCtrl, 'Callback', @VideoModeCtrl_Callback, 'Enable', 'off');
            set(DoneBtn, 'Callback', @DoneBtn_Callback, 'Enable', 'off');
        end

        function AdaptorCtrl_Callback
            aId = get(AdaptorCtrl, 'Value');

            i_a = imaqhwinfo;
            Adaptor = imaqhwinfo(i_a.InstalledAdaptors{gui.aId});

            set(DoneBtn, 'Enable', 'off');

            if(numel(Adaptor.DeviceIDs) < 1)
                % No devices available, don't throw exception though. Devices may be
                % available in another adaptor
                set(DeviceCtrl, 'String', 'None', 'Enable', 'off');
                return;
            end
            
            dev_str = Adaptor.DeviceInfo(1).DeviceName;

            if(numel(Adaptor.DeviceIDs) > 1)
                for i = 2:numel(Adaptor.DeviceIDs)
                    dev = Adaptor.DeviceInfo(i);
                    dev_str = [dev_str '|' dev.DeviceName];
                end
            end

            set(DeviceCtrl, 'String', dev_str, 'Enable', 'on');
        end

        function DeviceCtrl_Callback
            % Adaptor chosen
            aId = get(AdaptorCtrl, 'Value');

            i_a = imaqhwinfo;
            Adaptor = imaqhwinfo(i_a.InstalledAdaptors{aId});

            % Populate devices
            dId = get(DeviceCtrl, 'Value');
            
            dName = Adaptor.DeviceIDs{dId};
            Device = imaqhwinfo(Adaptor.AdaptorName, dName);
            
            set(DoneBtn, 'Enable', 'off');

            if(numel(gui.Device.SupportedFormats) < 1)
                % Device has no supported formats
                set(VideoModeCtrl, 'Enable', 'off', 'String', 'None');
                return;
            end

            Formats = Device.SupportedFormats;

            format_str = Formats{1};

            if(numel(Formats) > 1)
                for i = 2:numel(Formats)
                    format_str = [format_str '|' Formats{i}];
                end
            end

            set(VideoModeCtrl, 'Enable', 'on', 'String', format_str);
        end

        function VideoModeCtrl_Callback
            % Available adaptors`
            aId = get(AdaptorCtrl, 'Value');

            i_a = imaqhwinfo;
            Adaptor = imaqhwinfo(i_a.InstalledAdaptors{aId});

            % Available devices
            dId = get(DeviceCtrl, 'Value');
            
            dName = Adaptor.DeviceIDs{dId};
            Device = imaqhwinfo(Adaptor.AdaptorName, dName);

            fId = get(VideoModeCtrl, 'Value');

            Format = Device.SupportedFormats{fId};
            
            set(DoneBtn, 'Enable', 'on');
        end

        function DoneBtn_Callback(obj)
            % Available adaptors`
            aId = get(AdaptorCtrl, 'Value');

            i_a = imaqhwinfo;
            Adaptor = imaqhwinfo(i_a.InstalledAdaptors{aId});

            % Available devices
            dId = get(DeviceCtrl, 'Value');
            
            dName = Adaptor.DeviceIDs{dId};
            Device = imaqhwinfo(Adaptor.AdaptorName, dName);

            fId = get(VideoModeCtrl, 'Value');

            Format = Device.SupportedFormats{fId};

            % Trigger the finished initializing event
            notify(obj, 'SelectedVideo', VideoSelectedEvent({Adaptor.AdaptorName dId Format}));
        end
    end

    events
        SelectedVideo        
    end
end
