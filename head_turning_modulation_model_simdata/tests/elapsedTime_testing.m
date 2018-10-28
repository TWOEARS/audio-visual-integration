

param = struct('epsilon', 0,...
			   'nb_sources',0,...
			   'nb_simultaneous_sources',0,...
			   'scene',[],...
			   'nb_iterations', 0);

epsilon = [0.1, 0.4, 0.8];
nb_sources = [3, 6, 10];
nb_simultaneous_sources = [2, 4, 7];
nb_iterations = [1, 10, 100, 1000];
scene = {[1, 9]...
	     [1, 9, 18, 21],...
	     [1, 3, 9, 28, 41, 46]};

temps_calcul = cell(1, 3);
mfi_mean = cell(1, 3);
shms = cell(1, 3);

for iScenario = 1:3
	temps_calcul{iScenario} = cell(3, 4);
	mfi_mean{iScenario} = cell(3, 4);
	shms{iScenario} = cell(3, 4);

	param.nb_sources = nb_sources(iScenario);
	param.nb_simultaneous_sources = nb_simultaneous_sources(iScenario);
	param.scene = scene{iScenario};

	for iCondition = 1:4
			param.nb_iterations = nb_iterations(iCondition);
		for iEpsilon = 1:3

			param.epsilon = epsilon(iEpsilon);
			setappdata(0, 'param_simu', param);

			temps_calcul{iScenario}{iEpsilon, iCondition} = 0;
			mfi_mean{iScenario}{iEpsilon, iCondition} = zeros(500, 1);
			shms{iScenario}{iEpsilon, iCondition} = zeros(1, 2);

			for iExpe = 1:5
				startHTM_simulation;
				temps_calcul{iScenario}{iEpsilon, iCondition} = temps_calcul{iScenario}{iEpsilon, iCondition}+htm.elapsed_time;
				mfi_mean{iScenario}{iEpsilon, iCondition} = mfi_mean{iScenario}{iEpsilon, iCondition} + htm.statistics.mfi_mean(:, end);
				shms{iScenario}{iEpsilon, iCondition}(1) = shms{iScenario}{iEpsilon, iCondition}(1) + numel(cell2mat(htm.naive_shm(:)));
				shms{iScenario}{iEpsilon, iCondition}(2) = shms{iScenario}{iEpsilon, iCondition}(2) + MOKS.shm;
			end
			temps_calcul{iScenario}{iEpsilon, iCondition} = temps_calcul{iScenario}{iEpsilon, iCondition}/5;
			mfi_mean{iScenario}{iEpsilon, iCondition} = mfi_mean{iScenario}{iEpsilon, iCondition} ./ 5;
			shms{iScenario}{iEpsilon, iCondition} = shms{iScenario}{iEpsilon, iCondition} ./5;
			
			disp(htm.information.epsilon);
			disp(htm.information.nb_sources);
			disp(htm.information.nb_simultaneous_sources);
			disp(htm.information.nb_iterations);
		end
	end
end




