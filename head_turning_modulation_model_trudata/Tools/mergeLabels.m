function AVPair = mergeLabels (varargin)
    
    if iscell(varargin{1}) %&& isstr(varargin{1}{1})
        pairs = varargin(1);
        AVPair = cell(size(pairs, 1), 1);
        for iPair = 1:size(pairs, 1)
            AVPair{iPair} = strjoin(pairs{iPair}, '_');
        end
    elseif nargin == 1 && strcmp(varargin{1}, 'all')
		AVPairs = getInfo('AVPairs');
        AVPair = cell(getInfo('nb_AVPairs'), 1);
        for iPair = 1:getInfo('nb_AVPairs')
            AVPair{iPair} = strjoin(AVPairs{iPair}, '_');
        end
    elseif nargin == 1 && numel(varargin{1}) == 1
        AVPairs = getInfo('AVPairs');
		AVPair = strjoin(AVPairs{varargin{1}}, '_');
    elseif nargin == 2 && strcmp(varargin{2}, 'pairs')
        pairs = getInfo('AVPairs');
        %AVPair = cell(size(pairs, 2), 1);
        AVPair = cell(0);
        for iPair = varargin{1}
            AVPair{end+1} = [pairs{iPair}{1}, '_', pairs{iPair}{2}];
        end
    else
		p = getInfo('audio_labels', 'visual_labels');
		AVPair = strjoin({p.visual_labels{varargin{1}}, p.audio_labels{varargin{2}}}, '_');
	end
end
