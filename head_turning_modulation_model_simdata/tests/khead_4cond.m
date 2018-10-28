
nb_steps = 1000;
nb_sources = 10;
data(1, 4) = struct('stats', [],...
					'etime', 0,...
					'focus', [],...
					'timeline', [],...
					'labels', []);

cfile = 11:14;
for iData = 1:4
	CONFIG_FILE = cfile(iData);

	data(iData).angles_cpt = cell(1, 5);

	data(iData).stats = struct('mfi1', zeros(nb_steps, 5),...
							   'mfi2', zeros(nb_steps, 5),...
							   'max1', zeros(nb_steps,5),...
							   'max2', zeros(nb_steps,5));
	data(iData).focus = zeros(nb_steps, 5);

	data(iData).timeline = cell(1, 5);
	data(iData).labels = cell(1, 5);
	data(iData).etime = 0;

	for ii = 1:5
		disp(['SIMULATION : ', num2str(ii)])
		startHTM_simulation;
		data(iData).stats.mfi1(:, ii) = htm.statistics.mfi_mean(:, end);
		data(iData).stats.mfi2(:, ii) = htm.statistics.mfi_mean2(:, end);
		data(iData).stats.max1(:, ii) = htm.statistics.max_mean(:, end);
		data(iData).stats.max2(:, ii) = htm.statistics.max_mean2(:, end);
		data(iData).angles_cpt{ii} = htm.FCKS.naive_focus;
		data(iData).etime = htm.elapsed_time + data(iData).etime;
		data(iData).focus(:, ii) = htm.FCKS.focus';
		tline = getInfo('timeline');
		data(iData).timeline{:, ii} = tline;
		data(iData).labels{:, ii} = arrayfun(@(x) htm.gtruth{x}(tline{x}(2), 1), 1:nb_sources);
		% data(iData).naive_shm = htm.naive_shm;
	end
end


nb_steps = size(data(1).stats.mfi1, 1);
t = (1:nb_steps)';
colors = [0, 1, 1 ;...
		  0, 0.7, 1;...
		  0, 0.4, 0.8;...
		  0, 0, 0.6];

bar_data = [0, 0];

for iData = 1:4
	% hf = figure('Color', 'white');
	% ha = axes('Parent', hf, 'FontSize', 20);
	% ha = subplot(1, 6, [1:4]);
	% hold on;

	x_mfi1 = data(iData).stats.mfi1;
	x_mfi2 = data(iData).stats.mfi2;
	x_max1 = data(iData).stats.max1;
	x_max2 = data(iData).stats.max2;

	% ===
	% s_min = min(x_mfi1')';
	% s_max = max(x_mfi1')';
	% m = mean(x_mfi1, 2);

	% X = [t', fliplr(t')];
	% Y = [s_min', fliplr(s_max')];

	% h1 = fill(X, Y, colors(1, :));
	% set(h1, 'EdgeAlpha', 0);
	% alpha(0.8)

	std_all1 = std(x_mfi1(end, :));
	dd1 = mean(x_mfi1(end, :));

	% plot(t, m);

	% ===
	% s_min = min(x_mfi2')';
	% s_max = max(x_mfi2')';	
	% m = mean(x_mfi2, 2);

	% X = [t', fliplr(t')];
	% Y = [s_min', fliplr(s_max')];

	% h2 = fill(X, Y, colors(2, :));
	% set(h2, 'EdgeAlpha', 0);
	% alpha(0.8)
	% plot(t, m);

	std_all2 = std(x_mfi2(end, :));
	dd2 = mean(x_mfi2(end, :));


	% ===
	% s_min = min(x_max1')';
	% s_max = max(x_max1')';	
	% m = mean(x_max1, 2);

	% X = [t', fliplr(t')];
	% Y = [s_min', fliplr(s_max')];

	% h3 = fill(X, Y, colors(3, :));
	% set(h3, 'EdgeAlpha', 0);
	% alpha(0.8)
	 
	std_all3 = std(x_max1(end, :));
	dd3 = mean(x_max1(end, :));


	% plot(t, m);

	% ===
	% s_min = min(x_max2')';
	% s_max = max(x_max2')';	
	% m = mean(x_max2, 2);

	% X = [t', fliplr(t')];
	% Y = [s_min', fliplr(s_max')];

	% h4 = fill(X, Y, colors(4, :));
	% set(h4, 'EdgeAlpha', 0);
	% alpha(0.8)

	std_all4 = std(x_max2(end, :));
	dd4 = mean(x_max2(end, :));
	% plot(t, m);

	% figure;
	bar_data = [bar_data ;...
				dd1, std_all1 ;...
			    dd2, std_all2 ;...
			    dd3, std_all3 ;...
			    dd4, std_all4 ;...
			    0, 0];
	% set(ha, 'YLim', [0, 1]);
end


bar_data(1, :) = [];





figure
hold on;
for ii = 1:4
	plot(mean(data(ii).stats.mfi1, 2));
