function timeline_all = createTimeline (varargin)

	if nargin == 0
		if getInfo('load_timeline')
			timeline_all = getappdata(0, 'timeline');
			return;
		else
			info = getInfo('all');
		end
	else
		info = varargin{1};
	end
	
	nb_sources = info.nb_sources;
	nb_simultaneous_sources = info.nb_simultaneous_sources;
	nb_steps = info.nb_steps;
	cpt_object = info.cpt_object;
	cpt_silence = info.cpt_silence;
	
	timeline_all = cell(1, nb_sources);

	for iSource = 1:nb_sources
		timeline = 1;
		iStep = 1;
		while iStep <= nb_steps - (cpt_object(2)+cpt_silence(2))+1
			iStep = iStep + randi(cpt_silence, 1);
			timeline(end+1) = iStep;
			iStep = iStep + randi(cpt_object, 1);
			timeline(end+1) = iStep;
		end
		iStep = iStep + randi(cpt_silence, 1);
		timeline(end+1) = iStep;
		timeline(end+1) = nb_steps;
		timeline_all{iSource} = timeline;
	end

	
	idx_beg = arrayfun(@(x) timeline_all{x}(2), 1:nb_sources);
	[~, idx_beg] = min(idx_beg);

	new_tline = timeline_all;
	
	iStep = new_tline{idx_beg}(2)+1;
	while iStep <= nb_steps
	% for iStep = new_tline{idx_beg}(2)+1:nb_steps
		tt = cell2mat(arrayfun(@(x) find(new_tline{x} <= iStep, 1, 'last'), 1:nb_sources, 'UniformOutput', false));
		if sum(mod(tt, 2) == 0) > nb_simultaneous_sources && ~isempty(tt)
			tmp = find(mod(tt, 2) == 0);
			tmp2 = arrayfun(@(x) iStep - new_tline{x}(tt(x)), tmp);
			tmp3 = find(tmp2 > cpt_object(1));
			if ~isempty(tmp3)
				for iSource = 1:numel(tmp3)
					idx = tmp(tmp3(iSource));
					new_tline{idx}(tt(idx)+1) = iStep;
				end
				tmp2(tmp3) = [];
				tmp(tmp3) = [];
                if numel(tmp2)-numel(tmp3) > 0
                    selected_sources = randi(numel(tmp2)-numel(tmp3), info.nb_simultaneous_sources);
                    for iSource = 1:numel(tmp)
                        if iSource ~= selected_sources
                            source = tmp(iSource);
                            new_tline{source}(tt(source):end) = new_tline{source}(tt(source):end)+1;
                        end
                    end
                end
				% sources_to_shift = tmp(tmp3);
			else
				[~, pos] = min(tmp2);
				sources_to_shift = tmp(pos);
				for iSource = 1:numel(sources_to_shift)
					idx = sources_to_shift(iSource);
					new_tline{idx}(tt(idx):end) = new_tline{idx}(tt(idx):end)+1;
				end
			end
			
		else
			iStep = iStep + 1;
		end
	end
	

	new_tline = arrayfun(@(x) new_tline{x}(new_tline{x} <= nb_steps), 1:numel(new_tline), 'UniformOutput', false);


	for iSource = 1:numel(new_tline)
		if numel(new_tline{iSource}) > 1
			if mod(numel(new_tline{iSource}), 2) == 0
				if numel(new_tline{iSource}(end):nb_steps) >= cpt_object(1)
					new_tline{iSource}(end+1) = nb_steps;
				else
					new_tline{iSource}(end) = nb_steps;
				end
			else
				if new_tline{iSource}(end) ~= nb_steps
					new_tline{iSource}(end+1) = nb_steps;
				end
			end
		else
			new_tline{iSource}(end+1) = nb_steps;
		end
	end

	timeline_all = new_tline;

end