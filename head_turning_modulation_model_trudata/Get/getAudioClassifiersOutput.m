function audio_vec = getAudioClassifiersOutput (blackboard)
    audio_hyp = blackboard.getLastData('identityHypotheses') ;
    audio_vec = cell2mat(arrayfun(@(x) audio_hyp.data(x).p,...
                                  1:getInfo('nb_audio_labels'),...
                                  'UniformOutput', false))' ;
    audio_vec = audio_vec/sum(audio_vec) ;
    audio_vec(isnan(audio_vec)) = 0 ;
end