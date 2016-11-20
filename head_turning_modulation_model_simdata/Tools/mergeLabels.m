function AVPair = mergeLabels (varargin)

    % information = getInfo('all');
    global information;
    % --- cell of pairs to merge
    if iscell(varargin{1}) %&& isstr(varargin{1}{1})
        pairs = varargin{1};
        AVPair = cell(size(pairs, 1), 1);
        for iPair = 1:size(pairs, 1)
            AVPair{iPair} = strjoin(pairs{iPair}, '_');
        end
    % --- all pairs have to be merged
    elseif nargin == 1 && strcmp(varargin{1}, 'all')
		AVPairs = information.AVPairs;
        AVPair = cell(information.nb_AVPairs, 1);
        for iPair = 1:information.nb_AVPairs
            AVPair{iPair} = strjoin(AVPairs{iPair}, '_');
        end
    % --- one 
    elseif nargin == 1 && numel(varargin{1}) == 1
        AVPairs = information.AVPairs;
		AVPair = strjoin(AVPairs{varargin{1}}, '_');
    elseif nargin == 2 && strcmp(varargin{2}, 'pairs')
        pairs = information.AVPairs;
        %AVPair = cell(size(pairs, 2), 1);
        AVPair = cell(0);
        for iPair = varargin{1}
            AVPair{end+1} = [pairs{iPair}{1}, '_', pairs{iPair}{2}];
        end
    else
        AVPair = [information.visual_labels{varargin{1}}, '_' information.audio_labels{varargin{2}}];
		%AVPair = strjoin({information.visual_labels{varargin{1}}, information.audio_labels{varargin{2}}}, '_');
	end
end
