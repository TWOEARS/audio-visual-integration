function request = getClassifiersOutput (obj)
    audio_vec = getAudioClassifiersOutput(obj.blackboard) ;

    if isInFieldOfView(obj)
        visual_vec = getVisualClassifiersOutput(obj) ;
    else
        visual_vec = zeros(obj.nb_visual_labels, 1) ;
    end

    request = [audio_vec ; visual_vec] ;
end
