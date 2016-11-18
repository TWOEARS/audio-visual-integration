function setObject (obj, idx, parameter, value)

    if isa(obj, 'PerceivedEnvironment')
        objects = obj.objects;
    else
        env = getEnvironment(obj, 0);
        objects = env.objects;
    end

    if idx == 0
        idx = numel(objects);
    end

    if isempty(objects)
        return;
    end

    if strcmp(parameter, 'requests') && strcmp(value, 'init')
        objects{idx}.initializeRequests();
    else
        for iObject = idx
            objects{iObject}.(parameter) = value;
        end
    end

end