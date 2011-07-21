classdef ChangedPreviewEvent < event.EventData
    properties
        state
    end

    methods
        function e = ChangedPreviewEvent(state)
            if strcmp(state, 'on')
            	e.state = 'on';
            elseif strcmp(state, 'off')
                e.state = 'off';
            else
                throw(MException('VTrack:UnknownPreviewState', 'ChangedPreview event called with unknown argument'));
            end
        end
    end
end


