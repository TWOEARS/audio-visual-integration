function data = getClassifiersOutput (obj)
    
    audio_vec = getAudioClassifiersOutput(obj.blackboard);

    data = obj.blackboard.getLastData('visualIdentityHypotheses').data;
    
    present_objects = obj.blackboard.getLastData('visualStreamsHypotheses').data;
    present_objects = present_objects('present_objects');

    % if numel(present_objects) > 1
    % 	present_objects = cell2mat(present_objects);
    % end

    % visual_vec = zeros(getInfo('nb_visual_labels'), 1);

    % visual_vec(present_objects) = 1;

    % data = [audio_vec ; visual_vec];
    data = [audio_vec ; data('visual_vec')];

end
