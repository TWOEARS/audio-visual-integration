function [simulatedData, groundTruth, groundTruth_stats] = initializeScenario ()

	disp('HTM: initialization of simulated scenario');
	pause(0.25);
	disp('..................................................');
	p = getInfo('all');
    
	simulatedData = zeros(p.nb_labels, p.nb_steps);
	groundTruth = repmat({'none_none'}, p.nb_steps, 2);
	groundTruth_stats = ones(p.nb_steps, 2);

	scene = p.scenario.scene{end};

	% objects_idx = randi(p.nb_AVPairs, 1, p.nb_objects);
	objects_idx = randi(numel(p.scenario.scene{end}), 1, p.nb_objects);
	objects_idx = p.scenario.scene{end}(objects_idx);

	silence_tsteps = 1 :p.cpt_silence+p.cpt_object: p.nb_steps;
	object_tsteps = silence_tsteps+p.cpt_silence;
	tsteps = sort([silence_tsteps, object_tsteps]);

	for iStep = 1:p.nb_steps
        
		idx = find(tsteps <= iStep, 1, 'last');
		if ~mod(idx, 2) % --- period of object
			object = objects_idx(idx/2);
            
			visual_label = p.AVPairs{object}{1};
			audio_label = p.AVPairs{object}{2};

			tmp_visual_idx = find(strcmp(visual_label, p.visual_labels));
            %tmp_visual_idx = tmp_visual_idx(randi(numel(tmp_visual_idx)));
			
            tmp_audio_idx = find(strcmp(audio_label, p.audio_labels));
			%tmp_audio_idx = tmp_audio_idx(randi(numel(tmp_audio_idx)));
            
			groundTruth{iStep, 1} = mergeLabels(object);
			decision = rand;
			% --- Simulate classification errors
			if decision > p.thr_wrong || ~isempty(find(tsteps == iStep)) % --- no error inserted
				visual_idx = tmp_visual_idx;
				audio_idx = tmp_audio_idx;
				groundTruth{iStep, 2} = mergeLabels(object);
			else % --- error inserted
				% --- Audio error or Visual error? (not both at the same time)
				decision = rand;
				if decision >= 0.5 % --- audio
					audio_idx = randi(p.nb_audio_labels);
					while (audio_idx == tmp_audio_idx)
						audio_idx = randi(p.nb_audio_labels);
					end
					visual_idx = tmp_visual_idx;
				else % --- visual
					visual_idx = randi(p.nb_visual_labels);
					while (visual_idx == tmp_visual_idx)
						visual_idx = randi(p.nb_visual_labels);
					end
					audio_idx = tmp_audio_idx;
				end
				groundTruth{iStep, 2} = mergeLabels(visual_idx, audio_idx);
				groundTruth_stats(iStep, 1) = 0;
            end
			simulatedData(:, iStep) = generateProbabilities(audio_idx, visual_idx);
		end

	end
	
	groundTruth_stats(:, 2) = cumsum(groundTruth_stats(:, 1)) ./ (1:p.nb_steps)';

	pause(0.25)
	disp('HTM: initialization of simulated scenario -- DONE');

end
