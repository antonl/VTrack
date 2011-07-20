classdef ChangedOptionEvent < event.EventData
    properties
        % Contains new tracking options 
        UpdatedOption
    end

    methods
        function e = ChangedOptionEvent(src)
            % Function takes a struct that has some of the following fields set
            % BackgroundSubtract : boolean
            % ContrastStretch : boolean
            % ExposureValue : integer returned from imaq
            % GainValue : integer returned from imaq
            % FrameRate : integer returned from imaq
            % TrackingEnabled : boolean
            % CurrentROI : [left, bottom, width, height] in pixels
            % CurrentKernel : [left, bottom, width, height] in pixels
            
            % Determine which option changed, 
            % Error checking is done in TrackerOptions class
            %e.TrackerOptions = TrackerOptions(src);

            e.UpdatedOption = struct();

            tag = get(src, 'Tag');
            if strcmp(tag, 'contraststretch')
            	e.UpdatedOption.ContrastStretch = get(src, 'Value');
            elseif strcmp(tag, 'setroi')
            	e.UpdatedOption.CurrentROI = get(src, 'Value');
            elseif strcmp(tag, 'setkern')
            	e.UpdatedOption.CurrentKernel = get(src, 'Value');
            elseif strcmp(tag, 'tracking')
            	e.UpdatedOption.TrackingEnabled = get(src, 'Value');
            elseif strcmp(tag, 'backgroundsub')
            	e.UpdatedOption.BackgroundSubtract = get(src, 'Value');
            elseif strcmp(tag, 'setbackground')
            	e.UpdatedOption.CurrentBackground = get(src, 'Value');
            else
                throw(MException('VTrack:UnknownEvent', 'ChangedOption event called by an unknown source'));
            end
        end
    end
end

