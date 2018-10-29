function plotHeadMovements (htm)

    %t = htm.RIR.getAllObj('theta_hist');
    t = getObject(htm, 'all', 'theta');
    %t = arrayfun(@(x) t{x}(1), 1:numel(t));
    % tmp = find(arrayfun(@(x) isempty(t{x}), 1:htm.robot.nb_objects)) ;
    % if ~isempty(tmp)
    %     t{tmp} = htm.robot.getObj(tmp, 'theta') ;
    % end
    % t = cell2mat(arrayfun(@(x) t{x}(1), 1:numel(t), 'UniformOutput', false)) ;
    
    %d = cell2mat(htm.RIR.getAllObj('d')) ;
    d = getObject(htm, 'all', 'dist_hist');
    d = ones(numel(t), 1);

    t2 = unique(htm.MOKS.head_position, 'stable') ;
    
    t2 = t2(2:end) ;

    d2 = [] ;
    cpt =  1 ;
    for iAngle = 1:numel(t)
        if cpt <= numel(t2) 
            if t(iAngle) == t2(cpt)
                d2 = [d2, d(iAngle)];
                cpt = cpt + 1;
            end
        end
    end
    
    figure ;
    polar(t, d, '*') ;
    hold on ;
    polar(t2, d2) ;
end
