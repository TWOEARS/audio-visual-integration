function bool = isFocusedObjectPresent (RIR)
    if RIR.getObj(RIR.focus, 'presence')
        bool = true ;
    else
        bool = false ;
    end
end