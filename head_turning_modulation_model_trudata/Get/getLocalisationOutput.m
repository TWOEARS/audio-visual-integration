function request = getLocalisationOutput (obj)
    if isa(obj, 'Blackboard')
        loc_KS = obj.getLastData('sourcesAzimuthsDistributionHypotheses').data;
    elseif isa(obj, 'ObjectDetectionKS') || isa(obj, 'HeadTurningModulationKS')
        loc_KS = obj.blackboard.getLastData('sourcesAzimuthsDistributionHypotheses').data;
        head_position = obj.blackboardSystem.robotConnect.getCurrentHeadOrientation();
    else
        loc_KS = obj.blackboard.getLastData('sourcesAzimuthsDistributionHypotheses').data;
        head_position = obj.robot.getCurrentHeadOrientation;
    end

    if ~isempty(loc_KS)
        hyp_loc = loc_KS.sourcesDistribution;
        [value, idx] = max(hyp_loc);
        % if value > 0.5
        theta = loc_KS.azimuths(idx);
        if request <= 195 || request >= 165
            request = theta - 180;
        end
        request = mod(theta+head_position, 360);
        % else
        %     request = 0;
        % end
    else
        request = -1;
    end
end