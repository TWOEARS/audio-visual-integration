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
	% avpairs
	sources_position;

end

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = AudioLocalizationKS (htm)
	obj.htm = htm;
	obj.sources_position = getInfo('sources_position');
    % obj.avpairs = mergeLabels(info.AVPairs(info.scenario.scene{1}));
    % obj.sources_position = info.sources_position;
end
% === CONSTRUCTOR [END] === %

function execute (obj)
	iStep = obj.htm.iStep;
    % label = obj.htm.gtruth{iStep, 1};
    % tmp = strcmp(label, avpairs);
    source = obj.htm.sources(iStep);
	if source == 0
		audio_localization_hyp = -1;
	else
    	audio_localization_hyp = abs(obj.sources_position(source) - obj.htm.RIR.head_position);
	end

    % if isempty(audio_localization_hyp)
    % 	audio_localization_hyp = -1;
    % end
    obj.hyp_hist(end+1) = audio_localization_hyp;
    % obj.audio_localization_hyp = audio_localization_hyp;
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end