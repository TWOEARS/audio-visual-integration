
function plotFocus (htm)

	AVPairs = getInfo('AVPairs') ;

	% correctAVPairs = {'person_speech', 'door_knock', 'siren_alert'} ;
    
    correctAVPairs = AVPairs;
	
    figure ;

	subplot(1, 10, 1:8)
	hold on ;

	nb_tsteps = getInfo('nb_steps');

	xvec = linspace(0, 60.004, nb_tsteps) ;
	naive = zeros(1, numel(htm.FCKS.focus)) ;

	colors = {'black', 'red', 'green'} ;
	audio_labels = getInfo('audio_labels');

	tstop = 0 ;
	for iObj = 1:size(AVdata.t_idx, 1)
		tstart = AVdata.t_idx(iObj, 1) ;
		duration = AVdata.t_idx(iObj, 2) - tstart ;

		audio_color = find(strcmp(AVdata.t_idx(iObj, 3), audio_labels)) ;
		% audio_color = colors{audio_color} ;
		audio_color = colors{AVdata.t_idx(iObj, 3)} ;

		if find(iObj == AVdata.wrong)
			visual_color = 'red' ;
			wrong = true ;
		else
			visual_color = 'green' ;
			wrong = false ;
		end
		if wrong
			if find(strcmp(htm.getObj(iObj, 'label'), correctAVPairs))
    			correct = true ;
    		else
    			correct = false ;
    		end
    	end
        
        rectangle('Position', [tstart iObj-0.25 duration 0.5],...
                  'FaceColor', [1 1 1],...
                  'LineWidth', 6) ;
        rectangle('Position', [tstart iObj duration 0.25],...
                  'FaceColor', audio_color,...
                  'EdgeColor', audio_color) ;
        rectangle('Position', [tstart iObj-0.25 duration 0.25],...
                  'FaceColor', visual_color,...
                  'EdgeColor', visual_color) ;

        search_stop = find(tstop <= xvec, 1, 'first') ;
        search_start = find(tstart >= xvec, 1, 'last') ;
        search_duration = find(tstart+duration <= xvec, 1, 'first') ;

        nvalues = numel([search_stop:search_start]) ;
        nduration = numel([search_start:search_duration]) ;
        naive(search_stop:search_start) = ones(1, nvalues)*(iObj-1) ;

        naive(search_start:search_duration) = ones(1, nduration)*iObj ;
		
		if wrong && correct
			text(tstart, iObj+0.25, '*', 'FontSize', 52, 'Color', 'cyan') ;
		elseif wrong && ~correct
			text(tstart, iObj+0.25, '*', 'FontSize', 52, 'Color', 'blue') ;
		end
        tstop = tstart+duration ;
    end
    
    % search_stop = find(tstop <= xvec, 1, 'first') ;
    nduration = numel([search_duration:nb_tsteps]) ;
    naive(search_duration:end) = ones(1, nduration)*iObj ;

    rectangle('Position', [2 20-1 7 2],...
              'FaceColor', [1 1 1],...
              'LineWidth', 4) ;
    rectangle('Position', [2 20-1 7 1],...
              'FaceColor', [0 0 0]+0.45,...
              'EdgeColor', [0 0 0]+0.45) ;
    rectangle('Position', [2 20 7 1],...
              'FaceColor', [0 0 0]+0.90,...
              'EdgeColor', [0 0 0]+0.90) ;

    text(3, 20.50, 'Audio label', 'FontSize', 16) ;
    text(3, 19.40, 'Visual label', 'FontSize', 16) ;

    plot(xvec, htm.focus_hist, 'LineWidth', 4) ;
    plot(xvec, [zeros(1, 21), htm.focus_origin], 'r', 'LineWidth', 3) ;

    plot(xvec, naive, 'k--', 'LineWidth', 2) ;

    legend({'Objects focused',...
    		'DWmod (0) or MFImod (-1) based computation',...
    		'Purely reflexive robot'},...
    		'FontSize', 16,...
    		'Location', 'northwest') ;

    set(gca, 'XLim', [0, 61],...
    		 'XTickLabel', [0 :10: 61],...
    		 'YLim', [-2, htm.nb_objects+2]) ;
    xlabel('Time of simulation (sec)', 'FontSize', 16) ;
    ylabel('Object number', 'FontSize', 16) ;
    title('Focused objects based on DWmod and MFImod computations', 'FontSize', 20) ;

    hold off ;

    % --- Hist

    proba = cell2mat(htm.getEnv().getCategories('proba')) ;
    proba = proba(2:end) ;
    perf = cell2mat(htm.getEnv().getCategories('perf')) ;
    perf = perf(2:end) ;
    cat_labels = htm.getEnv().getCategories('label') ;
    cat_labels = cat_labels(2:end) ;

    cat_labels = arrayfun(@(x) [cat_labels{x}(1:find(cat_labels{x} == '_')-1), ' ', cat_labels{x}(find(cat_labels{x} == '_')+1:end)],...
    					  1:numel(cat_labels),...
    					  'UniformOutput', false) ;

    subplot(1, 10, 9:10)
    hold on ;
    bar(proba,'FaceColor', 'none',...
    		  'EdgeColor', 'red',...
    	      'LineStyle', '-',...
    	      'LineWidth', 3) ;
    bar(perf,'FaceColor', 'none',...
    		 'EdgeColor', 'blue',...
    		 'LineStyle', ':',...
    		 'LineWidth', 2) ;
    set(gca, 'XTick', [1:numel(cat_labels)],...
    		 'XTickLabel', cat_labels,...
    		 'XTickLabelRotation', 45,...
    		 'YLim', [0, 1],...
    		 'FontSize', 12) ;

    legend({'proba', 'perf'}, 'FontSize', 16) ;

end
