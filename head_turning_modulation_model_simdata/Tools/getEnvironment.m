function output = getEnvironment (obj, varargin)

    if isa(obj, 'Robot')
        objects = obj.getEnv().objects;
    elseif isa(obj, 'PerceivedEnvironment')
        objects = obj.objects;
    elseif isa(obj, 'HeadTurningModulationKS')
        objects = obj.robot.getEnv().objects;
    end
    
    if nargin > 1
        fnames = fieldnames(obj.environments{end}) ;
        target = find(strcmp(fnames, varargin{1})) ;
        if nargin > 2
            output = obj.environments{end}.(fnames{target}) ;
            output = output{varargin{2}} ;
        else
            output = obj.environments{end}.(fnames{target}) ;
        end
    else
        output = obj.environments{end} ;
    end

    if isempty(output)
        output
    end
end