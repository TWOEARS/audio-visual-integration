function plotSHM (htm)

    AVPairs = mergeLabels('all');

    % angles = 1 :360/(3+1): 360;
    angles = 1 :360/(getInfo('nb_AVPairs')+1): 360;
    angles = round(angles(1:end));
    cpt = zeros(numel(AVPairs), 1);
    positions = [];
    positions_naive = [];

    for iObj = 1:htm.RIR.nb_objects
        idx = find(strcmp(getObject(htm, iObj, 'label'), AVPairs));
        if ~isempty(idx) && getObject(htm, iObj, 'theta') == 0
        % --- Object focused
        % if htm.RIR.getObj(iObj).theta == 0
            % ff = [ff, htm.RIR.getObj(iObj).theta_hist(1)] ;
            % cpt(idx) = cpt(idx)+1 ;
            positions(end+1) = angles(idx+1);
        % --- Object NOT focused
        else
            % ff = [ff, 0] ;
            % positions = [positions ; 0] ;
        end
        positions_naive = [positions_naive, angles(idx+1)];
    end

    % angles = 0 :360/(9*(3+1)): 359;
    angles = 0 :360/(9*(getInfo('nb_AVPairs')+1)): 359;
    angles = deg2rad(angles);
    positions = deg2rad(positions);
    positions_naive = deg2rad(positions_naive);

    figure;

    h1 = rose(positions_naive, angles); 
    hold on;
    h2 = rose(positions, angles);


    pos = get(gca, 'XLim');
    set(gca, 'FontSize', 55)

    angles = angles(1 :9: end);

    h3 = polar(angles(2:end), ones(1, getInfo('nb_AVPairs'))*pos(2));

    % set(h1, 'Color', 'red',...
    set(h1, 'Color', [0.2, 0.2, 0.2],...
            'LineWidth', 7,...
            'LineStyle', '-');
    % set(h2, 'Color', [0.6, 0.6, 0.6],...
    set(h2, 'Color', 'red',...
            'LineWidth', 5,...
            'LineStyle', '-');

    set(h3, 'LineStyle', 'none',...
            'Marker', '.',...
            'MarkerSize', 50,...
            'Color', [0, 0, 0]);

    th = findall(gcf,'Type','text');
    for i = 1:length(th),
        set(th(i),'FontSize',20)
    end

end