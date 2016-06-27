
function computeStatisticalPerformance (obj)

    [~, ma] = max(obj.data(1:obj.nb_audio_labels, :)) ;
    [~, mv] = max(obj.data(obj.nb_audio_labels+1:end, :)) ;

    classif_max = cell(1, obj.cpt) ;
    thr_a = 1/obj.nb_audio_labels ;
    thr_v = 1/obj.nb_visual_labels ;
    eq_prob_thr_a = [thr_a-0.2, thr_a+0.2] ;
    eq_prob_thr_v = [thr_v-0.2, thr_v+0.2] ;
    
    for iCpt = 1:obj.cpt
        a = obj.data(1:obj.nb_audio_labels, iCpt) ;
        v = obj.data(obj.nb_audio_labels+1:end, iCpt) ;
        
        if sum(a) < 0.2 && sum(v) < 0.2
            classif_max{iCpt} = 'none_none' ;
        elseif all(a <= eq_prob_thr_a(2)) && all(a >= eq_prob_thr_a(1))
            classif_max{iCpt} = 'none_none' ;
        elseif all(v <= eq_prob_thr_v(2)) && all(v >= eq_prob_thr_v(1))
            classif_max{iCpt} = 'none_none' ;
        elseif sum(a) < 0.2
            classif_max{iCpt} = [obj.visual_labels{mv(iCpt)}, '_', 'none'] ;
        elseif sum(v) < 0.2
            classif_max{iCpt} = ['none', '_', obj.audio_labels{ma(iCpt)}] ;
        else
            classif_max{iCpt} = [obj.visual_labels{mv(iCpt)}, '_', obj.audio_labels{ma(iCpt)}] ;
        end
    end

    obj.classif_max = classif_max ;

    n = obj.cpt ;
    cpt1 = 0 ;
    cpt11 = zeros(1, n) ;
    cpt12 = zeros(1, n) ;
    cpt2 = 0 ;
    cpt21 = zeros(1, n) ;
    cpt22 = zeros(1, n) ;
    cpt3 = 0 ;

    for iCpt = 1:obj.cpt
        if strcmp(classif_max(iCpt), obj.gtruth(iCpt))
            cpt1 = cpt1 + 1 ;
            cpt11(iCpt) = 1 ;
        end

        if strcmp(obj.classif_mfi(iCpt), obj.gtruth(iCpt))
            cpt2 = cpt2 + 1 ;
            cpt21(iCpt) = 1 ;
        end
        cpt12(iCpt) = mean(cpt11(1:iCpt)) ;
        cpt22(iCpt) = mean(cpt21(1:iCpt)) ;
    end

    obj.statistics.max = cpt11 ;
    obj.statistics.max_mean = cpt12 ;
    obj.statistics.mfi = cpt21 ;
    obj.statistics.mfi_mean = cpt22 ;

    % =====================

    aa = zeros(1, numel(obj.AVPairs)) ;
    vv = zeros(1, numel(obj.AVPairs)) ;

    for iPair = 1:numel(obj.AVPairs)
        aa(iPair) = find(strcmp(obj.AVPairs{iPair}(2), obj.audio_labels)) ;
        vv(iPair) = find(strcmp(obj.AVPairs{iPair}(1), obj.visual_labels)) ;
    end

    alpha_a = zeros(1, obj.nb_audio_labels) ;
    alpha_v = zeros(1, obj.nb_visual_labels) ;
    beta_a = zeros(1, obj.nb_audio_labels) ;
    beta_v = zeros(1, obj.nb_visual_labels) ;

    mfi = obj.HTM_robot.getMFI() ;

    for iPair = 1:numel(obj.AVPairs)
        AVPairs{iPair} = [obj.AVPairs{iPair}{1}, '_', obj.AVPairs{iPair}{2}] ;
    end

    nb_steps = 1000 ;

    for iPair = 1:numel(obj.AVPairs)
        iStep = 1 ;
        data = generateProbabilities(aa(iPair), vv(iPair)) ;
        da = data(1:obj.nb_audio_labels) ;
        dv = data(obj.nb_audio_labels+1:end) ;
        cpt5 = 0 ;
        cpt6 = 0 ;
        while iStep < nb_steps

            random_visual = rand(obj.nb_visual_labels, 1) ;
            [~, m] = max(random_visual) ;

            if m == vv(iPair)
                iStep = iStep - 1 ;
            else
                est = mfi.inferCategory([da ; random_visual]) ;
                if strcmp(est, AVPairs{iPair})
                    alpha_a(iPair) = alpha_a(iPair) + 1 ;
                elseif find(strcmp(est, AVPairs))
                    beta_a(iPair) = beta_a(iPair) + 1 ;
                    cpt5 = cpt5 + 1 ;
                else
                    cpt5 = cpt5 + 1 ;
                end
            end
            iStep = iStep + 1 ;
        end
        alpha_a(iPair) = 100*(alpha_a(iPair)/nb_steps) ;
        beta_a(iPair) = 100*(beta_a(iPair)/cpt5) ;

        iStep = 1 ;

        while iStep < nb_steps
            random_audio = rand(obj.nb_audio_labels, 1) ;
            [~, m] = max(random_audio) ;

            if m == aa(iPair)
                iStep = iStep - 1 ;
            else
                est = mfi.inferCategory([random_audio ; dv]) ;
                if strcmp(est, AVPairs{iPair})
                    alpha_v(iPair) = alpha_v(iPair) + 1 ;
                elseif find(strcmp(est, AVPairs))
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
        cpt5, cpt6
    end
    obj.statistics.alpha_a = alpha_a ;
    obj.statistics.alpha_v = alpha_v ;
    obj.statistics.beta_a = beta_a ;
    obj.statistics.beta_v = beta_a ;

end