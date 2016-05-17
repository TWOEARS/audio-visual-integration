function bool = isSoundPresent (obj)
    tmp = getClassifiersOutput(obj) ;
    if sum(tmp(1:getInfo('nb_audio_labels'))) < 0.9
        bool = false ;
    else
        bool = true ;
    end
end