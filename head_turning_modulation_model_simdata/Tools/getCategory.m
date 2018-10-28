function request = getCategory (obj, idx, field, varargin)

    if isa(obj, 'PerceivedEnvironment')
        % obs_cat = obj.DW.observed_categories;
        obs_cat = obj.MFI.observed_categories;
    elseif isa(obj, 'HeadTurningModulationKS')
        % obs_cat = obj.DW.observed_categories;
        obs_cat = obj.MFI.observed_categories;
    % elseif isa(obj, 'DynamicWeighting')
    elseif isa(obj, 'MultimodalFusionAndInference')
        obs_cat = obj.observed_categories;
    else
        % obs_cat = obj.htm.DW.observed_categories;
        obs_cat = obj.htm.MFI.observed_categories;
    end

    if isempty(obs_cat)
    	request = false;
        return;
    end
    
    if nargin == 2
        field = 'all';
    end

    if nargin == 4 && strcmp(varargin{1}, 'Object')
        idx = getObject(obj, idx, 'audiovisual_category');
    elseif nargin == 3 && strcmp(field, 'Object')
        idx = getObject(obj, idx, 'audiovisual_category');
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
        request.(fname) = cell2mat(arrayfun(@(x) obs_cat{x}.(field{iField}), idx, 'UniformOutput', false));
    end

    if numel(field) == 1
        request = request.(fname);
    end

end