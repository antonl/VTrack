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
        function UpdateOptions(obj, opt)
            if isfield(opt, 'BackgroundSubtract')
            	obj.BackgroundSubtract = opt.BackgroundSubtract;
            end
            if isfield(opt, 'ContrastStretch')
                obj.ContrastStretch = opt.ContrastStretch;
            end
            if isfield(opt, 'ExposureValue')
                obj.ExposureValue = opt.ExposureValue;
            end
            if isfield(opt, 'GainMode')
                obj.GainMode = opt.GainMode;
            end
            if isfield(opt, 'FrameRate')
                obj.FrameRate = opt.FrameRate;
            end
            if isfield(opt, 'TrackingEnabled')
                obj.TrackingEnabled = opt.TrackingEnabled;
            end
        end
    end
end
