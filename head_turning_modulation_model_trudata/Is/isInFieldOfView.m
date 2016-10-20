function bool = isInFieldOfView (theta)
    %theta = getLocalisationOutput(obj.blackboard) ;
    if theta <= getInfo('fov')
        bool = true ;
    elseif theta >= 360-getInfo('fov')
        bool = true ;
    else
        bool = false ;
    end
end