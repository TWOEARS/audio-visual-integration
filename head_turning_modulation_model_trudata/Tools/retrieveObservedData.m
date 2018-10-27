function data = retrieveObservedData (obj, idx, str)

	if isa(obj, 'PerceivedEnvironment')
		objects = obj.objects;
		%RIR = obj.RIR;
        htm = obj.htm;
	elseif isa(obj, 'HeadTurningModulationKS')
        env = getEnvironment(obj, 0);
		objects = env.objects;
        htm = obj;
		%RIR = obj.RIR;
	elseif isa(obj, 'RobotInternalRepresentation')
        env = getEnvironment(obj, 0);
		objects = env.objects;
		%RIR = obj;
        htm = obj.htm;
	end
	if idx == 0
		idx = numel(objects);
	end
	if nargin == 2
		str = 'all';
    end


    p = getInfo('smoothing'      ,...
			    'nb_audio_labels',...
			    'nb_visual_labels'...
			   );

    iSource = getObject(htm, idx, 'source');

	tmIdx = getObject(htm, idx, 'tmIdx');

	tmIdx = processTmIdx();
	% data = htm.data{iSource}(:, tmIdx);
	
	% === CHANGES [beg] === %
	idx = min([10, numel(tmIdx)]);
	t = tmIdx(end-(idx-1):end);
	
	good_visual_data = getGoodVisualData();
	data = mean(htm.data(1:p.nb_audio_labels, t), 2);
	data = [data ; mean(good_visual_data, 2)];
	return;

	% tmIdx = objects{idx}.tmIdx;
	% data = htm.data(:, tmIdx);

	% tmIdx = tmIdx - (tmIdx(1)-1);

	% p = getInfo('smoothing',...
	% 			'nb_audio_labels',...
	% 			'nb_visual_labels');

	% s = tmIdx(end) - tmIdx(1) + 1;

	% if strcmp(str, 'best')
	% 	if s < p.smoothing
	% 		data = data(:, tmIdx(end));
	% 	elseif s >= p.smoothing && s < 2*p.smoothing
	% 		good_visual_data = getGoodVisualData();
	% 		data = mean(data(1:p.nb_audio_labels, p.smoothing:end), 2);
	% 	else
	% 		good_visual_data = getGoodVisualData();
	% 		data = mean(data(1:p.nb_audio_labels, p.smoothing:end-p.smoothing+1), 2);
	% 	end
	% 	data = [data ; mean(good_visual_data, 2)];
	% elseif strcmp(str, 'all')
	% 	data = data;
	% end

	% function request = getGoodVisualData ()
	% 	cpt = find(sum(data(p.nb_audio_labels+1:end, :)) > 0.1);

	% 	if isempty(cpt)
	% 		request = zeros(p.nb_visual_labels, 1);
	% 	else
	% 		request = data(p.nb_audio_labels+1:end, cpt);
	% 	end

	% end
	function request = getGoodVisualData ()
		
		% cpt = find(sum(data(p.nb_audio_labels+1:end, :)) > 0.1);
		cpt = find(sum(htm.data(p.nb_audio_labels+1:end, t)) > 0.1);

		if isempty(cpt)
			request = zeros(p.nb_visual_labels, 1);
		else
			% request = data(p.nb_audio_labels+1:end, cpt);
			request = htm.data(p.nb_audio_labels+1:end, t(cpt));
		end
	end

	function new_tmIdx = processTmIdx ()
		theta_a = getObject(htm, idx, 'theta');
		theta_v = getObject(htm, idx, 'theta_v');
		new_tmIdx = [];
		for iTime = 1:numel(tmIdx)
			theta_diff = abs(theta_a(iTime)-theta_v(iTime));
			if theta_diff < 20
				new_tmIdx(end+1) = tmIdx(iTime);
			end
		end
		if isempty(new_tmIdx)
			new_tmIdx = tmIdx(end);
		end
	end

end
		