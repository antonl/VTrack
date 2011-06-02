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

            set(gui.AdaptorCtrl, 'String', ad_str, 'Callback', @gui.AdaptorCtrl_Callback);
            set(gui.DeviceCtrl, 'Callback', @gui.DeviceCtrl_Callback, 'Enable', 'off');
            set(gui.VideoModeCtrl, 'Callback', @gui.VideoModeCtrl_Callback, 'Enable', 'off');
            set(gui.DoneBtn, 'Callback', @gui.DoneBtn_Callback, 'Enable', 'off');

            set(gui.Dialog, 'CloseRequestFcn', @gui.DialogCloseFcn_Callback);
        end

        function delete(gui)
            try
                delete(gui.Dialog);
            end
        end

        function DialogCloseFcn_Callback(gui, src, e)
            notify(gui, 'ClosedDialog', event.EventData);
        end

        function AdaptorCtrl_Callback(gui, src, e)
            aId = get(gui.AdaptorCtrl, 'Value');

            i_a = imaqhwinfo;
            Adaptor = imaqhwinfo(i_a.InstalledAdaptors{aId});

            set(gui.DoneBtn, 'Enable', 'off');

            if(numel(Adaptor.DeviceIDs) < 1)
                % No devices available, don't throw exception though. Devices may be
                % available in another adaptor
                set(gui.DeviceCtrl, 'String', 'None', 'Enable', 'off');
                return;
            end
            
            dev_str = Adaptor.DeviceInfo(1).DeviceName;

            if(numel(Adaptor.DeviceIDs) > 1)
                for i = 2:numel(Adaptor.DeviceIDs)
                    dev = Adaptor.DeviceInfo(i);
                    dev_str = [dev_str '|' dev.DeviceName];
                end
            end

            set(gui.DeviceCtrl, 'String', dev_str, 'Enable', 'on');
        end

        function DeviceCtrl_Callback(gui, src, e)
            % Adaptor chosen
            aId = get(gui.AdaptorCtrl, 'Value');

            i_a = imaqhwinfo;
            Adaptor = imaqhwinfo(i_a.InstalledAdaptors{aId});

            % Populate devices
            dId = get(gui.DeviceCtrl, 'Value');
            
            dName = Adaptor.DeviceIDs{dId};
            Device = imaqhwinfo(Adaptor.AdaptorName, dName);
            
            set(gui.DoneBtn, 'Enable', 'off');

            if(numel(Device.SupportedFormats) < 1)
                % Device has no supported formats
                set(gui.VideoModeCtrl, 'Enable', 'off', 'String', 'None');
                return;
            end

            Formats = Device.SupportedFormats;

            format_str = Formats{1};

            if(numel(Formats) > 1)
                for i = 2:numel(Formats)
                    format_str = [format_str '|' Formats{i}];
                end
            end

            set(gui.VideoModeCtrl, 'Enable', 'on', 'String', format_str);
        end

        function VideoModeCtrl_Callback(gui, src, e)
            % Available adaptors
            aId = get(gui.AdaptorCtrl, 'Value');

            i_a = imaqhwinfo;
            Adaptor = imaqhwinfo(i_a.InstalledAdaptors{aId});

            % Available devices
            dId = get(gui.DeviceCtrl, 'Value');
            
            dName = Adaptor.DeviceIDs{dId};
            Device = imaqhwinfo(Adaptor.AdaptorName, dName);

            fId = get(gui.VideoModeCtrl, 'Value');

            Format = Device.SupportedFormats{fId};
            
            set(gui.DoneBtn, 'Enable', 'on');
        end

        function DoneBtn_Callback(gui, src, e)
            % Hide dialog. It's just easier this way. It doesn't get closed by user 
            set(gui.Dialog, 'Visible', 'off');

            % Available adaptors
            aId = get(gui.AdaptorCtrl, 'Value');

            i_a = imaqhwinfo;
            Adaptor = imaqhwinfo(i_a.InstalledAdaptors{aId});

            % Available devices
            dId = get(gui.DeviceCtrl, 'Value');
            
            dName = Adaptor.DeviceIDs{dId};
            Device = imaqhwinfo(Adaptor.AdaptorName, dName);

            fId = get(gui.VideoModeCtrl, 'Value');

            Format = Device.SupportedFormats{fId};

            % Trigger the finished initializing event
            notify(gui, 'SelectedVideo', VideoSelectedEvent({Adaptor.AdaptorName dId Format}));
        end
    end

    events
        SelectedVideo        
        ClosedDialog
    end
end
