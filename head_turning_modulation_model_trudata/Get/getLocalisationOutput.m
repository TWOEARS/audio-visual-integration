function request = getLocalisationOutput (obj)
    if isa(obj, 'Blackboard')
        loc_KS = obj.getLastData('sourcesAzimuthsDistributionHypotheses').data;
    else
        loc_KS = obj.blackboard.getLastData('sourcesAzimuthsDistributionHypotheses').data;
    end
    if ~isempty(loc_KS)
        hyp_loc = loc_KS.sourcesDistribution;
        [~, idx] = max(hyp_loc);
        request = loc_KS.azimuths(idx);
    else
        request = 0;
    end
end