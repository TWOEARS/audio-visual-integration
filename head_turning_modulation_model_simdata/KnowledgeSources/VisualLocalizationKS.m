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
	hyp_hist = [];

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

function hyp = getVisualLocalization (obj, iStep)
	obj.visual_localization_hyp = obj.MOKS.head_position;
	obj.hyp_hist(end+1) = obj.visual_localization_hyp;
	hyp = obj.visual_localization_hyp;
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end