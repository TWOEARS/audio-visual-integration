function bool = isFocusedObjectPresent (obj)
    if obj.HTM_robot.getObj(obj.HTM_robot.focus, 'presence')
        bool = true ;
    else
        bool = false ;
    end
end