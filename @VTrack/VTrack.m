classdef VTrack < handle
    properties (SetAccess=private)
        Video
        SelectVideoDialog
        UserInterface
        TrackerOptions
    end

    methods
        function obj = VTrack(varargin)
        % Creates select video dialog, initializes the video capture
        % object and then creates the main user interface.

            % Quick test to check if GUILayoutToolbox is installed
            if ~(exist('uiextras.VBox') == 8)
            	throw(MException('VTrack:Prereqs:GUIToolboxMissing', ...
            	    'You do not seem to have the GUI Layout Toolbox Installed'))
            end

            if nargin == 0
                obj.Video = 'not available';

                % Create select video dialog
                obj.SelectVideoDialog = AdaptorSelectDialog;
                
                % Create main user interface
                obj.UserInterface = MainWindow(obj);

                set(obj.SelectVideoDialog.Dialog, 'Visible', 'on');

                % Add listener for event called when user selects video mode
                addlistener(obj.SelectVideoDialog, 'SelectedVideo', @obj.SelectedVideo_Callback);
                addlistener(obj.SelectVideoDialog, 'ClosedDialog', @obj.ClosedSelectVideo_Callback);
                addlistener(obj.UserInterface, 'ClosedMainWindow', @obj.ClosedMainWindow_Callback);
                addlistener(obj.UserInterface, 'ChangedPreviewState', @obj.ChangedPreviewState_Callback);

                obj.TrackerOptions = TrackerOptions();
            else
                throw(MException('VTrack:NotImplemented:ConstructFromArgs', 'Cannot construct VTrack from arguments. Please call VTrack without arguments and use the dialogs.'))
                % Create video object from arguments
            end
        end

        function delete(gui)
        % Class destructor
            fprintf('Called destructor\n'); 
        end
       
        function ClosedSelectVideo_Callback(obj, src, e)
            fprintf('Closed dialog before video mode was selected.\n');
            delete(obj.SelectVideoDialog);
            delete(obj.UserInterface);
        end

        function ChangedOptions_Callback(obj, src, e)
            obj.TrackerOptions.UpdateOptions(e.UpdatedOption);
            
            s = propinfo(obj.Video.Source);
            if isfield(e.UpdatedOption, 'FrameRate')
                frm = s.FrameRate;
            	set(obj.Video.Source, 'FrameRate', frm.ConstraintValue{obj.TrackerOptions.FrameRate}); 
            end
            %disp(obj.TrackerOptions)
        end

        function ClosedMainWindow_Callback(obj, src, e)
            delete(obj.UserInterface);
        end

        function ChangedPreviewState_Callback(obj, src, e)
            if strcmp(e.state, 'on')
            	% Turn on preview, open window, register callback, etc
                set(obj.UserInterface.Preview.Window, 'Visible', 'on')
                preview(obj.Video, obj.UserInterface.Preview.PreviewImage);	
            else
            	% Turn off preview, close hide window
                set(obj.UserInterface.Preview.Window, 'Visible', 'off')
                stoppreview(obj.Video);	
            end
        end

        function UpdatePreviewFcn_Callback(obj, v, e, hImage) 
            %% Function is called when imaq updates a frame
            VTrack_imcopy(hImage, imcomplement(e.Data));
            set(obj.UserInterface.Preview.TimeField, 'String', e.Timestamp);
            if ~isempty(e.Resolution)
                % Apparently, sometimes the resolution field is empty?
                set(obj.UserInterface.Preview.ResField, 'String', e.Resolution);
            end
            set(obj.UserInterface.Preview.CaptureField, 'String', e.Status);

            % Draw tracking box
            
            if obj.TrackerOptions.TrackingEnabled
                if ~isempty(obj.TrackerOptions.CurrentROI)
                    set(obj.UserInterface.Preview.ROI_Rect, 'Position', obj.TrackerOptions.CurrentROI, 'Visible', 'on');
                end

                if ~isempty(obj.TrackerOptions.CurrentKernel)
                    set(obj.UserInterface.Preview.Kern_Rect, 'Position', obj.TrackerOptions.CurrentKernel, 'Visible', 'on');
                end
            end

            % Maybe find out the parent?
            % Visualize tracking boxes? 
            % Contrast stretch here? 
            % WTF!
        end

        function SelectedVideo_Callback(obj, src, e)
        % We have all information to initialize video object
            try
                obj.Video = videoinput(e.VideoData{1}, e.VideoData{2}, e.VideoData{3});
                %set(obj.Video, 'ReturnedColorSpace', 'grayscale');
                %fprintf('Warning: Toolbox mode set to return values in grayscale\n');

                % Request creation of preview window and connect callbacks
                notify(obj, 'VideoObjectReady', VideoObjectReadyEvent(obj.Video));
                addlistener(obj.UserInterface, 'ChangedOption', @obj.ChangedOptions_Callback);
                % Preview frame acquired callback
                setappdata(obj.UserInterface.Preview.PreviewImage, 'UpdatePreviewWindowFcn', @obj.UpdatePreviewFcn_Callback);

            catch e
                disp('Failed to initialize video');
                rethrow(e);
            end

            % Place delete statement after the video object has been initialized
            delete(obj.SelectVideoDialog);
        end
    end

    events
        VideoObjectReady
    end
end
