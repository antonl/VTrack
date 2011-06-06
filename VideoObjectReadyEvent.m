classdef VideoObjectReadyEvent < event.EventData
    properties
        % Contains a handle to the created video object
        Video
    end

    methods
        function e = VideoObjectReadyEvent(video_object)
            e.Video = video_object;
        end
    end
end

