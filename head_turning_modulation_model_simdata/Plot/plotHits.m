
function plotHits(htm)

info = htm.information;
ndim = htm.MSOM.som_dimension(1);

labels = getObject(htm, 'all', 'label');
[labels, ulabels] = unique(labels);

[X, Y] = meshgrid(1:ndim);

for iObject = 1:numel(labels)
	labels{iObject}(strfind(labels{iObject}, '_')) = ' ';
	
	d = retrieveObservedData(htm, ulabels(iObject), 'best');
	% d = mean(d, 2);
	dist1 = sqrt(sum(bsxfun(@minus, d(1:info.nb_audio_labels)', htm.MSOM.weights_vectors{1}).^2, 2));
	dist2 = sqrt(sum(bsxfun(@minus, d(info.nb_audio_labels+1:end)', htm.MSOM.weights_vectors{2}).^2, 2));
	dist3 = dist1.*dist2;

	dist1 = reshape(dist1, htm.MSOM.som_dimension);
	dist2 = reshape(dist2, htm.MSOM.som_dimension);
	dist3 = reshape(dist3, htm.MSOM.som_dimension);

	dist1 = 1-(dist1 ./ (max(max(dist1))));
	dist2 = 1-(dist2 ./ (max(max(dist2))));
	dist3 = 1-(dist3 ./ (max(max(dist3))));

	% subplot(2, 2, 1);
	f = figure('Color', 'white');
	hs = surf(X, Y, dist1);%, gradient(dist1));
	% c = colorbar;
	set(gca, 'XLim', [0, ndim]+1,...
			 'YLim', [0, ndim]+1,...
			 'ZGrid', 'off',...
			 'ZColor', [1, 1, 1],...
			 'View', [-58.5, 60]);
	cc = get(hs, 'CData');
	[~, m1] = max(cc);
	[~, m2] = max(max(cc));
	
	if m2 >= 26
		idx1 = 25;
	else
		idx1= m2;
	end
	if m1(m2) >= 26
		idx2 = 25;
	else
		idx2 = m1(m2);
	end

	cc(m1(m2), m2) = 1.15;
	set(hs, 'CData', cc);
	hold on;
	m = max(max(dist1));
	plot3(idx1+0.5, idx2+0.5, m(1)+0.01, '.','MarkerSize', 50, 'Color', 'k');

	% uscore = strfind(labels{iObject}, '_');
	
	title([labels{iObject}, ' -- SRa'], 'FontSize', 20);
	% set(c, 'TickLabels', [0:0.2:1]);
	
	f = figure('Color', 'white');
	hs = surf(X, Y, dist2);%, gradient(dist2));
	% c = colorbar;
	set(gca, 'XLim', [1, ndim],...
			 'YLim', [1, ndim],...
			 'ZGrid', 'off',...
			 'ZColor', [1, 1, 1],...
			 'View', [-58.5, 60]);
	cc = get(hs, 'CData');
	[~, m1] = max(cc);
	[~, m2] = max(max(cc));
	if m2 >= 26
		idx1 = 25;
	else
		idx1= m2;
	end
	if m1(m2) >= 26
		idx2 = 25;
	else
		idx2 = m1(m2);
	end
	cc(m1(m2), m2) = 1.15;
	set(hs, 'CData', cc);
	hold on;
	m = max(max(dist2));
	plot3(idx1+0.5, idx2+0.5, m(1)+0.01, '.','MarkerSize', 50, 'Color', 'k');

	title([labels{iObject}, ' -- SRv'], 'FontSize', 20);

	f = figure('Color', 'white');
	hs = surf(X, Y, dist3);%, gradient(dist3));
	% c = colorbar;
	set(gca, 'XLim', [1, ndim],...
			 'YLim', [1, ndim],...
			 'ZGrid', 'off',...
			 'ZColor', [1, 1, 1],...
			 'View', [-58.5, 60]);
	cc = get(hs, 'CData');
	[~, m1] = max(cc);
	[~, m2] = max(max(cc));
	if m2 >= 26
		idx1 = 25;
	else
		idx1= m2;
	end
	if m1(m2) >= 26
		idx2 = 25;
	else
		idx2 = m1(m2);
	end
	cc(m1(m2), m2) = 1.15;
	set(hs, 'CData', cc);
	hold on;
	m = max(max(dist3));
	plot3(idx1+0.5, idx2+0.5, m(1)+0.01, '.','MarkerSize', 50, 'Color', 'k');

	title([labels{iObject}, ' -- SRav'], 'FontSize', 20);

end
	

