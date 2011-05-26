classdef VideoSelectedEvent < event.EventData
    properties
        VideoData
    end

    methods
        function data = VideoSelectedEvent(cell_data)
            data.VideoData = cell_data;
        end
    end
end
