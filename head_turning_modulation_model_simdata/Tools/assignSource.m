function repartition = assignSource (scene, nb_sources)

	if isappdata(0, 'repartition')
		repartition = getappdata(0, 'repartition');
		return
	end

	repartition = cell(1, numel(scene));
	pairs = randperm(numel(scene));
	sources = randperm(nb_sources);

	nb_remaining_sources = nb_sources;
	nb_remaining_pairs = numel(scene);
	
	for iPair = pairs(1:end-1)

		nb_assigned_sources = randi(nb_remaining_sources-nb_remaining_pairs);
		idx_sources = randi(nb_remaining_sources, 1, nb_assigned_sources);
		repartition{iPair} = sources(idx_sources);
		sources(idx_sources) = [];
		nb_remaining_sources = nb_remaining_sources - nb_assigned_sources;
		nb_remaining_pairs = nb_remaining_pairs-1;

	end

	repartition{pairs(end)} = sources;

end