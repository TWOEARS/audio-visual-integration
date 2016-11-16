function plotGoodClassif (htm, varargin)

    p = inputParser;
      p.addOptional('MinLim', 0);
      p.addOptional('MaxLim', 0);
      p.addOptional('Lim', [0, 0]);
      p.addOptional('Objects', [0, 0]);
      p.addOptional('MFI', true);
      p.addOptional('Max', true);
      p.addOptional('Rect', true);
      p.addOptional('Curv', true);
    p.parse(varargin{:});
    p = p.Results;

    if numel(p.Objects) == 1
        p.Objects = [p.Objects, p.Objects];
    end

    if sum(p.Objects) == 0
        objects = 1:htm.RIR.nb_objects;
    else
        objects = p.Objects(1):p.Objects(2);
    end

    RIR = htm.RIR;

    statistics = htm.statistics;
    
    cpt21 = statistics.mfi;
    cpt22 = statistics.mfi_mean;
    cpt11 = statistics.max;
    cpt12 = statistics.max_mean;

    correct = zeros(RIR.nb_objects, 1);
    correct2 = zeros(RIR.nb_objects, 1);
    for iObj = objects
        % --- If object focused -> system had access to whole data
        % if getObject(RIR, iObj, 'theta') == 0
            data = retrieveObservedData(RIR, iObj);

            audio_data = data(1:getInfo('nb_audio_labels'), :);
            visual_data = data(getInfo('nb_audio_labels')+1:end, :);

            idx_audio = find(sum(audio_data) == 0, 1, 'last');
            idx_vision = find(sum(visual_data) == 0, 1, 'last');

            tmIdx = getObject(RIR, iObj, 'tmIdx');
            if ~isempty(idx_audio)
                t = tmIdx(idx_audio);
            else
                t = tmIdx(1);
            end

            if ~isempty(idx_vision)
                % tidx = RIR.getObj(iObj).tmIdx(idx_vision) ;
                t = tmIdx(idx_vision);
            else
                t = tmIdx(1);
            end

            % --- Statistics MAX
            if mean(cpt21(tmIdx(1):t)) > 0.5
                correct(iObj) = 1;
            else
                correct(iObj) = -1;
            end
            % --- Statistics MEAN(MAX)
            if mean(cpt11(tmIdx(1):t)) >= 0.5
                correct2(iObj) = 1;
            else
                correct2(iObj) = -1;
            end
        % end
    end

    % correct(p.Objects(1):p.Objects(end))

    C_0 = [0.2, 0.2, 0.2];
    C_1 = [0.4, 0.4, 0.4];
    C_2 = [0.75, 0.75, 0.75];
    C_3 = [1, 1, 1];

    figure;
    hold on;

    colors_vec = [0  , 255, 255;...
                  0  , 0  , 255;...
                  204, 0  , 102;...
                  0  , 153, 0  ;...
                  255, 255, 0  ;...
                  102, 255, 102;...
                  0  , 153, 153;...
                  102, 0  , 102];

    detected_objects = unique(getObject(htm, 'all', 'label'));
    nb_detected_objects = numel(detected_objects);

    if p.Rect
        for iObj = 1:RIR.nb_objects
            tmIdx = getObject(RIR, iObj, 'tmIdx');
            idx = tmIdx(1:getInfo('cpt_object'):end);
            idx(end+1) = tmIdx(end)+1;
            nb_occurences = numel(idx);
            for iOcc = 1:(nb_occurences-1)
                x_beg = idx(iOcc);
                % x_end = idx(iOcc+1)-1;
                x_end = idx(iOcc)+getInfo('cpt_object')-1;
                % x = tmIdx(1);
                % X = [x, x, x+getInfo('cpt_object'), x+getInfo('cpt_object')];
                X = [x_beg, x_beg, x_end, x_end];
                if p.Max
                    Y1 = [0.5, 1, 1, 0.5];
                else
                    Y1 = [0, 1, 1, 0];
                end
                Y2 = [0, 0.5, 0.5, 0];

                if correct(iObj) == -1
                    C1 = C_0;
                elseif correct(iObj) == 1
                    data = getData(htm, iObj);
                    if sum(data(getInfo('nb_audio_labels')+1:end, 3)) > 0
                        C1 = C_2;
                    else
                        C1 = C_3;
                    end
                end

                if correct2(iObj) == -1
                    C2 = C_0;
                elseif correct2(iObj) == 1
                    C2 = C_2;
                else
                    C2 = C_3;
                end

                if p.MFI
                    h1 = patch(X, Y1, C1);%, 'FaceAlpha', 0.6);
                end
                if p.Max
                    h2 = patch(X, Y2, C2);%, 'FaceAlpha', 0.6);
                end
                if all(C1 == C_3)
                    % hp = findobj(h,'type','patch');
                    % hatch(h1, 45, [0.5, 0.5, 0.5], '-', 12, 2);
                end

                posx = find(strcmp(getObject(htm, iObj, 'label'), detected_objects));
                % h1 = patch(X, Y1, colors_vec(pos));%, 'FaceAlpha', 0.6);
                circle_size = 0.045;
                % --- Centering the center around [0, 0]
                % --- 'pos' is: [x, y, width, height]
                pos = [x_beg+1.5, 0.85,...
                       getInfo('cpt_object')-4, circle_size];
                % --- The 'Curvature' is allowing to draw a circle from the 'rectangle' function
                rectangle('Position' , pos  ,...
                          'Curvature', [1 1],...
                          'LineWidth', 2,...
                          'FaceColor', colors_vec(posx, :)/255,...
                          'EdgeColor', 'none');
            end
        end
    end

    if p.Curv
        plot(cpt22(1:end)                  ,...
                'LineWidth', 5             ,...
                'LineStyle', '-'           ,...
                'Color'    , [0.1, 0.1, 0.1]...
                );
                % 'Color'    , [51, 153, 255]/255 ...
        plot(cpt12(1:end)                  ,...
                'LineWidth', 5             ,...
                'LineStyle', '-'           ,...
                'Color'    , [0.6, 0.6, 0.6]...
            );
        plot(htm.statistics.max_mean_shm,...
             'LineWidth', 5,...
             'LineStyle', '-',...
             'Color', [0.8, 0.8, 0.8]);
    end


    lim = [0, 0];
    if sum(p.Objects) == 0
        if sum(p.Lim) == 0
            if p.MinLim == 0
                lim(1) = 1;
            else
                lim(1) = p.MinLim-10;
            end
            if p.MaxLim == 0
                lim(2) = numel(cpt12)+10;
            else
                lim(2) = p.MaxLim+10;
            end
        else
            lim = p.Lim;
        end
    else
        tmIdx = getObject(RIR, p.Objects(1), 'tmIdx');
        lim(1) = tmIdx(1)-20;
        lim(2) = tmIdx(end)+20;
    end
    
    set(gca, 'XLim', lim,...
             'Ylim', [0, 1]);

    title 'Mean of good classification over 1 simulation';
    xlabel 'time steps';
    ylabel 'mean of good classification';
end