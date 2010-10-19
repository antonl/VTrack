function [m] = pt_analyze(filename)
%PT_ANALYZE Run a particle tracking analysis on a video file or video object
% Detailed description

m = mmreader(filename);

h = figure('Visible', 'on', 'Position', [150 150 m.Width m.Height], ...
    'Toolbar', 'none', 'MenuBar', 'none', 'NumberTitle', 'off', 'Renderer', 'ZBuffer', ...
    'Name', 'ParticleTrack Analyze', 'Resize', 'off');


%roi = imrect()
end
