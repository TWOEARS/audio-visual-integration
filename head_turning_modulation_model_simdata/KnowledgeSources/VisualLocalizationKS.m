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
	
	visual_localization_hyp;
	%hyp_hist = [];

end

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = VisualLocalizationKS (htm)
	obj.htm = htm;
	obj.MOKS = htm.MotorOrderKS;
end
% === CONSTRUCTOR [END] === %

function execute (obj, iStep)
    if ~isempty(obj.MOKS.head_position)
        obj.visual_localization_hyp(end+1) = obj.MOKS.head_position(end);
        %obj.hyp_hist(end+1) = obj.visual_localization_hyp;
    else
        obj.visual_localization_hyp(end+1) = -1;
    end
	% hyp = obj.visual_localization_hyp;
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end