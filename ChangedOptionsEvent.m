classdef ChangedOptionsEvent < event.EventData
    properties
        % Contains new tracking options 
        TrackerOptions
    end

    methods
        function e = ChangedOptionsEvent(state)
            % Function takes a struct that has some of the following fields set
            % BackgroundSubtract : boolean
            % ContrastStretch : boolean
            % ExposureValue : integer returned from imaq
            % GainValue : integer returned from imaq
            % FrameRate : integer returned from imaq
            % TrackingEnabled : boolean
            % CurrentROI : [left, bottom, width, height] in pixels
            % CurrentKernel : [left, bottom, width, height] in pixels
            
            % Error checking is done in TrackerOptions class
            e.TrackerOptions = TrackerOptions(state);
        end
    end
end

