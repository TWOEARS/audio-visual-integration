function plotWeightHist (htm)

	info = htm.information;

	tline = info.timeline;
	nb_sources = info.nb_sources;
	nb_steps = info.nb_steps;

	figure('Color', 'white');
	hold on;

	sources = getObject(htm, 'all', 'source')';

	w_all = zeros(nb_sources, nb_steps);
	labels = cell(1, nb_sources);

	for iObject = 1:nb_sources
		iSource = sources(iObject);

		t = getObject(htm, iObject, 'tmIdx');
		w = getObject(htm, iObject, 'weight_hist');

		idx_end = min([t(1)+numel(w)-1, nb_steps]);
		w_all(iSource, t(1):idx_end) = w(1:(idx_end-t(1)+1));
	
		labels{iSource} = getObject(htm, iObject, 'label');
	end

	coeff = 1 :2: (2*nb_sources);
	sources_labels = {};
	ytick = [];

	for iSource = 1:nb_sources
		if numel(tline{iSource}) > 2
			iTimeline = tline{iSource};
			vec = zeros(1, nb_steps)+0.1;
			iStep = 2;
			while iStep < numel(iTimeline)
				idx = iTimeline(iStep):iTimeline(iStep+1);
				vec(idx) = 0.9;
				if iStep+2 < numel(iTimeline)
					iStep = iStep + 2;
				else
					iStep = iStep + 3;
				end
			end
		else
			vec = zeros(1, nb_sources)+0.1;
		end

		y = 0.1 - (iSource*2.2);
		for iStep = 2:2:numel(iTimeline)-1
			if iStep < numel(iTimeline)
				w = (iTimeline(iStep+1)-iTimeline(iStep))+1;
				rectangle('Position', [iTimeline(iStep), y, w, 2.2], 'FaceColor', [0.8,0.8,0.8], 'EdgeColor', 'none');
			end
		end
		ytick(end+1) = y+1.1;

		plot(w_all(iSource, :)+(y+1.1), 'LineWidth', 4);

		uscore = strfind(labels{iSource}, '_');
		sources_labels(end+1) = {[labels{iSource}(1:uscore-1), ' ', labels{iSource}(uscore+1:end)]};
	end

	yticklabels = {};
	for iSource = 1:nb_sources
		% yticklabels{end+1} = sources_labels{iSource};
		yticklabels{end+1} = sources_labels{(nb_sources-iSource)+1};
	end

	set(gca, 'YTick', ytick(end:-1:1),...
			 'YTickLabel', yticklabels,...
			 'YTickLabelRotation', 0,...
			 'YLim', [(ytick(end)-1.1)-0.1, 0.2],...
			 'Xlim', [0, info.nb_steps],...
			 'FontSize', 20,...
			 'Box', 'on',...
			 'XGrid', 'on',...
			 'XMinorGrid', 'on');









