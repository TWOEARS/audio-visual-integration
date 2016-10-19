function hypothesis = getLastHypothesis (obj, KS, varargin)

	if isa(obj, 'RobotInternalRepresentation')
        htm = obj.htm;
    elseif isa(obj, 'PerceivedEnvironment')
        htm = obj.htm;
    elseif isa(obj, 'HeadTurningModulationKS')
        htm = obj;
    else
        disp('provide good arguments please.');
        return;
    end

	if strcmp(KS, 'ALKS') || strcmp(KS, 'VLKS')
		hypothesis = htm.(KS).hypotheses(end);
	elseif strcmp(KS, 'ODKS')
		hypothesis = htm.(KS).(varargin{1})(end);
	end
			
end