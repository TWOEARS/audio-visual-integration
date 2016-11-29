function request = getLocalisationOutput (obj)
    if isa(obj, 'Blackboard')
        loc_KS = obj.getLastData('sourcesAzimuthsDistributionHypotheses').data;
    else
        obj = obj.blackboard;
        loc_KS = obj.getLastData('sourcesAzimuthsDistributionHypotheses').data;
    end
    if ~isempty(loc_KS)
        head_position = obj.bbs.getCurrentHeadOrientation;

        hyp_loc = loc_KS.sourcesDistribution;
        [value, idx] = max(hyp_loc);
        % if value > 0.5
        request = mod(loc_KS.azimuths(idx)+head_position, 360);
        % else
        %     request = 0;
        % end
    else
        request = -1;
    end
end