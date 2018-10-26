function plotHtmFTL (htm)

	info = htm.information;

	tline = info.timeline;
	nb_sources = info.nb_sources;
	nb_steps = info.nb_steps;
	
	focus = htm.FCKS.focus;
	focus_origin = htm.FCKS.focus_origin;
	
	focus_mfi = nan(1, nb_steps);
	idx_mfi = find(focus_origin == -1);
	focus_mfi(idx_mfi) = htm.FCKS.focus(idx_mfi);
	
	focus_dw = nan(1, nb_steps);
	idx_dw = find(focus_origin == 1);
	focus_dw(idx_dw) = htm.FCKS.focus(idx_dw);

	focus_rest = nan(1, nb_steps);
	idx_rest = find(focus_origin == 0);
	focus_rest(idx_rest) = htm.FCKS.focus(idx_rest);

	for iStep = 1:nb_steps-1
		if focus_origin(iStep) == 0
			if focus_origin(iStep+1) == 1
				focus_dw(iStep) = focus_rest(iStep);
			elseif focus_origin(iStep+1) == -1
				focus_mfi(iStep) = focus_rest(iStep);
			end
		elseif focus_origin(iStep) == 1
			if focus_origin(iStep+1) == 0
				focus_rest(iStep) = focus_dw(iStep);
			elseif focus_origin(iStep+1) == -1
				focus_mfi(iStep) = focus_dw(iStep);
			end
		elseif focus_origin(iStep) == -1
			if focus_origin(iStep+1) == 0
				focus_rest(iStep) = focus_mfi(iStep);
			elseif focus_origin(iStep+1) == 1
				focus_dw(iStep) = focus_mfi(iStep);
			end
		end
	end

	% line_color_mfi = [0, 0.4470, 0.7410];
	line_color_mfi = [139,0,139]/255;
	line_color_dw = [186,85,211]/255;
	line_color_rest = [176,196,222]/255;

	sources = getObject(htm, 'all', 'source');
	for iObject = 1:nb_sources
		focus_mfi(focus_mfi == iObject) = sources(iObject);
		focus_dw(focus_dw == iObject) = sources(iObject);
		focus_rest(focus_rest == iObject) = sources(iObject);
	end

	focus_mfi = -focus_mfi;
	focus_dw = -focus_dw;
	focus_rest = -focus_rest;

	focus_mfi(focus_mfi == 0) = 0.8;
	focus_dw(focus_dw == 0) = 0.8;
	focus_rest(focus_rest == 0) = 0.8;

	for ii = 1:nb_sources
		focus_mfi(focus_mfi == -ii) = -ii+0.9;
		focus_dw(focus_dw == -ii) = -ii+0.9;
		focus_rest(focus_rest == -ii) = -ii+0.9;
	end
	focus_mfi(focus_mfi ~= 0.8) = focus_mfi(focus_mfi ~= 0.8)-0.4;
	focus_dw(focus_dw ~= 0.8) = focus_dw(focus_dw ~= 0.8)-0.4;
	focus_rest(focus_rest ~= 0.8) = focus_rest(focus_rest ~= 0.8)-0.4;

	sources_labels = {};
	
	figure('Color', 'white');
	hold on;
	
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
				rectangle('Position', [iTimeline(iStep), 0.1-iSource, w, 0.8], 'FaceColor', [0.8,0.8,0.8], 'EdgeColor', [169,169,169]/255);
				% rectangle('Position', [iTimeline(iStep), 0.1-iSource, w, 0.8], 'FaceColor', [220,220,220]/255, 'EdgeColor', [169,169,169]/255);
			end
		end

		% plot(vec-iSource, 'LineWidth', 2);

		tmp_label = htm.gtruth{iSource}(iTimeline(2), 1);
		uscore = cell2mat(strfind(tmp_label, '_'));
		sources_labels(end+1) = {[tmp_label{1}(1:uscore-1), ' ', tmp_label{1}(uscore+1:end)]};
	end

	focus_naive = getNaiveBehavior(htm);
	focus_naive = -focus_naive;
	focus_naive(focus_naive == 0) = 0.8;
	for ii = 1:info.nb_sources
		focus_naive(focus_naive == -ii) = -ii+0.9;
	end
	focus_naive(focus_naive ~= 0.8) = focus_naive(focus_naive ~= 0.8)-0.4;
	plot(focus_naive, 'LineWidth', 3, 'LineStyle', '-', 'Color', [1, 0.4, 0.4]);

	plot(focus_mfi, 'LineWidth', 4, 'LineStyle', '-', 'Color', line_color_mfi);
	plot(focus_dw, 'LineWidth', 4, 'LineStyle', '-', 'Color', line_color_dw);
	plot(focus_rest, 'LineWidth', 4, 'LineStyle', '-', 'Color', line_color_rest);
	

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









