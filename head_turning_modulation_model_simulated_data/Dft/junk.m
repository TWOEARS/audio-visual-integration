
function retrieveGroundtruth (obj, iStep)
    % obj.gtruth = cell(obj.robot.nb_objects, 1) ;
    al = 0 ;
    vl = 0 ;

    vl = obj.simulation_status(1, iStep) ;
    al = obj.simulation_status(2, iStep) ;

    % if obj.simulation_status(3, iStep) == 1
    %     vl = obj.simulation_status(1, iStep) ;
    %     al = obj.simulation_status(2, iStep) ;
    % % === Audio is wrong
    % elseif obj.simulation_status(3, iStep) == 3
    %     vl = obj.simulation_status(1, iStep) ;
    %     al = find(arrayfun(@(x) strcmp(obj.AVPairs{x}(1), vl), 1:numel(obj.AVPairs))) ;
    % elseif obj.simulation_status(3, iStep) == 4
    %     al = obj.simulation_status(2, iStep) ;
    %     vl = find(arrayfun(@(x) strcmp(obj.AVPairs{x}(2), al), 1:numel(obj.AVPairs))) ;
    % end
    if al == 0
        obj.gtruth{end+1} = 'none_none' ;
    else
        obj.gtruth{end+1} = [obj.visual_labels{vl}, '_', obj.audio_labels{al}] ;
    end


    if iStep == obj.nb_steps

        [~, ma] = max(obj.data(1:obj.nb_audio_labels, :)) ;
        [~, mv] = max(obj.data(obj.nb_audio_labels+1:end, :)) ;

        classif_max = cell(obj.nb_steps, 1) ;
        for ii = 1:obj.nb_steps
            if sum(obj.data(1:obj.nb_audio_labels, ii)) < 0.2 &&...
                   sum(obj.data(obj.nb_audio_labels+1:end, ii)) < 0.2
                classif_max{ii} = 'none_none' ;
            elseif sum(obj.data(1:obj.nb_audio_labels, ii)) < 0.2
                classif_max{ii} = [obj.visual_labels{mv(ii)}, '_', 'none'] ;
            elseif sum(obj.data(obj.nb_audio_labels+1:end, ii)) < 0.2
                classif_max{ii} = ['none', '_', obj.audio_labels{ma(ii)}] ;
            else
                classif_max{ii} = [obj.visual_labels{mv(ii)}, '_', obj.audio_labels{ma(ii)}] ;
            end
        end

        obj.classif_max = classif_max ;

        silence = 10 ;
        n = obj.nb_steps-(silence-1) ;
        cpt1 = 0 ;
        cpt11 = zeros(1, n) ;
        cpt12 = zeros(1, n) ;
        cpt2 = 0 ;
        cpt21 = zeros(1, n) ;
        cpt22 = zeros(1, n) ;
        cpt3 = 0 ;

        for ii = silence:obj.nb_steps
            if strcmp(classif_max(ii), obj.gtruth(ii))
                cpt1 = cpt1 + 1 ;
                cpt11(ii-(silence-1)) = 1 ;
            end

            if strcmp(obj.classif_mfi(ii), obj.gtruth(ii))
                cpt2 = cpt2 + 1 ;
                cpt21(ii-(silence-1)) = 1 ;
            end
            cpt12(ii-(silence-1)) = mean(cpt11(1:ii-(silence-1))) ;
            cpt22(ii-(silence-1)) = mean(cpt21(1:ii-(silence-1))) ;
        end

        obj.cpt11 = cpt11 ;
        obj.cpt12 = cpt12 ;
        obj.cpt21 = cpt21 ;
        obj.cpt22 = cpt22 ;
    end

    % for iObj = 1:obj.robot.nb_objects
    %     % d = obj.robot.getObj(iObj).getBestData() ;
    %     tmIdx = obj.robot.getObj(iObj).tmIdx ;
    %     idx = tmIdx(1):min([tmIdx(end), tmIdx(1)+29]) ;
    %     % idx = idx - (iObj*10) + 1 ;
    %     d = mean(obj.data(:, idx), 2) ;
    %     [~, max_a] = max(d(1:obj.nb_audio_labels)) ;
    %     [~, max_v] = max(d(obj.nb_audio_labels+1:end)) ;
    %     obj.gtruth{iObj} = [obj.visual_labels{max_v}, '_', obj.audio_labels{max_a}] ;
    % end
end

