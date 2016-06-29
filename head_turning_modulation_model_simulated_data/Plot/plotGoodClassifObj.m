function plotGoodClassifObj (htm, varargin)
        p = inputParser ;
          p.addOptional('MinLim', 0) ;
          p.addOptional('MaxLim', 0) ;
          p.addOptional('Lim', [0, 0]) ;
          p.addOptional('Objects', [0, 0]) ;
          p.addOptional('MFI', true) ;
          p.addOptional('Max', true) ;
        p.parse(varargin{:}) ;
        p = p.Results ;


    if numel(p.Objects) == 1
        p.Objects = [p.Objects, p.Objects] ;
    end
    if sum(p.Objects) == 0
        objects = 1:htm.robot.nb_objects ;
    else
        objects = p.Objects(1):p.Objects(2) ;
    end

    robot = htm.robot;

    cpt21 = htm.statistics.mfi ;
    cpt22 = htm.statistics.mfi_mean ;
    cpt11 = htm.statistics.max ;
    cpt12 = htm.statistics.max_mean ;


    correct = zeros(htm.robot.nb_objects, 1) ;
    correct2 = zeros(htm.robot.nb_objects, 1) ;

    info = getInfo('nb_audio_labels',...
                   'nb_visual_labels',...
                   'nb_steps');
    
    for iObj = objects

        % --- Object focused
        if getObject(robot, iObj, 'theta') == 0
        % if htm.robot.getObj(iObj).theta == 0
            data = retrieveObservedData(robot, iObj);

            audio_data = data(1:getInfo('nb_audio_labels'), :);
            visual_data = data(getInfo('nb_audio_labels')+1:end, :);

            idx_audio = find(sum(audio_data) == 0, 1, 'last')+1;
            idx_vision = find(sum(visual_data) == 0, 1, 'last')+1;

            tmIdx = getObject(robot, iObj, 'tmIdx');
            % tidx = getObject(robot, iObj, 'tmIdx'); 
            if ~isempty(idx_audio)
                % tidx = htm.robot.getObj(iObj).tmIdx(idx_audio) ;
                t = tmIdx(idx_audio);
            elseif ~isempty(idx_vision)
                % tidx = htm.robot.getObj(iObj).tmIdx(idx_vision) ;
                t = tmIdx(idx_vision);
            end
            if mean(cpt21(tmIdx(1):t-1)) >= 0.5
                correct(iObj) = 1 ;
            else
                correct(iObj) = -1 ;
            end
            if mean(cpt11(tmIdx(1):t-1)) >= 0.5
                correct2(iObj) = 1 ;
            else
                correct2(iObj) = -1 ;
            end
        end
    end

    figure ;
    hold on ;

    limits = zeros(1, info.nb_steps);
    tmIdx = zeros(1, info.nb_steps);
    for iObj = 1:htm.robot.nb_objects
        t = getObject(robot, iObj, 'tmIdx');
        
        x = t(1);
        
        object_data = htm.data(:, t);
        
        s = size(object_data, 2);

        X = [x, x, x+(s-1), x+(s-1)] ;
        Y = [0, 1, 1, 0] ;
        
        patch(X, Y, [1, 1, 1], 'LineWidth', 2) ;

        % ttt = min([htm.robot.getObj(iObj).tmIdx(end-9), htm.robot.getObj(iObj).tmIdx(1)+29]) ;
        % ttt = size(htm.robot.getObj(iObj).data, 2) ;
        tt = t(1:s) ;

        % tt = ttt;

        limits(tt) = 1 ;
        
        tmp = ones(1, s);
        
        tmp(find(sum(htm.data(info.nb_visual_labels:end, t)) == 0)) = 0 ;
        tmIdx(tt) = tmp;
    end

    C_0 = [0.2, 0.2, 0.2] ;
    C_1 = [0.35, 0.35, 0.35] ;
    C_2 = [0.75, 0.75, 0.75] ;
    C_3 = [1, 1, 1] ;

    for iStep = 1:info.nb_steps
        % --- Bad Inference
        if cpt21(iStep) == 0
            % --- Missing Data
            if tmIdx(iStep) == 0
                C1 = C_0 ;
            % --- Full Data
            else
                C1 = C_1 ;
            end
        % --- Good Inference
        else
            % --- Missing Data
            if tmIdx(iStep) == 0
                C1 = C_2 ;
            % --- Full Data
            else
                C1 = C_3 ;
            end
        end

        if cpt11(iStep) == 0
            % --- Missing Data
            if tmIdx(iStep) == 0
                C2 = C_0 ;
            % --- Full Data
            else
                C2 = C_1 ;
            end
        else
            % --- Missing Data
            if tmIdx(iStep) == 0
                C2 = C_2 ;
            % --- Full Data
            else
                C2 = C_3 ;
            end
        end
        Y2 = [0, 0.5, 0.5, 0] ;
        if limits(iStep) == 1
            X = [iStep-1, iStep-1, iStep, iStep] ;
            if p.Max
                Y1 = [0.5, 1, 1, 0.5] ;
            else
                Y1 = [0, 1, 1, 0] ;
            end
            patch(X, Y1, C1) ;
            if p.Max
                patch(X, Y2, C2) ;
            end
        end
    end

    lim = [0, 0] ;
    if sum(p.Objects) == 0
        if sum(p.Lim) == 0
            if p.MinLim == 0
                lim(1) = 1 ;
            else
                lim(1) = p.MinLim ;
            end
            if p.MaxLim == 0
                lim(2) = numel(cpt12) ;
            else
                lim(2) = p.MaxLim ;
            end
        else
            lim = p.Lim ;
        end
    else
        t1 = getObject(robot, p.Objects(1), 'tmIdx');
        t2 = getObject(robot, p.Objects(2), 'tmIdx');
        lim(1) = t1(1) - 2;
        lim(2) = t2(end);% + size(htm.data(:, getObject(robot, p.Objects(2), data), 2);
    end
    
    set(gca, 'XLim', lim, 'Ylim', [0, 1]) ;

    % title 'Mean of good classification over 1 simulation' ;
    xlabel 'time steps' ;
    % ylabel 'mean of good classification' ;

end