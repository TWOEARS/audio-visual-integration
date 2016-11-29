function request = getLocalisationOutput (obj)
    if isa(obj, 'Blackboard')
        loc_KS = obj.getLastData('sourcesAzimuthsDistributionHypotheses').data;
    else
        loc_KS = obj.blackboard.getLastData('sourcesAzimuthsDistributionHypotheses').data;
    end
    if ~isempty(loc_KS)
        hyp_loc = loc_KS.sourcesDistribution;
        [value, idx] = max(hyp_loc);
        % if value > 0.5
            request = loc_KS.azimuths(idx);
        % else
        %     request = 0;
        % end
    else
        request = -1;
    end
end