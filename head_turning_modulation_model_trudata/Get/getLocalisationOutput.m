function request = getLocalisationOutput (obj)
    if isa(obj, 'Blackboard')
        hyp_loc = obj.getLastData('locationHypotheses') ;
    else
        hyp_loc = obj.blackboard.getLastData('locationHypotheses') ;
    end
    if ~isempty(hyp_loc)
        hyp_loc = hyp_loc.data ;
        [~, idx] = max(hyp_loc.posteriors) ;
        request = hyp_loc.locations(idx) ;
    else
        request = 0 ;
    end
end