% function compareLabels (obj)
%     labels = obj.robot.getAllObj('label') ;
%     obj.compared_labels = [obj.gtruth, labels'] ;
%     cpt = 0 ;
%     for iLabel = 1:numel(labels)
%         if strcmp(obj.compared_labels{iLabel, 1}, obj.compared_labels{iLabel, 2})
%             cpt = cpt + 1 ;
%         end
%     end
%     obj.goodClassifCpt = 100*cpt/numel(labels) ;
%     obj.goodClassifHist = [obj.goodClassifHist, obj.goodClassifCpt] ;
% end



    %setappdata(0, 'elaps', elaps) ;

    %% Edit Ion
    % if (p.save)
   
    %     simuData = struct('gtruth',{obj.gtruth}, ...
    %                       'AVPairs', {obj.AVPairs}, ...
    %                       'audioLabels', {obj.audio_labels}, ...
    %                       'visualLabels', {obj.visual_labels}, ...
    %                       'data', {obj.data}, ... 
    %                       'thetaObj', {obj.theta_obj}, ...
    %                       'distHist', {obj.dist_hist} ) ;
        
    %     if (~exist(['Data/', num2str(obj.nb_AVPairs), '_', num2str(obj.nb_steps)]) )
    %         mkdir('Data', [num2str(obj.nb_AVPairs), '_', num2str(obj.nb_steps)]);
    %     end

    %     save(['Data/', num2str(obj.nb_AVPairs), '_', num2str(obj.nb_steps), '/', datestr(datetime('now'))], 'simuData');
    % end

    % textprogressbar('') ;





        % for iNode = 1:obj.nb_nodes
        %   % --- aleph = learning rate
            % aleph = exp(-sum((obj.som_grid(bmu, :) - obj.som_grid(iNode, :)).^2) / (2*sig^2)) ;

        %     % dw = mu * aleph * (vector' - obj.som_weights{modality}(iNode, :)) ;
        %     % dw = mu * aleph(iNode) * (vector' - obj.som_weights{modality}(iNode, :)) ;
        %     % dw = tmp(iNode) * (vector' - obj.som_weights{iI}(iNode, :)) ;
        %     dw = tmp(iNode) * (vec' - obj.som_weights{iI}(iNode, :)) ;

        %     % --- Update iNode(th) node's weights
        %     obj.som_weights{iI}(iNode, :) = obj.som_weights{iI}(iNode, :) + dw ; 
        % end



    % obj.mu = zeros(1, obj.nb_iterations) ;
    % obj.sig = zeros(1, obj.nb_iterations) ;
    % % === Initializing parameters of learning
    % for iStep = 1:obj.nb_iterations
    %   tfrac = iStep / obj.nb_iterations ; 
    %   obj.mu(iStep) = obj.lrates.initial + tfrac * (obj.lrates.final - obj.lrates.initial) ;
    %   obj.sig(iStep) = obj.sigmas.initial + tfrac * (obj.sigmas.final - obj.sigmas.initial) ;
    % end
    
    % obj.aleph = cell(obj.nb_nodes, obj.nb_iterations) ;

    % for iNode = 1:obj.nb_nodes
    %   for iStep = 1:obj.nb_iterations
    %       obj.aleph{iNode, iStep} = exp(-sum((bsxfun(@minus, obj.som_grid(iNode, :), obj.som_grid).^2), 2) / (2*obj.sig(iStep).^2)) ;
    %   end
    % end



    % [bmu_a, tmp1] = min(sqrt(sum(bsxfun(@minus, vector(1:obj.modalities(1))', obj.som_weights{1}).^2, 2))) ;
    % [bmu_v, tmp2] = min(sqrt(sum(bsxfun(@minus, vector(obj.modalities(1)+1:end)', obj.som_weights{2}).^2, 2))) ;

    % if bmu_a < bmu_v
    %   best_matching_unit = tmp1 ;
    % else
    %   best_matching_unit = tmp2 ;
    % end



        % global ISTEP ;

    % tfrac = ISTEP / obj.nb_iterations ;
    % % --- mu = parameter for the learning function
    % mu = obj.lrates.initial + tfrac * (obj.lrates.final - obj.lrates.initial) ;
    % % --- sig = parameter for the neighborhood function
    % sig = obj.sigmas.initial + tfrac * (obj.sigmas.final - obj.sigmas.initial) ;

    % aleph = exp(-sum((bsxfun(@minus, obj.som_grid(bmu, :), obj.som_grid).^2), 2) / (2*sig^2)) ;
