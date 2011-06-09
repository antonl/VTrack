classdef TrackerOptions < handle
    properties
        % BackgroundSubtract : boolean
        % ContrastStretch : boolean
        % ExposureValue : integer returned from imaq
        % GainMode : 'manual' or 'automatic', from imaq
        % GainValue : integer returned from imaq
        % FrameRate : integer returned from imaq
        % TrackingEnabled : boolean
        % CurrentROI : [left, bottom, width, height] in pixels
        % CurrentKernel : [left, bottom, width, height] in pixels

        BackgroundSubtract
        ContrastStretch
        ExposureValue
        GainMode
        GainValue
        FrameRate
        TrackingEnabled
        CurrentROI
        CurrentKernel
    end

    methods
    end
end
