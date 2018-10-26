wvectors = getappdata(0, 'wvectors');


info = htm.information;
ndim = htm.MSOM.som_dimension(1);

labels = getObject(htm, 'all', 'label');
[labels, ulabels] = unique(labels);

[X, Y] = meshgrid(1:ndim);


labels{iObject}(strfind(labels{iObject}, '_')) = ' ';
	
	d = retrieveObservedData(htm, ulabels(iObject), 'best');

	f = figure('Color', 'white');
	cpt = 0;
	for ii = 1:12
		cpt = cpt+1;
		subplot(3,4,cpt);
		htm.MSOM.weights_vectors = wvectors{ii};
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
		hs = surf(X, Y, dist1);%, gradient(dist1));
		% c = colorbar;
		set(gca, 'XLim', [0, ndim]+1,...
				 'YLim', [0, ndim]+1,...
				 'ZGrid', 'off',...
				 'ZColor', [1, 1, 1],...
				 'View', [-58.5, 55]);
		% 'View', [-58.5, 48]);
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
		plot3(idx1+0.5, idx2+0.5, m(1)+0.02, '.','MarkerSize', 40, 'Color', [0, 0, 0]);
	end



