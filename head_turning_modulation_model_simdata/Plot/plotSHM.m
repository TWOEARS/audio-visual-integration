function plotSHM (htm)

    nb_sources = getInfo('nb_sources');
    angles_cpt = zeros(2, nb_sources);
    angles = getInfo('sources_position');
    angles_rad = deg2rad(angles);

    for iStep = 2:htm.nb_steps_final
        mo = htm.MOKS.motor_order(iStep);
        if mo > 0
            pos = find(angles == mo);
            angles_cpt(1, pos) = angles_cpt(1, pos) +  1;
        end
        
        tmp = htm.sources(iStep-1:iStep);
        if tmp(2)-tmp(1) > 1
            angles_cpt(2, tmp(2)) = angles_cpt(2, tmp(2)) + 1;
        end
    end
    [x, y] = pol2cart(angles_rad, angles_cpt(1, :));
    [x2, y2] = pol2cart(angles_rad, angles_cpt(2, :));

    h_fig = figure;
    set(h_fig, 'Color', [1, 1, 1]);

    h = compass([x2, x], [y2, y]);
    set(h(nb_sources+1:end), 'LineWidth', 4);
    set(h(1:nb_sources), 'Color', 'red', 'LineWidth', 2);
    
    set(get(h(1), 'Parent'), 'FontSize', 60);
 

    % if strcmp(k, 'init')
    %     [x, y] = pol2cart(obj.angles_rad, obj.angles_cpt(1, :));
    %     obj.shm_handle = compass([x, x], [y, y], 'Parent', obj.h3);
    %     % obj.naive_handle = compass(x, y, 'Parent', obj.h3);

    % elseif strcmp(k, 'update')
    %     % source = obj.htm.sources(iStep);
    %     % if source == 1
    %     mo = obj.htm.MOKS.motor_order(obj.htm.iStep);
    %     if mo > 0
    %         pos = find(obj.angles == mo);
    %         obj.angles_cpt(1, pos) = obj.angles_cpt(1, pos) + 1;
    %     end
    %     [x, y] = pol2cart(obj.angles_rad, obj.angles_cpt(1, :));
        
    %     iStep = obj.htm.iStep;
    %     if iStep > 1
    %         tmp = obj.htm.sources(iStep-1:iStep);
    %         if tmp(2)-tmp(1) > 1
    %             obj.angles_cpt(2, tmp(2)) = obj.angles_cpt(2, tmp(2)) + 1;
    %         end
    %         % hold on;
    %         [x2, y2] = pol2cart(obj.angles_rad, obj.angles_cpt(2, :));
    %         % obj.naive_handle = compass(x, y, 'red');
    %         % set(obj.naive_handle(:), 'LineWidth', 1);
            
    %         nb_sources = getInfo('nb_sources');
    %         obj.shm_handle = compass([x2, x], [y2, y], 'Parent', obj.h3);
    %         set(obj.shm_handle(nb_sources+1:end), 'LineWidth', 4);
    %         set(obj.shm_handle(1:nb_sources), 'Color', 'red', 'LineWidth', 2);
    %         % hold off;
    %     end
    %     %legend({'HTMKS', 'Naive robot'});%, 'Color', {'blue', 'red'});

    % end

    % AVPairs = mergeLabels('all');
    
    % info = getInfo('all');
    
    % % angles = getInfo('sources_position');

    % %angles = 1 :360/(3+1): 360;
    % %angles = 1 :360/(info.nb_sources+1): 360;
    % %angles = round(angles(1:end));
    % angles = info.sources_position;
    
    % cpt = zeros(info.nb_sources, 1);
    % positions = [];
    % positions_naive = [];

    % for iObj = 1:htm.RIR.nb_objects
    %     idx = find(strcmp(getObject(htm, iObj, 'label'), AVPairs));
    %     theta = getObject(htm, iObj, 'theta');
    %     theta = theta(end);
    %     if ~isempty(idx) && theta == 0
    %     % --- Object focused
    %     % if htm.RIR.getObj(iObj).theta == 0
    %         % ff = [ff, htm.RIR.getObj(iObj).theta_hist(1)] ;
    %         % cpt(idx) = cpt(idx)+1 ;
    %         positions(end+1) = angles(idx+1);
    %     % --- Object NOT focused
    %     else
    %         % ff = [ff, 0] ;
    %         % positions = [positions ; 0] ;
    %     end
    %     positions_naive = [positions_naive, angles(idx+1)];
    % end

    % % angles = 0 :360/(9*(3+1)): 359;
    % angles = 0 :360/(9*(getInfo('nb_AVPairs')+1)): 359;
    % angles = deg2rad(angles);
    % positions = deg2rad(positions);
    % positions_naive = deg2rad(positions_naive);

    % figure;

    % h1 = rose(positions_naive, angles);
    % hold on;
    % h2 = rose(positions, angles);


    % pos = get(gca, 'XLim');
    % set(gca, 'FontSize', 55)

    % angles = angles(1 :9: end);

    % h3 = polar(angles(2:end), ones(1, getInfo('nb_AVPairs'))*pos(2));

    % % set(h1, 'Color', 'red',...
    % set(h1, 'Color', [0.2, 0.2, 0.2],...
    %         'LineWidth', 7,...
    %         'LineStyle', '-');
    % % set(h2, 'Color', [0.6, 0.6, 0.6],...
    % set(h2, 'Color', 'red',...
    %         'LineWidth', 5,...
    %         'LineStyle', '-');

    % set(h3, 'LineStyle', 'none',...
    %         'Marker', '.',...
    %         'MarkerSize', 50,...
    %         'Color', [0, 0, 0]);

    % th = findall(gcf,'Type','text');
    % for i = 1:length(th),
    %     set(th(i),'FontSize',20)
    % end

end