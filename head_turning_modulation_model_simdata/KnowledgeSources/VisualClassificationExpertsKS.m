% 'VisualClassificationExpertsKS' class
% This knowledge source aims at determining if a new object has appeared in the scene or not
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

classdef VisualClassificationExpertsKS < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)

	htm;

	visual_data;

end

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = VisualClassificationExpertsKS (htm)
	obj.htm = htm;
end
% === CONSTRUCTOR [END] === %

function visual_data = getVisualData (obj)
	iStep = obj.htm.iStep;
	data = obj.htm.gtruth_data(:, iStep);
	obj.visual_data = data(getInfo('nb_audio_labels')+1:end);
	visual_data = obj.visual_data;
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end