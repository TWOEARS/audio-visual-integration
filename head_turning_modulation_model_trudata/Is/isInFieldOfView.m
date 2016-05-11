function bool = isInFieldOfView (obj)
    theta = getLocalisationOutput(obj.blackboard) ;
    if theta <= obj.fov
        bool = true ;
    elseif theta >= 360-obj.fov
        bool = true ;
    else
        bool = false ;
    end
end