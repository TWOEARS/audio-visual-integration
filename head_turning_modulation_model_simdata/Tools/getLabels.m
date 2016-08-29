function labels = getLabels ()

	info = getInfo('scenario', 'AVPairs');

	labels = info.AVPairs(info.scenario.scene{1});

	% labels = mergeLabels(labels);

end
