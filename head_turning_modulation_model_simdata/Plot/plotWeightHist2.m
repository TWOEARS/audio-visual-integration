function plotWeightHist (htm)

figure('color', 'white');

nb_objects = htm.RIR.nb_objects;
nb_steps = getInfo('nb_steps');
nb_sources = getInfo('nb_sources');

sources = getObject(htm, 'all', 'source')';

w_all = zeros(nb_objects, nb_steps);
labels = {};

% for iObject = 1:nb_objects
for iObject = 1:nb_objects
	iSource = sources(iObject);
	
	subplot(nb_sources+2, 1, iSource+2);

	t = getObject(htm, iObject, 'tmIdx');
	w = getObject(htm, iObject, 'weight_hist');
	
	idx = t(1):t(1)+numel(w)-1;
	if idx(end) ~= nb_steps
		idx = [1:idx(1)-1, idx(1:end-1), idx(end):nb_steps];
		w(end:idx(end)) = w(end);
	end
	
	w_all(iObject, idx) = w;

	labels{end+1} = getObject(htm, iObject, 'label');
	
	plot(idx, w, 'LineWidth', 3);
	
	set(gca, 'XLim', [0, nb_steps], 'YLim', [-1.1, 1.1]);
	
	line([0, nb_steps], [0, 0], 'LineStyle', '--', 'Color', 'k');
end

subplot(nb_objects+2, 1, [1,2]);

plot(w_all', 'LineWidth', 3);
set(gca, 'XLim', [0, nb_steps], 'YLim', [-1.1, 1.1]);

line([0, nb_steps], [0, 0], 'LineStyle', '--', 'Color', 'k');