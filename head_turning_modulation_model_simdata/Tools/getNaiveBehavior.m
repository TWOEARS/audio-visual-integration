function naive_focus = getNaiveBehavior (htm)

	info = htm.information;
	tline = info.timeline;

	naive_focus = zeros(1, info.nb_steps);
	naive_focus = [];

	bool = true;

	while bool
		val = zeros(1, info.nb_sources)+info.nb_steps+1;
		for iSource = 1:info.nb_sources
			if numel(tline{iSource}) >= 2
				val(iSource) = tline{iSource}(2);
			end
		end
		
		n = arrayfun(@(x) numel(tline{x}), 1:info.nb_sources);
		if all(n <= 2)
			bool = false;
		else
			pos = find(n > 2);
			% [val, m] = min([val, tline{iSource}(2)]);
			[val, m] = min(val(pos));
			naive_focus(1:2, end+1) = [val ; pos(m)];
			tline{pos(m)}(2:3) = [];
		end
	end

	tmp = zeros(1, info.nb_steps);
	
	for iStep = 1:size(naive_focus, 2)-1
		idx = naive_focus(1, iStep):naive_focus(1, iStep+1);
		tmp(idx) = naive_focus(2, iStep);
	end
	idx = naive_focus(1, end):info.nb_steps;
	tmp(idx) = naive_focus(2, end);

	naive_focus = tmp;