function plotSHM (obj)

    AVPairs = obj.AVPairs ;

    for iPair = 1:numel(AVPairs)
        AVPairs{iPair} = [AVPairs{iPair}{1}, '_', AVPairs{iPair}{2}] ;
    end

    angles = 1 :360/(3+1): 360 ;
    angles = round(angles(1:end)) ;
    cpt = zeros(numel(AVPairs), 1) ;
    positions = [] ;
    positions_naive = [] ;

    for iObj = 1:obj.HTM_robot.nb_objects
        idx = find(strcmp(obj.HTM_robot.getObj(iObj).label, AVPairs)) ;
        % === Object focused
        if obj.HTM_robot.getObj(iObj).theta == 0
            % ff = [ff, obj.HTM_robot.getObj(iObj).theta_hist(1)] ;
            % cpt(idx) = cpt(idx)+1 ;
            positions = [positions ; angles(idx+1)] ;
        % === Object NOT focused
        else
            % ff = [ff, 0] ;
            % positions = [positions ; 0] ;
        end
        positions_naive = [positions_naive, angles(idx+1)] ;
    end

    angles = 0 :360/(9*(3+1)): 359 ;
    angles = deg2rad(angles) ;
    positions = deg2rad(positions) ;
    positions_naive = deg2rad(positions_naive) ;

    figure ; 

    h1 = rose(positions_naive, angles) ; 
    hold on ;
    h2 = rose(positions, angles) ;


    pos = get(gca, 'XLim') ;

    angles = angles(1 :9: end) ;

    h3 = polar(angles(2:end), ones(1, 3)*pos(2)) ;

    % set(h1, 'Color', 'red',...
    set(h1, 'Color', [0.2, 0.2, 0.2],...
            'LineWidth', 5,...
            'LineStyle', '-') ;
    % set(h2, 'Color', [0.6, 0.6, 0.6],...
    set(h2, 'Color', 'red',...
            'LineWidth', 3,...
            'LineStyle', '-') ;

    set(h3, 'LineStyle', 'none',...
            'Marker', '.',...
            'MarkerSize', 50,...
            'Color', [0, 0, 0] ) ;
end