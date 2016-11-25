% 'VisualLocalizationKS' class
% This knowledge source aims at determining if a new object has appeared in the scene or not
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

classdef VisualLocalizationKS < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
	
	htm;
	MOKS;
	
	hypotheses;

	detected_sources;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = VisualLocalizationKS (htm)
	obj.htm = htm;
	obj.MOKS = htm.MOKS;
end
% === CONSTRUCTOR [END] === %

function execute (obj)
	head_position = obj.MOKS.head_position;
    if ~isempty(obj.MOKS.head_position)
        obj.hypotheses(end+1) = head_position(end);
    else
        obj.hypotheses(end+1) = -1;
    end
    % if isempty()
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === END OF FILE === % 
% =================== %
end