function data = generateProbabilities (audio_idx, visual_idx)
    % --- Audio vector
    audio_vec = zeros(obj.nb_audio_labels, 1) ;
    tmp = (1-0.6)*rand + 0.6 ;
    audio_vec(audio_idx) = tmp ;
    
    idx_vec = 1:obj.nb_audio_labels ;
    idx_vec(idx_vec == audio_idx) = [] ;
    
    audio_vec(idx_vec) = (1-0.5)*rand(obj.nb_audio_labels-1, 1) ;
    % for iComp = idx_vec
    %     audio_vec(iComp) = 1-((1-sum(audio_vec))*rand + sum(audio_vec)) ;
    % end
    % audio_vec = audio_vec/sum(audio_vec) ;

    % --- Visual vector
    visual_vec = zeros(obj.nb_visual_labels, 1) ;
    tmp = (1-0.6)*rand + 0.6 ;
    
    visual_vec(visual_idx) = tmp ;
    
    idx_vec = 1:obj.nb_visual_labels ;
    idx_vec(idx_vec == visual_idx) = [] ;
    
    visual_vec(idx_vec) = (1-0.5)*rand(obj.nb_visual_labels-1, 1) ;

    % for iComp = idx_vec
    %     visual_vec(iComp) = 1-((1-sum(visual_vec))*rand + sum(visual_vec)) ;
    % end
    % visual_vec = visual_vec/sum(visual_vec) ;
    data = [audio_vec ; visual_vec] ;
end