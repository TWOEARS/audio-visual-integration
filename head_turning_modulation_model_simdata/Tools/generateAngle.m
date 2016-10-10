function theta = generateAngle (label)
    % theta = randi(360) ;
    % angles = getInfo('sources_position');
    info = getInfo('all');
    avpairs = mergeLabels(info.AVPairs(info.scenario.scene{1}));
    tmp = strcmp(label, avpairs);
    theta = info.sources_position(tmp);
    % theta = angles(randi(getInfo('nb_angles')));
end