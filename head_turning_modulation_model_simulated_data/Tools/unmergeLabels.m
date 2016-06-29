function [visual_labels, audio_labels] = unmergeLabels (varargin)

    if nargin == 1 && isstr(varargin{1})
        varargin{1} = {varargin{1}};
    end

    if iscell(varargin{1})
        pairs = varargin{1};
        visual_labels = cell(size(pairs, 1), 1);
        audio_labels = cell(size(pairs, 1), 1);
        for iPair = 1:size(pairs, 1)
            uscore_pos = strfind(pairs{iPair}, '_');
            visual_labels{iPair} = pairs{iPair}(1:uscore_pos-1);
            audio_labels{iPair} = pairs{iPair}(uscore_pos+1:end);
        end
  %   elseif nargin == 1 && strcmp(varargin{1}, 'all')
		% AVPairs = getInfo('AVPairs');
  %       AVPair = cell(getInfo('nb_AVPairs'), 1);
  %       for iPair = 1:getInfo('nb_AVPairs')
  %           AVPair{iPair} = [AVPairs{iPair}{1}, '_', AVPairs{iPair}{2}];
  %       end
  %   elseif nargin == 1 && isnumeric(varargin{1})
  %       pair_idx = varargin{1}
  %       AVPairs = getInfo('AVPairs');
		% AVPair = [AVPairs{pair_idx}{1}, '_', AVPairs{pair_idx}{2}];
  %   else
		% p = getInfo('audio_labels', 'visual_labels');
		% AVPair = [p.visual_labels{varargin{1}}, '_', p.audio_labels{varargin{2}}];
	end
end
