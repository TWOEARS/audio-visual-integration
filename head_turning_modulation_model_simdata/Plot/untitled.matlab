function plotHtmFTL (htm)

	if nargin == 1
		behavior = 'dw';
	else
		behavior = varargin{1};
	end

	info = htm.information;

	tline = info.timeline;
	nb_sources = info.nb_sources;
	nb_steps = info.nb_steps;
	figure('Color', 'white');

	hold on;

	if strcmp(behavior, 'dw') || strcmp(behavior, 'both')
		focus = htm.FCKS.focus;
		line_color = [0 0.4470 0.7410];

		ff = zeros(1, info.nb_steps);
		sources = getObject(htm, 'all', 'source');
		for iStep = 1:info.nb_steps
			if focus(iStep) ~= 0
				ff(iStep) = sources(focus(iStep));
			end
		end
	else
		ff = getNaiveBehavior(htm);
		line_color = [1, 0.4, 0.4];
	end

	ff = -ff;% - info.nb_sources;
	ff(ff == 0) = 0.8;
	for ii = 1:info.nb_sources
		ff(ff == -ii) = -ii+0.9;
	end

	ff(ff ~= 0.8) = ff(ff ~= 0.8)-0.4;

	sources_labels = {};

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

		for iStep = 2:2:numel(iTimeline)-1
			if iStep < numel(iTimeline)
				w = (iTimeline(iStep+1)-iTimeline(iStep))+1;
				rectangle('Position', [iTimeline(iStep), 0.1-iSource, w, 0.8], 'FaceColor', [0.8,0.8,0.8]);
			end
		end

		% plot(vec-iSource, 'LineWidth', 2);

		tmp_label = htm.gtruth{iSource}(iTimeline(2), 1);
		uscore = cell2mat(strfind(tmp_label, '_'));
		sources_labels(end+1) = {[tmp_label{1}(1:uscore-1), ' ', tmp_label{1}(uscore+1:end)]};
	end

	if strcmp(behavior, 'both')
		ff2 = ff;
		ff = getNaiveBehavior(htm);
		ff = -ff;
		ff(ff == 0) = 0.8;
		for ii = 1:info.nb_sources
			ff(ff == -ii) = -ii+0.9;
		end
		ff(ff ~= 0.8) = ff(ff ~= 0.8)-0.4;
		plot(ff, 'LineWidth', 5, 'LineStyle', '-', 'Color', [1, 0.4, 0.4]);

		plot(ff2, 'LineWidth', 4, 'LineStyle', '-', 'Color', line_color);
	else
		plot(ff, 'LineWidth', 5, 'LineStyle', '-', 'Color', line_color);
	end
	

	ytick = (2*nb_sources-1)*(-0.5):-0.5;
	ytick = [ytick, ytick+0.4, ytick-0.4];
	ytick = sort(ytick);
	yticklabels = {};
	for iSource = 1:nb_sources
		yticklabels{end+1} = '';
		yticklabels{end+1} = sources_labels{(nb_sources-iSource)+1};
		yticklabels{end+1} = '';
	end
	ytick(end+1) = 0.8;
	yticklabels{end+1} = 'rest. pos';
	% 'YTick', (2*nb_sources-1)*(-0.5):-0.5,...
	% 'YTickLabel', sources_labels,...
	set(gca, 'YTick', ytick,...
			 'YTickLabel', yticklabels,...
			 'YTickLabelRotation', 0,...
			 'YLim', [-info.nb_sources-0.1, 1],...
			 'Xlim', [0, info.nb_steps],...
			 'FontSize', 20,...
			 'Box', 'on',...
			 'XGrid', 'on',...
			 'XMinorGrid', 'on');









