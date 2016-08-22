function theta = generateAngle ()
    % theta = randi(360) ;
    angles = getInfo('sources_position');
    theta = angles(randi(getInfo('nb_angles')));
end