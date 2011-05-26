classdef VTrack < handle
    properties (SetAccess=private)
        video
        SelectVideoDialog
        UserInterfaceDialog
    end

    methods
        function obj = VTrack()
        % Creates select video dialog, initializes the video capture
        % object and then creates the main user interface.

            % Quick test to check if GUILayoutToolbox is installed
            if ~(exist('uiextras.VBox') == 8)
            	throw MException('VTrack:Prereqs:GUIToolboxMissing', ...
            	    'You do not seem to have the GUI Layout Toolbox Installed');
            end

            if nargin == 0
                obj.video = 'not available';

                % Create select video dialog
                obj.SelectVideoDialog = AdaptorSelectDialog;

                set(obj.SelectVideoDialog.Dialog, 'Visible', 'on');

                % Add listener for event called when user selects video mode
                addlistener(obj.SelectVideoDialog, 'SelectedVideo', @obj.SelectedVideo_Callback);

                % Create main user interface
                %obj.UserInterface = MainGui;

                % Display it
            else
                ;
                % Create video object from arguments
            end
        end

        function delete(gui)
        % Class destructor
            
        end
        
        function SelectedVideo_Callback(obj, src, e)
        % We have all information to initialize video object
            try
                delete(obj.SelectVideoDialog);
                obj.video = videoinput(e.Data.VideoData{1}, e.Data.VideoData{2}, e.Data.VideoData{3});
            catch e
                disp('Failed to initialize video');
                rethrow(e);
            end
        end
        
        function v = get.video(object)
        % Accessor method for video object
        % Should return nothing if the video is not initialized
            v = object.video;
        end
    end
end
