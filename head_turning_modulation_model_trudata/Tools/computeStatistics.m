% 'computeStatistics' function
% This function process the data from an HTM simulation
% Author: Benjamin Cohen-Lhyver
% Date: 21.05.16
% Rev. 1.0

function statistics = computeStatistics (htm)
    
    % textprogressbar('HTM: computing statistics -- ');
    
    p = getInfo('audio_labels'    ,...
                'visual_labels'   ,...
                'nb_audio_labels' ,...
                'nb_visual_labels',...
                'nb_labels'       ,...
                'AVPairs'         ,...
                'nb_AVPairs'      ,...
                'nb_steps'         ...
               );

    % htm.statistics.mfi = [htm.statistics.mfi; zeros(p.nb_steps, 1)];
    htm.statistics.mfi = [htm.statistics.mfi; zeros(p.nb_steps, 1)];
    htm.statistics.mfi_mean = zeros(htm.nb_steps_final, 1);
    
    htm.statistics.mfi = strcmp(htm.classif_mfi(:), htm.gtruth(:, 1));
    
    htm.statistics.mfi_mean = cumsum(htm.statistics.mfi) ./ (1:htm.nb_steps_final)';

    % return;

    % =====================

    vec = 0 :0.1: 1;

    mfi = htm.MFI;

    % dv = zeros(1000, 5);
    audio_idx = zeros(1, p.nb_AVPairs);
    visual_idx = zeros(1, p.nb_AVPairs);

    na = numel(audio_idx);
    
    if isempty(htm.statistics.c)
        c = cell(1, p.nb_AVPairs*2);
    else
        c = htm.statistics.c;
    end

    AVpairs = mergeLabels('all');

    for iPair = 1:p.nb_AVPairs
        audio_idx(iPair) = find(strcmp(p.AVPairs{iPair}(2), p.audio_labels));
        visual_idx(iPair) = find(strcmp(p.AVPairs{iPair}(1), p.visual_labels));
    end

    sc = getInfo('scenario');

    for iLabel = sc.unique_idx
        disp(iLabel);

        d = generateProbabilities(audio_idx(iLabel), visual_idx(iLabel), 100);

        for jj = 1:numel(vec)
            da = d;
            da(audio_idx(iLabel), :) = vec(jj);
            est = arrayfun(@(x) mfi.inferCategory(da(:, x)), 1:100, 'UniformOutput', false);
            result = arrayfun(@(x) strcmp(est{x}, AVpairs{iLabel}), 1:100, 'UniformOutput', false);

            c{iLabel}(jj) = mean(cell2mat(result));

            dv = d;
            dv(p.nb_audio_labels+visual_idx(iLabel), :) = vec(jj);
            est = arrayfun(@(x) mfi.inferCategory(dv(:, x)), 1:100, 'UniformOutput', false);
            result = arrayfun(@(x) strcmp(est{x}, AVpairs{iLabel}), 1:100, 'UniformOutput', false);

            c{p.nb_AVPairs+iLabel}(jj) = mean(cell2mat(result));
        end
    end



    %     for ii = 1:100
    %         tmp_ca = zeros(1, numel(vec));
    %         tmp_cv = zeros(1, numel(vec));

    %         % --- Display --- %
    %         % tt = iAudioLabel+iVisualLabel;
    %         % t = 100*((ii+((iLabel-1)*100)) / (numel([audio_idx, visual_idx])*100));
    %         % textprogressbar(t);
    %         % --- Display --- %

    %         d = generateProbabilities(audio_idx(iLabel), visual_idx(iLabel));
    %         for jj = 1:numel(vec)
    %             da = d;
    %             da(audio_idx(iLabel)) = vec(jj);
    %             est = mfi.inferCategory(da);
    %             if strcmp(est, AVpairs{iLabel})
    %                 tmp_ca(jj) = 1;
    %             end

    %             dv = d;
    %             dv(p.nb_audio_labels+visual_idx(iLabel)) = vec(jj);
    %             est = mfi.inferCategory(dv);
    %             if strcmp(est, AVpairs{iLabel})
    %                 tmp_cv(jj) = 1;
    %             end
    %         end

    %         if isempty(c{iLabel})
    %             c{iLabel} = tmp_ca;
    %         else
    %             tmp_ca = [tmp_ca ; c{iLabel}];
    %             c{iLabel} = sum(tmp_ca);
    %         end

            
    %         if isempty(c{p.nb_AVPairs+iLabel})
    %             c{p.nb_AVPairs+iLabel} = tmp_cv;
    %         else
    %             tmp_cv = [tmp_cv ; c{p.nb_AVPairs+iLabel}];
    %             c{p.nb_AVPairs+iLabel} = sum(tmp_cv);
    %         end

    %     end
    %     c{iLabel} = c{iLabel}/ii;
    %     c{p.nb_AVPairs+iLabel} = c{p.nb_AVPairs+iLabel}/ii;
    % end

    % if ~isempty(htm.statistics.c)
    %     for iPair = 1:numel(c)
    %         htm.statistics.c{iPair} = [htm.statistics.c{iPair}, c{iPair}];
    %     end
    % else
        htm.statistics.c = c;
    % end

    % =====================

    htm.MSOM.assignNodesToCategories();

    % =====================

    % textprogressbar(' -- DONE');

    return;

    % =====================

    % for iAudioLabel = 1:p.nb_audio_labels
    %     audio_data = generateProbabilities(iAudioLabel, 1);

    %     for iStep = 1:1000
    %         visual_data = rand(p.nb_visual_labels, 1);

    aa = zeros(1, p.nb_AVPairs);
    vv = zeros(1, p.nb_AVPairs);

    for iPair = 1:p.nb_AVPairs
        aa(iPair) = find(strcmp(AVPairs{iPair}(2), p.audio_labels)) ;
        vv(iPair) = find(strcmp(AVPairs{iPair}(1), p.visual_labels)) ;
    end

    alpha_a = zeros(1, p.nb_audio_labels) ;
    alpha_v = zeros(1, p.nb_visual_labels);
    beta_a  = zeros(1, p.nb_audio_labels) ;
    beta_v  = zeros(1, p.nb_visual_labels);

    mfi = htm.robot.getMFI();

    AVpairs = arrayfun(@(x) mergeLabels(x), 1:p.nb_AVPairs, 'UniformOutput', false);

    iPair = 1;
    % --- Testing the ability of the MFI to correct wrong AV pairings
    while iPair < p.nb_AVPairs

    for iAudioLabel = 1:p.nb_audio_labels
        

        data = generateProbabilities(aa(iAudioLabel), vv(1));
        
        da = data(1:p.nb_audio_labels);
        % dv = data(p.nb_audio_labels+1:end);
        
        cpt5 = 0;
        cpt6 = 0;
        
        iStep = 1;
        
        while iStep < 1000
            random_visual = rand(p.nb_visual_labels, 1);
            [~, m] = max(random_visual);

            if m == vv(iPair)
                iStep = iStep - 1;
            else
                est = mfi.inferCategory([da ; random_visual]);
                if strcmp(est, AVpairs{iPair}) % ------ correction is good
                    alpha_a(iPair) = alpha_a(iPair) + 1;
                elseif find(strcmp(est, AVpairs)) % --- correction is viable (i.e. existing AV pair)
                    beta_a(iPair) = beta_a(iPair) + 1;
                    cpt5 = cpt5 + 1;
                else % -------------------------------- correction is not good
                    cpt5 = cpt5 + 1;
                end
            end
            iStep = iStep + 1;
        end
        alpha_a(iPair) = 100*(alpha_a(iPair)/nb_steps) ;
        beta_a(iPair) = 100*(beta_a(iPair)/cpt5) ;

        iStep = 1 ;

        while iStep < nb_steps
            random_audio = rand(p.nb_audio_labels, 1) ;
            [~, m] = max(random_audio) ;

            if m == aa(iPair)
                iStep = iStep - 1 ;
            else
                est = mfi.inferCategory([random_audio ; dv]) ;
                if strcmp(est, AVpairs{iPair})
                    alpha_v(iPair) = alpha_v(iPair) + 1 ;
                elseif find(strcmp(est, AVpairs))
                    beta_v(iPair) = beta_v(iPair) + 1 ;
                    cpt6 = cpt6 + 1 ;
                else
                    cpt6 = cpt6 + 1 ;
                end
            end
            iStep = iStep + 1 ;
        end
        
        alpha_v(iPair) = 100*(alpha_v(iPair)/nb_steps) ;
        beta_v(iPair) = 100*(beta_v(iPair)/cpt6) ;
    end
    statistics.alpha_a = alpha_a ;
    statistics.alpha_v = alpha_v ;
    statistics.beta_a = beta_a ;
    statistics.beta_v = beta_a ;

    setappdata(0, 'statistics', statistics);

end