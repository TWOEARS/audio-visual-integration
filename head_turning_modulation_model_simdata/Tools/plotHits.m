function plotHits (htm, vec)

    p = getInfo('AVPairs',...
                'nb_audio_labels',...
                'nb_labels',...
                'scenario');

    idx = p.scenario.scene{:};
    AVPairs = p.AVPairs(idx);

    msom = htm.MSOM;
    
    if nargin == 1
        labels = mergeLabels(AVPairs);
		disp(labels);
		BOOL = false;
		str = input('Please select an audiovisual pair: ');
		while ~BOOL
			varargin{1} = str;
            if isnumeric(str)
                str = labels{str};
            end
			if ~strcmp(str, labels)
				str = input('Error: Wrong Field. \nPlease select again a field to retrieve: ');
			else
				BOOL = true;
			end
        end
        vec = str;
    end
    
    if isstr(vec)
        if strcmp(vec, 'all')
            % vec = arrayfun(@(x) [htm.AVPairs{x}{1}, '_', htm.AVPairs{x}{2}], 1:numel(htm.AVPairs), 'UniformOutput', false) ;
            sc = getInfo('scenario');
            %idx = sc.unique_idx;
            labels = mergeLabels(sc.unique_idx, 'pairs');
            nb_labels = numel(labels);
        else
            labels = mergeLabels(p.AVPairs);
            tmp = find(strcmp(vec, labels));
            if isempty(tmp)
                disp(labels);
                BOOL = false;
                disp('Error: Wrong label');
                str = input('Please select a correct audiovisual pair: ');
                while ~BOOL
                    varargin{1} = str;
                    if isnumeric(str)
                        str = labels{str};
                    end
                    if ~strcmp(str, labels)
                        str = input('Error: Wrong Field. \nPlease select again a field to retrieve: ');
                    else
                        BOOL = true;
                    end
                end
                vec = str;
            end
            nb_labels = 1;
            labels = {vec};
        end
    elseif iscell(vec)
        nb_labels = size(vec, 1);
        labels = vec;
    end
    
    data = cell(nb_labels, 1);
    for iLabel = 1:nb_labels
        tmIdx = [];
        tmp = find(strcmp(htm.gtruth(:, 1), labels{iLabel}));
        %tmp = find(strcmp(getObject(htm, 'all', 'label'), labels{iLabel}));
        data{iLabel} = htm.gtruth_data(:, tmp);
%         if ~isempty(tmp)
%             data{iLabel} = getData(htm, tmp, true);
%         end
    end
%         for iObj = 1:htm.robot.nb_objects
%             obj_tmIdx = getObject(htm, iObj, 'tmIdx');
%             t = obj_tmIdx(1);
%             if strcmp(htm.gtruth{t, 1}, labels{iLabel})
%                 obj_data = getData(htm, iObj, true);
%                 idx = find(sum(obj_data(p.nb_audio_labels+1:end, :)) > 0);
%                 if ~isempty(idx)
%                     s = size(obj_data, 2);
%                     if s <= getInfo('cpt_object')
%                         tidx = s;
%                     else
%                         tidx = getInfo('cpt_object');
%                     end
%                     tmIdx = [tmIdx, obj_tmIdx(1:tidx)];
%                 end
%             end
%         end
%             data{iLabel} = htm.data(:, tmIdx) ;
%         data{iLabel} = htm.data(:, tmIdx);
%     end
    %end

    figure;
    
    subplot_dim2 = ceil(sqrt(nb_labels));
    subplot_dim1 = ceil(nb_labels/subplot_dim2); 
%     subplot_dim1 = max([subplot_dim1, 1]) ;
%     
%     x = 1:nb_labels;
%     div = x(~(rem(nb_labels, x)));
%     subplot_dim1 = div(end-2);
%     subplot_dim2 = div(end-1);

    for iLabel = 1:nb_labels
        if ~isempty(data{iLabel})
            vec = mean(data{iLabel}, 2);
            axis;
            subplot(subplot_dim1, subplot_dim2, iLabel);

            set(gca, 'XLim' , [1, msom.som_dimension(1)+1],...
                     'YLim' , [1, msom.som_dimension(1)+1],...
                     'XTick', [1:msom.som_dimension(1)],...
                     'YTick', [1:msom.som_dimension(1)]) ;
            grid on ;
            hold on ;

            s = size(vec, 2) ;
            % d1 = data(:, 4) ;
            dist1 = zeros(msom.nb_nodes, s) ;
            dist2 = zeros(msom.nb_nodes, s) ;
            dist3 = zeros(msom.nb_nodes, s) ;

            for iVec = 1:s
                dist1(:, iVec) = sqrt(sum(bsxfun(@minus, vec(1:msom.modalities(1), iVec)', msom.weights_vectors{1}).^2, 2)) ;
                dist2(:, iVec) = sqrt(sum(bsxfun(@minus, vec(msom.modalities(1)+1:end, iVec)', msom.weights_vectors{2}).^2, 2)) ;
                dist3(:, iVec) = dist1(:, iVec).*dist2(:, iVec) ;
            end

            dist1 = mean(dist1, 2) ;
            dist2 = mean(dist2, 2) ;
            dist3 = mean(dist3, 2) ;

            dist1 = 1./dist1 ;
            dist1 = (dist1 - min(dist1))/max(dist1) ;

            dist2 = 1./dist2 ;
            dist2 = (dist2 - min(dist2))/max(dist2) ;

            dist3 = 1./dist3 ;
            dist3 = (dist3 - min(dist3))/max(dist3) ;


            [I, J] = ind2sub(msom.som_dimension(1), 1:msom.nb_nodes) ;

            for iNode = 1:msom.nb_nodes
                x = I(iNode) ;
                y = J(iNode) ;

                x1 = x + ((1-dist1(iNode))/2) ;
                y1 = y + ((1-dist1(iNode))/2) ;

                x1 = [x1, x1+dist1(iNode), x1+dist1(iNode), x1] ;
                y1 = [y1, y1, y1+dist1(iNode), y1+dist1(iNode)] ;

                x2 = x + ((1-dist2(iNode))/2) ;
                y2 = y + ((1-dist2(iNode))/2) ;

                x2 = [x2, x2+dist2(iNode), x2+dist2(iNode), x2] ;
                y2 = [y2, y2, y2+dist2(iNode), y2+dist2(iNode)] ;

                x3 = [x, x+1, x+1, x] ;
                y3 = [y, y, y+1, y+1] ;
                patch(x3, y3, 'blue', 'FaceAlpha', dist3(iNode)) ;

                if dist1(iNode) >= dist2(iNode)
                    patch(x1, y1, 'red') ;
                    patch(x2, y2, 'black') ;
                else
                    patch(x2, y2, 'black') ;
                    patch(x1, y1, 'red') ;
                end
            end
            for iData = 1:size(vec, 2)
                bmu = msom.getCombinedBMU(vec(:, iData)) ;
                x = I(bmu) ;
                y = J(bmu) ;
                rectangle('Position', [x, y, 1, 1],...
                          'EdgeColor', 'green',...
                          'LineWidth', 4,...
                          'LineStyle', '--') ;
            end
        else
            % subplot(subplot_dim1, subplot_dim2, iLabel);
        end
    end
    if nb_labels == 1
        [v, a] = unmergeLabels(labels{1});
        title(strjoin([v, a]));
    end

end