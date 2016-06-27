
function plotHits (htm, vec)

    p = getInfo('AVPairs',...
        'nb_audio_labels',...
        'nb_labels');

    msom = htm.MSOM;
    

    if nargin == 1
        labels = mergeLabels(p.AVPairs);
        disp(labels);
        BOOL = false;
        str = input('Please select an audiovisual pair: ', 's');
        while ~BOOL
            varargin{1} = str;
            if ~strcmp(str, labels)
                str = input('Error: Wrong field. \nPlease select again a field to retrieve: ', 's');
            else
                BOOL = true;
            end
        end
        vec = str;
    end

    if isstr(vec)
        if strcmp(vec, 'all')
            vec = arrayfun(@(x) [htm.AVPairs{x}{1}, '_', htm.AVPairs{x}{2}], 1:numel(htm.AVPairs), 'UniformOutput', false) ;
            else
                nb_labels = size(vec, 1) ;
                labels = {vec} ;
            end
        end
        if iscell(vec)
            nb_labels = size(vec, 2) ;
            labels = vec ;
        end
        data = cell(nb_labels, 1) ;
        for iLabel = 1:nb_labels
            tmIdx = [] ;
            for iObj = 1:htm.RIR.nb_objects
                t = htm.RIR.getObj(iObj).tmIdx(1) ;
                if strcmp(htm.gtruth{t}, labels{iLabel})
                    idx = find(sum(htm.RIR.getObj(iObj).data(htm.nb_audio_labels+1:end, :)) > 0) ;
                    if ~isempty(idx)
                        s = size(htm.RIR.getObj(iObj).data, 2) ;
                        if s <= 30
                            tidx = s ;
                        else
                            tidx = 30 ;
                        end
                        tmIdx = [tmIdx, htm.RIR.getObj(iObj).tmIdx(1:tidx)] ;
                    end
                end
            end
            data{iLabel} = htm.data(:, tmIdx) ;
        end
    end

    subplot_dim2 = ceil(sqrt(nb_labels)) ;
    subplot_dim1 = numel(labels) - subplot_dim2 ;
    subplot_dim1 = max([subplot_dim1, 1]) ;

    for iLabel = 1:nb_labels
        vec = mean(data{iLabel}, 2) ;
        axis ;
        subplot(subplot_dim1, subplot_dim2, iLabel) ;

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
            dist1(:, iVec) = sqrt(sum(bsxfun(@minus, vec(1:msom.modalities(1), iVec)', msom.som_weights{1}).^2, 2)) ;
            dist2(:, iVec) = sqrt(sum(bsxfun(@minus, vec(msom.modalities(1)+1:end, iVec)', msom.som_weights{2}).^2, 2)) ;
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
            bmu = msom.findBestBMU(vec(:, iData)) ;
            x = I(bmu) ;
            y = J(bmu) ;
            rectangle('Position', [x, y, 1, 1],...
                      'EdgeColor', 'green',...
                      'LineWidth', 4,...
                      'LineStyle', '--') ;
        end
    end

end