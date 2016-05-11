function plotGoodClassif (obj, varargin)

    p = inputParser ;
      p.addOptional('MinLim', 0) ;
      p.addOptional('MaxLim', 0) ;
      p.addOptional('Lim', [0, 0]) ;
      p.addOptional('Objects', [0, 0]) ;
      p.addOptional('MFI', true) ;
      p.addOptional('Max', true) ;
      p.addOptional('Rect', true) ;
      p.addOptional('Curv', true) ;
    p.parse(varargin{:}) ;
    p = p.Results ;

    if numel(p.Objects) == 1
        p.Objects = [p.Objects, p.Objects] ;
    end

    if sum(p.Objects) == 0
        objects = 1:obj.HTM_robot.nb_objects ;
    else
        objects = p.Objects(1):p.Objects(2) ;
    end

    cpt21 = obj.statistics.mfi ;
    cpt22 = obj.statistics.mfi_mean ;
    cpt11 = obj.statistics.max ;
    cpt12 = obj.statistics.max_mean ;

    correct = zeros(obj.HTM_robot.nb_objects, 1) ;
    correct2 = zeros(obj.HTM_robot.nb_objects, 1) ;
    for iObj = objects
        % === Object focused
        if obj.HTM_robot.getObj(iObj).theta == 0
            idx_audio = find(sum(obj.HTM_robot.getObj(iObj).data(1:obj.nb_audio_labels, :)) == 0, 1, 'last')+1 ;
            idx_vision = find(sum(obj.HTM_robot.getObj(iObj).data(obj.nb_audio_labels+1:end, :)) == 0, 1, 'last')+1 ;
            if ~isempty(idx_audio)
                tidx = obj.HTM_robot.getObj(iObj).tmIdx(idx_audio) ;
            elseif ~isempty(idx_vision)
                tidx = obj.HTM_robot.getObj(iObj).tmIdx(idx_vision) ;
            end
            if mean(cpt21(tidx-1:tidx-1)) > 0.5
                correct(iObj) = 1 ;
            else
                correct(iObj) = -1 ;
            end
            if mean(cpt11(tidx-1:tidx-1)) > 0.5
                correct2(iObj) = 1 ;
            else
                correct2(iObj) = -1 ;
            end
        end
    end

    % correct(p.Objects(1):p.Objects(end))

    C_0 = [0.2, 0.2, 0.2] ;
    C_1 = [0.4, 0.4, 0.4] ;
    C_2 = [0.75, 0.75, 0.75] ;
    C_3 = [1, 1, 1] ;

    figure ;
    hold on ;

    if p.Rect
        for iObj = 1:obj.HTM_robot.nb_objects
            x = obj.HTM_robot.getObj(iObj).tmIdx(1) ;
            X = [x, x, x+30, x+30] ;
            if p.Max
                Y1 = [0.5, 1, 1, 0.5] ;
            else
                Y1 = [0, 1, 1, 0] ;
            end
            Y2 = [0, 0.5, 0.5, 0] ;

            if correct(iObj) == -1
                C1 = C_0 ;
            elseif correct(iObj) == 1
                C1 = C_2 ;
            else
                C1 = C_3 ;
            end

            if correct2(iObj) == -1
                C2 = C_0 ;
            elseif correct2(iObj) == 1
                C2 = C_2 ;
            else
                C2 = C_3 ;
            end
            if p.MFI
                h1 = patch(X, Y1, C1) ;%, 'FaceAlpha', 0.6) ;
            end
            if p.Max
                h2 = patch(X, Y2, C2) ;%, 'FaceAlpha', 0.6) ;
            end
            if all(C1 == C_3)
                % hp = findobj(h,'type','patch');
                % hatch(h1, 45, [0.5, 0.5, 0.5], '-', 12, 2) ;
            end
        end
    end

    if p.Curv
        plot(cpt22(1:end), 'LineWidth', 4,...
                            'LineStyle', '-',...
                            'Color', [0.1, 0.1, 0.1]) ;
        plot(cpt12(1:end), 'LineWidth', 4,...
                            'LineStyle', '-',...
                            'Color', [0.6, 0.6, 0.6]) ;
    end


    lim = [0, 0] ;
    if sum(p.Objects) == 0
        if sum(p.Lim) == 0
            if p.MinLim == 0
                lim(1) = 1 ;
            else
                lim(1) = p.MinLim-10 ;
            end
            if p.MaxLim == 0
                lim(2) = numel(cpt12) ;
            else
                lim(2) = p.MaxLim+10 ;
            end
        else
            lim = p.Lim ;
        end
    else
        lim(1) = obj.HTM_robot.getObj(p.Objects(1)).tmIdx(1)-10 ;
        lim(2) = obj.HTM_robot.getObj(p.Objects(2)).tmIdx(end)+10 ;
    end
    
    set(gca, 'XLim', lim, 'Ylim', [0, 1]) ;

    title 'Mean of good classification over 1 simulation' ;
    xlabel 'time steps' ;
    ylabel 'mean of good classification' ;
end