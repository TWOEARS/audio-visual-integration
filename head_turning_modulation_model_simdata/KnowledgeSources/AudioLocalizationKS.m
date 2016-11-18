% AudioLocalizationKS class
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
	hypotheses = [];
	sources_position;
	nb_sources;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = AudioLocalizationKS (htm)
	obj.htm = htm;
	obj.sources_position = getInfo('sources_position');
	obj.nb_sources = getInfo('nb_sources');
end
% === CONSTRUCTOR [END] === %

function execute (obj)
	iStep = obj.htm.iStep;
    % source = obj.htm.sources(iStep); % --- which source is emitting now
    streams = getLastHypothesis(obj.htm, 'SSKS');
    audio_localization_hyp = zeros(obj.nb_sources, 1);
    for iSource = 1:numel(streams)
        if streams(iSource) == 0
            audio_localization_hyp(iSource) = -1;
        else
        	audio_localization_hyp(iSource) = mod(obj.sources_position(iSource)-obj.htm.MOKS.head_position(end), 360);
        end
    end
	% if source == 0
	% 	audio_localization_hyp = -1;
	% else
 %    	audio_localization_hyp = mod(obj.sources_position(source)-obj.htm.MOKS.head_position(end), 360);
	% end

    obj.hypotheses(:, end+1) = audio_localization_hyp;
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end