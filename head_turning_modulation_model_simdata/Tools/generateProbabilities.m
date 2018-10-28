function data = generateProbabilities (audio_idx, visual_idx, number)

    if nargin == 2
        number = 1;
    end

    lambda = getInfo('lambda');
    % --- Audio vector
    nb_audio = getInfo('nb_audio_labels') ;
    % audio_idx = audio(2) ;
    nb_visual = getInfo('nb_visual_labels') ;

    data = zeros(getInfo('nb_labels'), number);

    for iStep = 1:number
        audio_vec = zeros(nb_audio, 1) ;
        tmp = (1-lambda)*rand + lambda ;
        audio_vec(audio_idx) = tmp ;
        
        idx_vec = 1:nb_audio ;
        idx_vec(idx_vec == audio_idx) = [] ;
        
        
        audio_vec(idx_vec) = (1-0.5)*rand(nb_audio-1, 1);
        % for iComp = idx_vec
        %     audio_vec(iComp) = 1-((1-sum(audio_vec))*rand + sum(audio_vec)) ;
        % end
        % audio_vec = audio_vec/sum(audio_vec) ;

        % --- Visual vector
        % visual_idx = visual(2) ;
        
        visual_vec = zeros(nb_visual, 1) ;
        tmp = (1-lambda)*rand + lambda ;
        
        visual_vec(visual_idx) = tmp ;
        
        idx_vec = 1:nb_visual ;
        idx_vec(idx_vec == visual_idx) = [] ;
        
        visual_vec(idx_vec) = (1-0.5)*rand(nb_visual-1, 1) ;

        % for iComp = idx_vec
        %     visual_vec(iComp) = 1-((1-sum(visual_vec))*rand + sum(visual_vec)) ;
        % end
        % visual_vec = visual_vec/sum(visual_vec) ;
        data(:, iStep) = [audio_vec ; visual_vec] ;
    end
end