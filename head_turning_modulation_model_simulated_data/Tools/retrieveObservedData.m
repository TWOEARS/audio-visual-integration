function data = retrieveObservedData (obj, idx, str)
	
	if isa(obj, 'PerceivedEnvironment')
		objects = obj.objects;
		RIR = obj.RIR;
	elseif isa(obj, 'HeadTurningModulationKS')
		objects = obj.RIR.getEnv().objects;
		RIR = obj.RIR;
	elseif isa(obj, 'RobotInternalRepresentation')
		objects = obj.getEnv().objects;
		RIR = obj;
	end
	if idx == 0
		idx = numel(objects);
	end
	if nargin == 2
		str = 'all';
	end

	tmIdx = objects{idx}.tmIdx;
	data = RIR.data(:, tmIdx);
	
	tmIdx = tmIdx - (tmIdx(1)-1);

	p = getInfo('smoothing'      ,...
			    'nb_audio_labels',...
			    'nb_visual_labels'...
			   );

	s = tmIdx(end) - tmIdx(1) + 1;
	if strcmp(str, 'best')
		if s < p.smoothing
			data = data(:, tmIdx(end));
		elseif s >= p.smoothing && s < 2*p.smoothing
			good_visual_data = getGoodVisualData();
			data = mean(data(1:p.nb_audio_labels, p.smoothing:end), 2);
		else
			good_visual_data = getGoodVisualData();
			data = mean(data(1:p.nb_audio_labels, p.smoothing:end-p.smoothing+1), 2);
		end
		data = [data ; mean(good_visual_data, 2)];
	elseif strcmp(str, 'all')
		data = data;
	end

	function request = getGoodVisualData ()
		
		cpt = find(sum(data(p.nb_audio_labels+1:end, :)) > 0.1);

		if isempty(cpt)
			request = zeros(p.nb_visual_labels, 1);
		else
			request = data(p.nb_audio_labels+1:end, cpt);
		end
	end

end