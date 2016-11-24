function hypothesis = getLastHypothesis (obj, KS, varargin)

    if isa(obj, 'HeadTurningModulationKS')
        htm = obj;
    else
        htm = obj.htm;
    end

	if strcmp(KS, 'ODKS') || strcmp(KS, 'FCKS')
		hypothesis = htm.(KS).(varargin{1})(:, end);
    elseif strcmp(KS, 'SSKS') || strcmp(KS, 'ALKS')
        hypothesis = htm.(KS).hypotheses(:, end);
    else
        hypothesis = htm.(KS).hypotheses(end);
	end
			
end