end
figure
hold on;
for ii = 1:4
	plot(mean(data(ii).stats.mfi2, 2))
end
figure
hold on;
for ii = 1:4
	plot(mean(data(ii).stats.max1, 2))
end
figure
hold on;
for ii = 1:4
	plot(mean(data(ii).stats.max2, 2))
end


focus_all = zeros(4, nb_sources);
naive_all = zeros(4, nb_sources);

for iData = 1:4
	for iExpe = 1:5
		tmp_focus = zeros(1, nb_sources);
		for iStep = 2:nb_steps
			if data(iData).focus(iStep-1, iExpe) ~= data(iData).focus(iStep, iExpe) && data(iData).focus(iStep, iExpe) ~= 0
				tmp_focus(data(iData).focus(iStep, iExpe)) = tmp_focus(data(iData).focus(iStep, iExpe))+1;
			end
		end
		focus_all(iData, :) = focus_all(iData, :) + tmp_focus;
		naive_all(iData, :) = naive_all(iData, :) + data(iData).angles_cpt{iExpe};
	end
	focus_all(iData, :) = focus_all(iData, :)/5;
	naive_all(iData, :) = naive_all(iData, :)/5;
end

figure('Color', 'white');
h = bar([0.9+(0:3)], sum(focus_all')', 0.15, 'EdgeColor', 'none', 'FaceColor', [0 0.4470 0.7410]);
hold on;
h2 = bar([0.1+(1:4)], sum(naive_all')', 0.15, 'EdgeColor', 'none', 'FaceColor', 'red');
set(gca, 'XTick', 1:4, 'XTickLabels', 0.1:0.3:1, 'FontSize', 20, 'XLim', [0.7, 4.3]);



t = (1:nb_steps)';
colors = [0, 1, 1 ;...
		  0, 0.7, 1;...
		  0, 0.4, 0.8;...
		  0, 0, 0.6];

bar_data = [0, 0];

for iData = 1:4
	hf = figure('Color', 'white');
	ha = axes('Parent', hf, 'FontSize', 20);
	% ha = subplot(1, 6, [1:4]);
	hold on;

	x_mfi1 = data(iData).stats.mfi1;
	x_mfi2 = data(iData).stats.mfi2;
	x_max1 = data(iData).stats.max1;
	x_max2 = data(iData).stats.max2;

	% ===
	s_min = min(x_mfi1')';
	s_max = max(x_mfi1')';	
	m = mean(x_mfi1, 2);

	X = [t', fliplr(t')];
	Y = [s_min', fliplr(s_max')];

	h1 = fill(X, Y, colors(1, :));
	set(h1, 'EdgeAlpha', 0);
	alpha(0.8)

	std_all1 = mean(std(x_mfi1'));
	dd1 = mean(x_mfi1(end, :));

	plot(t, m);

	% ===
	s_min = min(x_mfi2')';
	s_max = max(x_mfi2')';	
	m = mean(x_mfi2, 2);

	X = [t', fliplr(t')];
	Y = [s_min', fliplr(s_max')];

	h2 = fill(X, Y, colors(2, :));
	set(h2, 'EdgeAlpha', 0);
	alpha(0.8)
	plot(t, m);

	std_all2 = mean(std(x_mfi2'));
	dd2 = mean(x_mfi2(end, :));


	% ===
	s_min = min(x_max1')';
	s_max = max(x_max1')';	
	m = mean(x_max1, 2);

	X = [t', fliplr(t')];
	Y = [s_min', fliplr(s_max')];

	h3 = fill(X, Y, colors(3, :));
	set(h3, 'EdgeAlpha', 0);
	alpha(0.8)
	 
	std_all3 = mean(std(x_max1'));
	dd3 = mean(x_max1(end, :));


	plot(t, m);

	% ===
	s_min = min(x_max2')';
	s_max = max(x_max2')';	
	m = mean(x_max2, 2);

	X = [t', fliplr(t')];
	Y = [s_min', fliplr(s_max')];

	h4 = fill(X, Y, colors(4, :));
	set(h4, 'EdgeAlpha', 0);
	alpha(0.8)

	std_all4 = mean(std(x_max2'));
	dd4 = mean(x_max2(end, :));
	plot(t, m);

	% figure;
	bar_data = [bar_data ;...
				dd1, std_all1 ;...
			    dd2, std_all2 ;...
			    dd3, std_all3 ;...
			    dd4, std_all4 ;...
			    0, 0];
end



bar_data(1, :) = [];

iData = 1;
figure('Color', 'white');
xx = iData;
h = bar(1, bar_data(iData, 1), 'FaceColor', colors(1, :), 'EdgeColor', 'none');
hold on;
for iData = 2:4
	xx = iData;
	bar(xx, bar_data(iData, 1), 'FaceColor', colors(xx, :), 'EdgeColor', 'none');
	set(gca, 'XTick', 1:4, 'XTickLabels', 0.1:0.3:1, 'FontSize', 20, 'YLim', [0, 1], 'XLim', [0.7, 4.3]);
end