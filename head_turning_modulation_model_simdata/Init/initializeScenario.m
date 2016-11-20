function initializeScenario (htm, init_scenario)

	if nargin == 1
		init_scenario = true;
	end

	% --- DISPLAY --- %
	% textprogressbar('HTM: generating the simulated scenario -- ')
	% disp('HTM: initialization of simulated scenario');
	% pause(0.25);
	% disp('..................................................');
	% --- DISPLAY --- %

	info = getInfo('all');

	simulated_data = cell(1, info.nb_sources);

	ground_truth = cell(1, info.nb_sources);
	ground_truth_stats = cell(1, info.nb_sources);

	timeline_all = cell(1, 5);

	scene = info.scenario.scene{end};
	for iSource = 1:info.nb_sources
		simulated_data{iSource} = zeros(info.nb_labels, info.nb_steps);
		ground_truth{iSource} = repmat({'none_none'}, info.nb_steps, 2);

		ground_truth_stats{iSource} = ones(info.nb_steps, 2);
		
		% --- Find designated AVpair for this source
		for ii = 1:numel(info.repartition)
			if sum(info.repartition{ii} == iSource) > 0
				pos = ii;
			end
		end
		avpair = scene(pos);
		visual_label = info.AVPairs{avpair}{1};
		audio_label = info.AVPairs{avpair}{2};
		

		% --- generating time indexes for silence phases and emission phases
		timeline = 1;
		iStep = 1;
		while iStep <= info.nb_steps - (info.cpt_object(2)+info.cpt_silence(2))+1
			iStep = iStep + randi(info.cpt_silence, 1);
			timeline(end+1) = iStep;
			iStep = iStep + randi(info.cpt_object, 1);
			timeline(end+1) = iStep;
		end
		iStep = iStep + randi(info.cpt_silence, 1);
		timeline(end+1) = iStep;
		timeline(end+1) = info.nb_steps;

		tmp_visual_idx = find(strcmp(visual_label, info.visual_labels));
       	tmp_audio_idx = find(strcmp(audio_label, info.audio_labels));
       	
       	ground_truth{iSource}(timeline(2):end, 1) = repmat({mergeLabels(avpair)}, numel(timeline(2):info.nb_steps), 1);
       	ground_truth{iSource}(timeline(2):end, 2) = repmat({mergeLabels(avpair)}, numel(timeline(2):info.nb_steps), 1);
       	
       	ground_truth_stats{iSource}(1:timeline(2), 1) = 0;
		
		for iStep = 2 :2 :numel(timeline)-1 % only object tmIdx
			for iTmIdx = timeline(iStep):timeline(iStep+1);
				decision = rand;
				% --- Simulate classification errors
				% ground_truth{iSource}{iTmIdx, 1} = mergeLabels(avpair);
				if decision > info.epsilon %|| ~isempty(find(tsteps == iStep)) % --- no error inserted
					visual_idx = tmp_visual_idx;
					audio_idx = tmp_audio_idx;
					ground_truth{iSource}{iTmIdx, 2} = mergeLabels(avpair);
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
					ground_truth{iSource}{iTmIdx, 2} = mergeLabels(visual_idx, audio_idx);
					ground_truth_stats{iSource}(iTmIdx, 1) = 0;
	            end
				simulated_data{iSource}(:, iTmIdx) = generateProbabilities(audio_idx, visual_idx);
			end
		end
		timeline_all{iSource} = timeline;
	end

	% setInfo('timeline', timeline_all);
	global information;
	information.timeline = timeline_all;


% =====================
	htm.statistics.max = zeros(info.nb_steps, info.nb_sources);
	tmp = zeros(info.nb_steps, info.nb_sources);
	for iSource = 1:info.nb_sources
		tmp(:, iSource) = cumsum(ground_truth_stats{iSource}(:, 1)) ./ (1:info.nb_steps)';
		htm.statistics.max(:, iSource) = ground_truth_stats{iSource}(:, 1);
	end
	ground_truth_stats = tmp;

	% if init_scenario
	% 	groundTruth_stats(:, 2) = cumsum(groundTruth_stats(:, 1)) ./ (1:info.nb_steps)';
 %    else
 %        tmp = zeros(htm.nb_steps_final, 2);
	% 	tmp(:, 1) = [htm.statistics.max ; groundTruth_stats(:, 1)];
	% 	tmp(:, 2) = cumsum(tmp(:, 1)) ./ (1:htm.nb_steps_final)';
 %        groundTruth_stats = tmp;
	% end

	% =====================

	if init_scenario
		htm.data = simulated_data;
		% htm.gtruth = groundTruth;
		htm.gtruth = ground_truth;
		htm.gtruth_data = simulated_data;
		% htm.statistics.max = groundTruth_stats(:, 1);
		htm.statistics.max_mean = [ground_truth_stats, zeros(info.nb_steps, 1)];
		% htm.statistics.max_mean(:, end) = mean(htm.statistics.max_mean, 2);
		% htm.statistics.max_mean = groundTruth_stats(:, 2);
		htm.statistics.max_shm = htm.statistics.max;
		htm.statistics.max_mean_shm = htm.statistics.max_mean;
		htm.statistics.max_mean_shm(:, end+1) = zeros(info.nb_steps, 1);
		htm.statistics.mfi = zeros(info.nb_steps, info.nb_sources);
		htm.statistics.mfi_mean = zeros(info.nb_steps, info.nb_sources+1);
		% htm.sources = sources;
		htm.classif_mfi = cell(1, 5);
        for iSource = 1:getInfo('nb_sources')
            htm.classif_mfi{iSource} = repmat({'none_none'}, getInfo('nb_steps'), 1);
        end
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
	% textprogressbar(' -- DONE');
	% disp('HTM: initialization of simulated scenario -- DONE');

end
