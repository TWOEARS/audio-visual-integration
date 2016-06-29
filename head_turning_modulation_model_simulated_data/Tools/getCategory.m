function request = getCategory (obj, idx, field)

    if isa(obj, 'Robot')
        obs_cat = obj.getEnv().observed_categories;
    elseif isa(obj, 'PerceivedEnvironment')
        obs_cat = obj.observed_categories;
    elseif isa(obj, 'HeadTurningModulationKS')
        obs_cat = obj.robot.getEnv().observed_categories;
    end

    if isempty(obs_cat)
    	request = false;
        return;
    end
    
    if nargin == 2
        field = 'all';
    end

    % if strcmp(field, 'all')
    %     idx = 1:numel(objects);
    % elseif idx == 0
    %     idx = numel(objects);
    % end
    
    if isstr(idx) && ~strcmp(idx, 'all')
        idx = find(arrayfun(@(x) strcmp(obs_cat{x}.label, idx), 1:numel(obs_cat)));
    elseif isstr(idx) && strcmp(idx, 'all')
        idx = 1:numel(obs_cat);
    end

    if strcmp(field, 'all')
        field = fieldnames(obs_cat{1});
    elseif isstr(field)
        field = {field};
    end
    % request = cell(numel(field), 1);
    % request = cell(numel(field), 1);

    request = struct();

    for iField = 1:numel(field)
        fname = char(field(iField));
        request.(fname) = arrayfun(@(x) obs_cat{x}.(field{iField}), idx, 'UniformOutput', false);
        % request{iField} = arrayfun(@(x) obs_cat{x}.(field{iField}), idx, 'UniformOutput', false);
    end
    % request = request{:};

    if numel(field) == 1
        request = request.(fname);
    end

end