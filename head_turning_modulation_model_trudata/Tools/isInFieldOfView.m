function bool = isInFieldOfView (theta)
	fov = getInfo('fov');

    if theta <= fov
        bool = true ;
    elseif theta >= 360-fov
        bool = true ;
    else
        bool = false ;
    end
end