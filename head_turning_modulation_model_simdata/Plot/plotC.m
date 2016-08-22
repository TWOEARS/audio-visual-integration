function plotC (htm)

	c = htm.statistics.c;

	vec = htm.statistics.vec;

	sc = getInfo('scenario');
	idx = [sc.unique_idx, sc.unique_idx+getInfo('nb_AVPairs')];
	c = c(idx);

	vec2 = 0 :1/(numel(idx)+1): 1;

	cc = [];
	for ii = 1:numel(c), cc = [cc ; c{ii}];end
	
	% plot(vec, mean(cc)+std(cc), 'LineWidth', 3, 'Color', 'r');
	% plot(vec, mean(cc)-std(cc), 'LineWidth', 3, 'Color', 'r');

	min_c = min(cc);
	max_c = max(cc);
	
	figure;
	hold all;

	X = [min_c, fliplr(max_c)];
	Y = [vec, fliplr(vec)];
	fill(Y, X, [51 255 255]/255, 'LineStyle', 'none');

	X = [mean(cc)-var(cc), fliplr(mean(cc)+var(cc))];
	fill(Y, X, [51 153 255]/255, 'LineStyle', 'none');

	for iStat = 1:numel(c)
		C = repmat(vec2(iStat), 3, 1);
		plot(vec, c{iStat}, 'LineWidth', 3, 'Color', C);
	end

	line([0, vec(end)], [0.5, 0.5], 'LineWidth', 3, 'Color', 'k', 'LineStyle', '--');
	line([0, vec(end)], [0.75, 0.75], 'LineWidth', 2, 'Color', 'k', 'LineStyle', '--');
	line([0, vec(end)], [0.9, 0.9], 'LineWidth', 1, 'Color', 'k', 'LineStyle', '--');

	line([0, vec(end)], [1, 1], 'LineWidth', 0.75, 'Color', 'k', 'LineStyle', '--');

	x = 0:0.01:1;
	y = sigmf(x, [10, 0.5]);

	plot(x, y, 'LineWidth', 2, 'LineStyle', ':', 'Color', 'red');
	
	set(gca, 'YLim', [0, 1],...
			 'XTick', vec,...
		     'XTickLabel', vec);

	xlabel('value');
	ylabel('mean of good correction over 100 tries');

end
