function request = getObject (obj, idx, varargin)

    if isa(obj, 'RobotInternalRepresentation')
        objects = obj.getEnv().objects;
    elseif isa(obj, 'PerceivedEnvironment')
        objects = obj.objects;
    elseif isa(obj, 'HeadTurningModulationKS')
        objects = obj.RIR.getEnv().objects;
    end

    if isempty(objects)
    	request = false;
        return;
    end

    if isstr(idx) && strcmp(idx, 'all')
        idx = 1:numel(objects);
    elseif idx == 0
        idx = numel(objects);
    end

    % if isstr(idx) 
    %     if strcmp(idx, 'all')
    %         idx = 1:numel(objects);
    %     % else
    %     %     find(strcmp(idx, ))
    %     end
    % end

    if nargin == 2
        if numel(idx) > 1
            request = arrayfun(@(x) objects{x},...
                               idx            ,...
                               'UniformOutput', false...
                               );

        else
            request = objects{idx};
        end
    elseif nargin == 3
        if numel(idx) > 1
            request = arrayfun(@(x) objects{x}.(varargin{1}),...
                               idx                          ,...
                               'UniformOutput', false...
                               );
            if isnumeric(request{1})
                request = cell2mat(request)';
            else
                request = request';
            end
        else
            request = objects{idx}.(varargin{1});
        end
    end
end