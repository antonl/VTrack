classdef FileTracker < handle
    properties (SetAccess=private)
        MainDialog
        PreviewImage

        FirstFileLabel
        LastFileLabel
        SequenceLengthLabel
        BackgroundSubtract
        ContrastStretch

        Path
        FileList
        AvgBackground
    end

    methods
        function obj = FileTracker(varargin)
            % Check to see if we have layout toolbox
            if ~(exist('uiextras.VBox') == 8)
            	throw(MException('VTrack:Prereqs:GUIToolboxMissing', ...
            	    'You do not seem to have the GUI Layout Toolbox Installed'))
            end
            
            % Display main dialog

            sz = get(0, 'ScreenSize');
            dim = [250 400]; % Size of figure window
            
            obj.MainDialog = figure('Visible', 'off', 'Position', [(sz(3)-dim(1))/2 (sz(4)-dim(2))/2 dim], ...
                'Toolbar', 'none', 'MenuBar', 'none', 'NumberTitle', 'off', ...
                'Name', 'VTrack FileTracker', 'Resize', 'off', 'CloseRequestFcn', @obj.CloseMainWindow_Callback);

            vbox = uiextras.VBox('Parent', obj.MainDialog);
            infopanel = uiextras.Panel('Parent', vbox, 'Title', 'File Info');
            optionspanel = uiextras.Panel('Parent', vbox, 'Title', 'Options');
            gopanel = uiextras.Panel('Parent', vbox, 'Padding', 15);
            set(vbox, 'Sizes', [-3 -1 -1]);

            infogrid = uiextras.Grid('Parent', infopanel, 'Spacing', 3, 'Padding', 5);
            uicontrol('Parent', infogrid, 'style', 'text', 'String', 'Select Files', 'HorizontalAlignment', 'Left');
            uicontrol('Parent', infogrid, 'style', 'text', 'String', 'First file:', 'HorizontalAlignment', 'Left');
            uicontrol('Parent', infogrid, 'style', 'text', 'String', 'Last file:', 'HorizontalAlignment', 'Left');
            uicontrol('Parent', infogrid, 'style', 'text', 'String', 'Sequence Length:', 'HorizontalAlignment', 'Left');

            selectfiles_button = uicontrol('Parent', infogrid, 'style', 'pushbutton', 'String', 'Open Dialog');
            obj.FirstFileLabel = uicontrol('Parent', infogrid, 'style', 'text', 'String', 'N/A');
            obj.LastFileLabel = uicontrol('Parent', infogrid, 'style', 'text', 'String', 'N/A');
            obj.SequenceLengthLabel = uicontrol('Parent', infogrid, 'style', 'text', 'String', 'N/A');

            set(infogrid, 'ColumnSizes', [-1 -1], 'RowSizes', [-1 -1 -1 -1]); 

            optionsvbox = uiextras.VBox('Parent', optionspanel, 'Padding', 5);
            obj.BackgroundSubtract = uicontrol('Parent', optionsvbox, 'style', 'checkbox', 'String', ... 
                'Subtract background', 'HorizontalAlignment', 'Left');
            obj.ContrastStretch = uicontrol('Parent', optionsvbox, 'style', 'checkbox', 'String', ...
                'Contrast Stetch', 'HorizontalAlignment', 'Left');

            gobutton = uicontrol('Parent', gopanel, 'style', 'pushbutton', 'String', 'Go!');

            % Do all callbacks in one place
            set(selectfiles_button, 'Callback', @obj.SelectFiles_Callback);
            set(gobutton, 'Callback', @obj.Go_Callback);

            % Finished constructing main dialog
            set(obj.MainDialog, 'Visible', 'on');
        end

        function Go_Callback(obj, src, e)
            % Magic happens here

            if get(obj.BackgroundSubtract, 'Value') == 1
            	% Average background over sequence
            	len = size(obj.FileList)

            	% Scale by number of images
            	obj.AvgBackground = 0;

                scale = res(1)*res(2)*len(2);
            	for i = 1:len(2)
            		obj.AvgBackground = obj.AvgBackground + sum(sum(imread([obj.Path obj.FileList{i}])))./scale;
            	end

            end  
            

            % Display first image and ask for ROI and Kern


            % Panel to hold preview image
            
            PreviewWindow = figure('Visible', 'off', 'MenuBar', 'none', 'Toolbar', 'none', ...
                'NumberTitle', 'off', 'Name', 'Preview', 'Resize', 'off', 'Units', 'pixels');
            Ax = axes('Parent', PreviewWindow);
            obj.PreviewImage = imshow(obj.BackgroundImage, 'Parent', Ax, 'Border', 'tight', 'DisplayRange', [0 255]);
            set(PreviewWindow, 'Visible', 'on');


        end
        
        function SelectFiles_Callback(obj, src, e)
            [obj.FileList, obj.Path] = uigetfile({'*.jpg;*.bmp;*.png;*.tif', 'Image Files' }, 'Select sequence', 'MultiSelect', 'on');

            len = size(obj.FileList);
            if size(obj.FileList) > [0 1]
            	% More than one image in sequence
                set(obj.FirstFileLabel, 'String', obj.FileList(1));
                set(obj.LastFileLabel, 'String', obj.FileList(len(2)));
                set(obj.SequenceLengthLabel, 'String', len(2));
            else
            	obj.FileList = [];
            end
        end

        function CloseMainWindow_Callback(obj, src, e)
            % Main dialog closed. Shutdown program
            delete(src)
        end
    end
end

