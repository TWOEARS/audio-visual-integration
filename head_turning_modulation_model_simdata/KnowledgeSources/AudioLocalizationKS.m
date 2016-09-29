% 'AudioLocalizationKS' class
% This knowledge source aims at determining if a new object has appeared in the scene or not
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

classdef AudioLocalizationKS < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)

	htm;

	audio_localization_hyp;
	hyp_hist = [];

end

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = AudioLocalizationKS (htm)
	obj.htm = htm;
end
% === CONSTRUCTOR [END] === %

function audio_localization_hyp = getAudioLocalization (obj)
	iStep = obj.htm.iStep;
	info = getInfo('all');
    avpairs = mergeLabels(info.AVPairs(info.scenario.scene{1}));
    label = obj.htm.gtruth{iStep, 1};
    tmp = strcmp(label, avpairs);
    audio_localization_hyp = abs(info.sources_position(tmp) - obj.htm.MotorOrderKS.head_position);
    if isempty(audio_localization_hyp)
    	audio_localization_hyp = -1;
    end
    obj.hyp_hist(end+1) = audio_localization_hyp;
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end