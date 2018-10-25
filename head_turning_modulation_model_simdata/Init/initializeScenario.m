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

	n = [0, 16];
	cpt_generation = 0;

	if getInfo('load_timeline') == 0
		while std(n) > 8
			if cpt_generation > 1
				disp('=============');
				disp('Regeneration of a scenario');
				disp('=============');
				pause(1);
			end

			timeline_all = createTimeline();

			if info.load_timeline
				n = [0, 2];
			else
				n = arrayfun(@(x) numel(timeline_all{x}), 1:numel(timeline_all));
			end

			if std(n) > 10
				cpt_generation = cpt_generation +1;
			end
		end
	else
		% timeline_all = getappdata(0, 'timeline');
		timeline_all = getappdata(0, 'tline');
	end

	simulated_data = cell(1, info.nb_sources);

	ground_truth = cell(1, info.nb_sources);
	ground_truth_stats = cell(1, info.nb_sources);

	% timeline_all = cell(1, info.nb_sources);

	% if info.load_timeline
	% 	timeline_loaded = getappdata(0, 'tline');
	% end

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
		

		% % --- generating time indexes for silence phases and emission phases
		% timeline = 1;
		% iStep = 1;
		% while iStep <= info.nb_steps - (info.cpt_object(2)+info.cpt_silence(2))+1
		% 	iStep = iStep + randi(info.cpt_silence, 1);
		% 	timeline(end+1) = iStep;
		% 	iStep = iStep + randi(info.cpt_object, 1);
		% 	timeline(end+1) = iStep;
		% end
		% iStep = iStep + randi(info.cpt_silence, 1);
		% timeline(end+1) = iStep;
		% timeline(end+1) = info.nb_steps;
       	timeline = timeline_all{iSource};

		% if info.load_timeline
		% 	timeline = timeline_all{iSource};
		% end


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
					if decision >= 0 % --- audio
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
		% timeline_all{iSource} = timeline;
	end

	
	% === Simultaneous sources
	% cpt = 0;
	% for iStep = 2:info.nb_steps
	% 	for iSource = 1:info.nb_sources
	% 		if sum(simulated_data{iSource}(:, iStep-1)) == 0 && sum(simulated_data{iSource}(:, iStep)) > 0 % object starts emitting
	% 			if cpt == info.nb_simultaneous_sources
	% 				t = find(timeline_all{iSource} <= iStep, 1, 'last');
 %                    if t > numel(timeline_all{iSource})+2
 %                        simulated_data{iSource}(:, timeline_all{iSource}(t):timeline_all{iSource}(t+1)) = 0;
 %                        timeline_all{iSource}(t) = [];
 %                        timeline_all{iSource}(t) = [];
 %                    end
	% 			else
	% 				cpt = cpt+1;
	% 			end
	% 		elseif sum(simulated_data{iSource}(:, iStep-1)) > 0 && sum(simulated_data{iSource}(:, iStep)) == 0 % object has stopped emitting
	% 			cpt = cpt-1;
	% 		end
	% 	end
	% end

	% cpt = 0;





	% for iStep = 2:info.nb_steps
	% 	for iSource = 1:info.nb_sources
	% 		if sum(simulated_data{iSource}(:, iStep-1)) == 0 && sum(simulated_data{iSource}(:, iStep)) > 0 % object starts emitting
	% 			if cpt == info.nb_simultaneous_sources
	% 				t = find(timeline_all{iSource} <= iStep, 1, 'last');
 %                    if t > numel(timeline_all{iSource})+2
 %                        simulated_data{iSource}(:, timeline_all{iSource}(t):timeline_all{iSource}(t+1)) = 0;
 %                        timeline_all{iSource}(t) = [];
 %                        timeline_all{iSource}(t) = [];
 %                    end
	% 			else
	% 				cpt = cpt+1;
	% 			end
	% 		elseif sum(simulated_data{iSource}(:, iStep-1)) > 0 && sum(simulated_data{iSource}(:, iStep)) == 0 % object has stopped emitting
	% 			cpt = cpt-1;
	% 		end
	% 	end
	% end

	% for iSource = 1:info.nb_sources
	% 	tt = find(timeline_all{iSource} > info.nb_steps);
	% 	if ~isempty(tt)
	% 		timeline_all{iSource}(tt:end) = [];
	% 	end
	% end


	% if info.load_timeline
	% 	n = [0, 2];
	% else
	% 	n = arrayfun(@(x) numel(timeline_all{x}), 1:numel(timeline_all));
	% end

	% if std(n) > 4
	% 	cpt_generation = cpt_generation +1;
	% end

% end
	
% setInfo('timeline', timeline_all);
global information;
information.timeline = timeline_all;


% =====================
% htm.statistics.max = zeros(info.nb_steps, info.nb_sources);
% tmp = zeros(info.nb_steps, info.nb_sources);
% tmp2 = zeros(info.nb_steps, info.nb_sources);
% for iSource = 1:info.nb_sources
% 	pos = find(ground_truth_stats{iSource}(:, 1) > 0, 1, 'first');
% 	tmp(pos:end, iSource) = cumsum(ground_truth_stats{iSource}(pos:end, 1)) ./ (1:((info.nb_steps-pos)+1))';
% 	tmp2(:, iSource) = cumsum(ground_truth_stats{iSource}(:, 1)) ./ (1:info.nb_steps)';
% 	htm.statistics.max(:, iSource) = ground_truth_stats{iSource}(:, 1);
% end
% ground_truth_stats = tmp;

% =====================

if init_scenario
	htm.data = simulated_data;
	% htm.gtruth = groundTruth;
	htm.gtruth = ground_truth;
	htm.gtruth_data = simulated_data;
	% htm.statistics.max = groundTruth_stats(:, 1);
	% htm.statistics.max_mean = [ground_truth_stats, zeros(info.nb_steps, 1)];
	htm.statistics.max = zeros(info.nb_steps, info.nb_sources);
	htm.statistics.max2 = zeros(info.nb_steps, info.nb_sources);
	htm.statistics.max_mean = zeros(info.nb_steps, info.nb_sources+1);
	htm.statistics.max_mean2 = zeros(info.nb_steps, info.nb_sources+1);
	htm.statistics.max_mean3 = zeros(info.nb_steps, info.nb_sources+1);
	% htm.statistics.max_mean2 = [tmp2, zeros(info.nb_steps, 1)];
	% htm.statistics.max_mean(:, end) = mean(htm.statistics.max_mean, 2);
	% htm.statistics.max_mean = groundTruth_stats(:, 2);
	htm.statistics.max_shm = htm.statistics.max;
	htm.statistics.max_mean_shm = htm.statistics.max_mean;
	htm.statistics.max_mean_shm(:, end+1) = zeros(info.nb_steps, 1);
	htm.statistics.mfi = zeros(info.nb_steps, info.nb_sources);
	% htm.statistics.mfi2 = zeros(info.nb_steps, info.nb_sources);
	htm.statistics.mfi_mean = zeros(info.nb_steps, info.nb_sources+1);
	htm.statistics.mfi_mean2 = zeros(info.nb_steps, info.nb_sources+1);
	% htm.sources = sources;
	htm.classif_mfi = cell(1, info.nb_sources);
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

end
