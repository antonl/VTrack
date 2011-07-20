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
                addlistener(obj.UserInterface, 'WantPreview', @obj.WantPreview_Callback);

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
            disp(obj.TrackerOptions)
        end

        function ClosedMainWindow_Callback(obj, src, e)
            delete(obj.UserInterface);
        end

        function WantPreview_Callback(obj, src, e)
            disp('Want preview!')
        end

        function SelectedVideo_Callback(obj, src, e)
        % We have all information to initialize video object
            try
                obj.Video = videoinput(e.VideoData{1}, e.VideoData{2}, e.VideoData{3});
                set(obj.Video, 'ReturnedColorSpace', 'grayscale');
                fprintf('Warning: Toolbox mode set to return values in grayscale\n');

                % Request creation of preview window and connect callbacks
                notify(obj, 'VideoObjectReady', VideoObjectReadyEvent(obj.Video));
                addlistener(obj.UserInterface, 'ChangedOption', @obj.ChangedOptions_Callback);
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
