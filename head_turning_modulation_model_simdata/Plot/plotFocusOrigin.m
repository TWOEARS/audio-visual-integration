function plotFocusOrigin (htm)


figure('Color', 'white');
h = axes('FontSize', 16);
hold(h, 'on');

fo_handle = plot(getHypothesis(htm, 'FCKS', 'focus_origin')-1,...
                    'LineWidth', 2             ,...
                    'LineStyle', '-'           ,...
                    'Color'    , [0.1, 0.1, 0.1],...
                    'Parent'   , h);

y_tick_label = {'', 'MFImod', 'rest. pos.', 'DWmod'};%, 'rest. pos.'};
y_tick_label{end+1} = '';
set(h, 'XLim', [0, htm.nb_steps_final],...
			  'YLim', [-2.2, 0.2],...
			  'YTick', -3:1,...
			  'YTickLabel', y_tick_label);
% set(get(h, 'XLabel'), 'String', 'time steps');

% ---
x = [0 getInfo('nb_steps') getInfo('nb_steps') 0];
y = [-1 -1 0 0];
hp1 = patch(x, y, 'red', 'Parent', h);
set(hp1, 'FaceAlpha', 0.3, 'EdgeColor', 'none');

y2 = [-2 -2 -1 -1];
hp2 = patch(x, y2, 'blue', 'Parent', h);
set(hp2, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

% ---
line([1, getInfo('nb_steps')], [0, 0]-1,...
	 'Color', 'k',...
	 'LineStyle', ':',...
	 'LineWidth', 2,...
	 'Parent', h);

focus = getHypothesis(htm, 'FCKS', 'focus');

% for iStep = 1:numel(focus)-1
% 	if focus(iStep+1) ~= focus(iStep) && focus(iStep+1) ~= 0
% 		text(iStep, 0.08, num2str(focus(iStep+1)), 'FontSize', 20);
% 		% line([iStep, iStep], [-1, 0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2);
% 	end
% end