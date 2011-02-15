function TrackerGUI(func)
%% A single entry-point for the gui code. Every callback is called through this function
% Procedure taken from mathworks blog on the switchyard pattern.
% http://www.mathworks.com/company/newsletters/news_notes/win00/prog_patterns.html

    persistent gui; % Contains handles of stuff

    if nargin == 0
        gui = initialize; % Create the gui
    else
        try
            feval(func, gui);
        catch
            disp(lasterr);
        end
    end
end

function g = initialize
%% Creates components for default layout of the gui
%
sz = get(0, 'ScreenSize');
dim = [800 600]; % Size of figure window

% Hold handles in a struct
g = struct();

% Main Window
g.Window = figure('Visible', 'off', 'Position', [(sz(3)-dim(1))/2 (sz(4)-dim(2))/2 dim], ...
    'Toolbar', 'none', 'MenuBar', 'none', 'NumberTitle', 'off', 'Renderer', 'ZBuffer', ...
    'Name', 'ParticleTrack', 'Resize', 'on', 'DoubleBuffer', 'on');

vbox1 = uiextras.VBox('Parent', g.Window);

% Video Box
g.Preview = axes('Parent', vbox1, 'DataAspectRatio', [1 1 1]);
uiextras.Empty('Parent', vbox1);
p1 = uiextras.Panel('Parent', vbox1, 'Title', 'Capture Parameters');
set(vbox1, 'Sizes', [600 -1 200]);

hbox1 = uiextras.HBox('Parent', p1);
p2 = uiextras.Panel('Parent', hbox1); 



set(g.Window, 'Visible', 'on');
end

