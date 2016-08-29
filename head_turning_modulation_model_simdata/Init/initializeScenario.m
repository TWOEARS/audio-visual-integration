function [simulatedData, groundTruth, groundTruth_stats] = initializeScenario (htm, varargin)


	p = inputParser();
	  p.addOptional('Initialize', true,...
	  				@islogical);
	p.parse(varargin{:});
	p = p.Results;

	% --- DISPLAY --- %
	textprogressbar('HTM: generating the simulated scenario -- ')
	% disp('HTM: initialization of simulated scenario');
	% pause(0.25);
	% disp('..................................................');
	% --- DISPLAY --- %

	info = getInfo('all');
    
	simulatedData = zeros(info.nb_labels, info.nb_steps);
	groundTruth = repmat({'none_none'}, info.nb_steps, 2);
	groundTruth_stats = ones(info.nb_steps, 2);

	scene = info.scenario.scene{end};

	% objects_idx = randi(info.nb_AVPairs, 1, info.nb_objects);
	objects_idx = randi(numel(info.scenario.scene{end}), 1, info.nb_objects);
	objects_idx = info.scenario.scene{end}(objects_idx);

	silence_tsteps = 1 :info.cpt_silence+info.cpt_object: info.nb_steps;
	object_tsteps = silence_tsteps+info.cpt_silence;
	tsteps = sort([silence_tsteps, object_tsteps]);

	for iStep = 1:info.nb_steps

		% --- DISPLAY --- %
		t = 100*(iStep/info.nb_steps);
		textprogressbar(t);
		% --- DISPLAY --- %
        
		idx = find(tsteps <= iStep, 1, 'last');
		if ~mod(idx, 2) % --- period of object
			object = objects_idx(idx/2);
            visual_label = info.AVPairs{object}{1};
			audio_label = info.AVPairs{object}{2};

			tmp_visual_idx = find(strcmp(visual_label, info.visual_labels));
            %tmp_visual_idx = tmp_visual_idx(randi(numel(tmp_visual_idx)));
			
            tmp_audio_idx = find(strcmp(audio_label, info.audio_labels));
			%tmp_audio_idx = tmp_audio_idx(randi(numel(tmp_audio_idx)));
            
			groundTruth{iStep, 1} = mergeLabels(object);
			decision = rand;
			% --- Simulate classification errors
			if decision > info.epsilon || ~isempty(find(tsteps == iStep)) % --- no error inserted
				visual_idx = tmp_visual_idx;
				audio_idx = tmp_audio_idx;
				groundTruth{iStep, 2} = mergeLabels(object);
			else % --- error inserted
				% --- Audio error or Visual error? (not both at the same time)
				decision = rand;
				if decision >= 0.5 % --- audio
					audio_idx = randi(info.nb_audio_labels);
					while (audio_idx == tmp_audio_idx)
						audio_idx = randi(info.nb_audio_labels);
					end
					visual_idx = tmp_visual_idx;
				else % --- visual
					visual_idx = randi(info.nb_visual_labels);
					while (visual_idx == tmp_visual_idx)
						visual_idx = randi(info.nb_visual_labels);
					end
					audio_idx = tmp_audio_idx;
				end
				groundTruth{iStep, 2} = mergeLabels(visual_idx, audio_idx);
				groundTruth_stats(iStep, 1) = 0;
            end
			simulatedData(:, iStep) = generateProbabilities(audio_idx, visual_idx);
		end

	end

	if p.Initialize
		groundTruth_stats(:, 2) = cumsum(groundTruth_stats(:, 1)) ./ (1:info.nb_steps)';
    else
        tmp = zeros(htm.nb_steps_final, 2);
		tmp(:, 1) = [htm.statistics.max ; groundTruth_stats(:, 1)];
		tmp(:, 2) = cumsum(tmp(:, 1)) ./ (1:htm.nb_steps_final)';
        groundTruth_stats = tmp;
	end



	if p.Initialize
		htm.data = simulatedData;
		htm.gtruth = groundTruth;
		htm.gtruth_data = simulatedData;
		htm.statistics.max = groundTruth_stats(:, 1);
		htm.statistics.max_mean = groundTruth_stats(:, 2);
		htm.statistics.max_shm = htm.statistics.max;
		htm.statistics.max_mean_shm = htm.statistics.max_mean;
	else
		htm.data = [htm.data, simulatedData];
		htm.gtruth = [htm.gtruth ; groundTruth];
		htm.gtruth_data = [htm.gtruth_data, simulatedData];
		htm.statistics.max = groundTruth_stats(:, 1);
		htm.statistics.max_mean = groundTruth_stats(:, 2);
		htm.statistics.max_shm = htm.statistics.max;
		htm.statistics.max_mean_shm = htm.statistics.max_mean;
	end

	pause(0.25)
	textprogressbar(' -- DONE');
	% disp('HTM: initialization of simulated scenario -- DONE');

end
