function data = getClassifiersOutput (obj)
    
    audio_vec = getAudioClassifiersOutput(obj.blackboard);

    data = obj.blackboard.getLastData('visualIdentityHypotheses').data;
    visual_vec = zeros(getInfo('nb_visual_labels'), 1);

function audio_vec = getAudioClassifiersOutput (blackboard)
    audio_hyp = blackboard.getLastData('identityHypotheses') ;
    audio_vec = cell2mat(arrayfun(@(x) audio_hyp.data(x).p,...
                                  1:getInfo('nb_audio_labels'),...
                                  'UniformOutput', false))' ;
    audio_vec = audio_vec/sum(audio_vec) ;
    audio_vec(isnan(audio_vec)) = 0 ;
end

    % if isInFieldOfView(obj)
    %     visual_vec = getVisualClassifiersOutput(obj);
    % else
    %     visual_vec = zeros(getInfo('nb_visual_labels'), 1);
    % end

    %request = [audio_vec ; visual_vec];
end
