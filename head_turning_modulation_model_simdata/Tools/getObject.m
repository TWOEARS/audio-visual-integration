% GETOBJECT - get information of an object
%
% This HTM function provides the information about the IDX object observed
% by the robot from the OBJ class.
%
% o = getObject(obj, idx)
% o = getObject(obj, idx, field)
%
% Example: o = getObject(htm, 2, 'audio_label')
% author: Benjamin Cohen-Lhyver
% version 1.0

function request = getObject (obj, idx, varargin)

    if isa(obj, 'PerceivedEnvironment')
        objects = obj.objects;
    else
        env = getEnvironment(obj, 0);
        objects = env.objects;
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
            if isnumeric(request{1}) || islogical(request{1})
                request = cell2mat(request)';
            else
                request = request';
            end
        else
            request = objects{idx}.(varargin{1});
        end
    end
end