% 'AudioClassificationExpertsKS' class
% This knowledge source aims at determining if a new object has appeared in the scene or not
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

classdef AudioClassificationExpertsKS < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)

	htm;

	audio_data;

end

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = AudioClassificationExpertsKS (htm)
	obj.htm = htm;
end
% === CONSTRUCTOR [END] === %

function audio_data = getAudioData (obj)
	iStep = obj.htm.iStep;
	data = obj.htm.gtruth_data(:, iStep);
	audio_data = data(1:getInfo('nb_audio_labels'));
	obj.audio_data = audio_data;
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end