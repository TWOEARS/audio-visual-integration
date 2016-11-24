function request = getEnvironment(obj, idx, varargin)

	if isa(obj, 'RobotInternalRepresentation')
        env = obj.environments;
    elseif isa(obj, 'HeadTurningModulationKS')
        env = obj.RIR.environments;
    else
        env = obj.htm.RIR.environments;
    end

    if isempty(env)
    	request = false;
        return;
    end

    if isstr(idx) && strcmp(idx, 'all')
        idx = 1:numel(env);
    elseif idx == 0
        idx = numel(env);
    end
    
    if nargin == 2
        if numel(idx) > 1
            request = arrayfun(@(x) env{x}    ,...
                               idx            ,...
                               'UniformOutput', false...
                               );

        else
            request = env{idx};
        end
    elseif nargin == 3
        if numel(idx) > 1
            request = arrayfun(@(x) env{x}.(varargin{1}),...
                               idx                          ,...
                               'UniformOutput', false...
                               );
            if isnumeric(request{1}) || islogical(request{1})
                request = cell2mat(request)';
            else
                request = request';
            end
        else
            request = env{idx}.(varargin{1});
        end
    end


end