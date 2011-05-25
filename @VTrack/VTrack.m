classdef VTrack
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
                % Create select video dialog
                obj.SelectVideoDialog = AdaptorSelectDialog

                set(obj.SelectVideoDialog.Dialog, True)
                % Wait for value

                % Create video object

                % Create main user interface

                % Display it
            else
                ;
                % Create video object from arguments
            end
        end

        function v = get.video(object)
        % Accessor method for video object
        % Should return nothing if the video is not initialized
            %return object.video
            v = object.video;
        end
    end
end
