function plotHeadMovements (obj)
    t = obj.robot.getAllObj('theta_hist') ;
    t = arrayfun(@(x) t{x}(1), 1:numel(t)) ;
    % tmp = find(arrayfun(@(x) isempty(t{x}), 1:obj.robot.nb_objects)) ;
    % if ~isempty(tmp)
    %     t{tmp} = obj.robot.getObj(tmp, 'theta') ;
    % end
    % t = cell2mat(arrayfun(@(x) t{x}(1), 1:numel(t), 'UniformOutput', false)) ;
    
    d = cell2mat(obj.robot.getAllObj('d')) ;
    t2 = unique(obj.theta_hist, 'stable') ;
    t2 = t2(2:end) ;

    d2 = [] ;
    cpt =  1 ;
    for iAngle = 1:numel(t)
        if cpt <= numel(t2) 
            if t(iAngle) == t2(cpt)
                d2 = [d2, d(iAngle)] ;
                cpt = cpt + 1 ;
            end
        end
    end
    figure ;
    polar(t, d, '*') ;
    hold on ;
    polar(t2, d2) ;
end
