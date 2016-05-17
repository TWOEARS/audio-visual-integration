function simulationStatus (obj)
    AVData = obj.getAVData() ;
    t = obj.current_time ;
    if ~isempty(AVData)
        m1 = find(AVData.t_idx(:, 1) <= t, 1, 'last') ;
        m2 = find(AVData.t_idx(:, 2) >= t, 1, 'first') ;
        if m1 == m2
            a = find(arrayfun(@(x) strcmp(obj.AVPairs{x}(2), AVData.labels{m1}), 1:numel(obj.AVPairs))) ;
            v = a ;
            obj.gtruth{end+1} = [obj.visual_labels{v}, '_', obj.audio_labels{a}] ;
            % end
            % if strcmp(AVData.labels{m1}, 'acceptable')
            %     % a = find(strcmp(obj.AVPairs) ;
            %     v = 1 ;
            % else
            %     a = 1 ;
            %     v = 0 ;
            % end
        else
            a = 0 ;
            v = 0 ;
            obj.gtruth{end+1} = 'none_none' ;
        end
    else
        a = 0 ;
        v = 0 ;
        obj.gtruth{end+1} = 'none_none' ;
    end
    
    obj.simulation_status(1, obj.cpt) = a ;
    obj.simulation_status(2, obj.cpt) = v ;
    % obj.simulation_status(3, obj.cpt) = v ;

end