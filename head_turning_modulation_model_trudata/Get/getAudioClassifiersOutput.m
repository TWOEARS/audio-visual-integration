function audio_vec = getAudioClassifiersOutput (blackboard)
    audio_hyp = blackboard.getLastData('auditoryIdentityHypotheses') ;
    audio_vec = cell2mat(arrayfun(@(x) audio_hyp.data(x).p,...
                                  1:numel(audio_hyp.data),...
                                  'UniformOutput', false))' ;
    audio_vec = audio_vec/sum(audio_vec) ;
    audio_vec(isnan(audio_vec)) = 0 ;
end