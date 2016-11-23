function hypothesis = getHypothesis (obj, KS, varargin)

    if isa(obj, 'HeadTurningModulationKS')
        htm = obj;
    else
        htm = obj.htm;
    end

	if strcmp(KS, 'ODKS')
        if nargin == 2
            hypothesis.create_new = htm.ODKS.create_new;
            hypothesis.update_object = htm.ODKS.update_object;
            hypothesis.id_object = htm.ODKS.id_object;
        else
            hypothesis = htm.ODKS.(varargin{1});
        end
    else
        hypothesis = htm.(KS).hypotheses;
	end
			
end