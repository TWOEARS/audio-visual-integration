function plotTimeline (htm)

	if ~isa(htm, 'HeadTurningModulationKS')
		tline = htm;
		nb_sources = numel(tline);
		nb_steps = tline{1}(end);
		bool = false;
	else
		info = htm.information;
		tline = info.timeline;
		nb_sources = info.nb_sources;
		nb_steps = info.nb_steps;
		bool = true;
	end

	% tline = getInfo('timeline');
	% nb_sources = getInfo('nb_sources');
	% nb_steps = getInfo('nb_steps');

figure('Color', 'white');
hold on;

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

	if bool
		tmp_label = htm.gtruth{iSource}(iTimeline(2), 1);
		uscore = cell2mat(strfind(tmp_label, '_'));
		sources_labels(end+1) = {[tmp_label{1}(1:uscore-1), ' ', tmp_label{1}(uscore+1:end)]};
	end
end

ytick = (2*nb_sources-1)*(-0.5):-0.5;
ytick = [ytick, ytick+0.4, ytick-0.4];
ytick = sort(ytick);
yticklabels = {};
if bool
	for iSource = 1:nb_sources
		yticklabels{end+1} = '';
		yticklabels{end+1} = sources_labels{iSource};
		yticklabels{end+1} = '';
	end
end
% 'YTick', (2*nb_sources-1)*(-0.5):-0.5,...
% 'YTickLabel', sources_labels,...
set(gca, 'YTick', ytick,...
		 'YTickLabel', yticklabels,...
		 'YTickLabelRotation', 45,...
		 'FontSize', 20,...
		 'Box', 'on',...
		 'XGrid', 'on',...
		 'XMinorGrid', 'on');

