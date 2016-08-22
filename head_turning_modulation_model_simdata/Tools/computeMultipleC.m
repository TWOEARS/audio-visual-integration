function computeMultipleC (htm)

	msom_weights = getappdata(0, 'msom_weights');

	vec = 0 :0.1: 1;

	n = numel(htm.statistics.c);
	m = zeros(n, size(htm.statistics.c{1}, 2));
	s = zeros(n, size(htm.statistics.c{1}, 2));

	Y = [vec, fliplr(vec)];

	for ii = 1:size(msom_weights, 1);
		htm.MSOM.som_weights{1} = msom_weights{ii, 1};
		htm.MSOM.som_weights{2} = msom_weights{ii, 2};
		computeStatistics(htm);
		cc = [];
		for jj = 1:n, cc = [cc ; htm.statistics.c{jj}];end
		m(ii, :) = mean(cc);
		s(ii, :) = var(cc);

		
		subplot(5, 2, ii);

		X = [m(ii, :)-s(ii, :), fliplr(m(ii,:)+s(ii,:))];
		fill(Y, X, [51 153 255]/255, 'LineStyle', 'none');
		hold on;
		plot(vec, m(ii, :), 'LineWidth', 2, 'Color', 'blue');

		% x = 0:0.01:1;
		% y = sigmf(x, [10, 0.5]);

		% plot(x, y, 'LineWidth', 2, 'LineStyle', ':', 'Color', 'red');
		
		ylim([0, 1]);
		
		title(['step: ', num2str(ii*getInfo('nb_steps')/10), ' -- mfi=', num2str(htm.statistics.mfi_mean(ii*getInfo('nb_steps')/10))]);
	end

end