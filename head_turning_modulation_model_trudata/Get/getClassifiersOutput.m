function data = getClassifiersOutput (obj)
    
    audio_vec = getAudioClassifiersOutput(obj.blackboard);

    data = obj.blackboard.getLastData('visualIdentityHypotheses').data;
    
    present_objects = obj.blackboard.getLastData('visualStreamsHypotheses').data;
    present_objects = present_objects('present_objects');

    visual_vec = zeros(getInfo('nb_visual_labels'), 1);

    visual_vec(present_objects) = data('visual_labels');

end
