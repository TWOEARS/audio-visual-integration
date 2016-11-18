% StreamSegregationKS class
% This knowledge source aims at determining the number of streams in the actual frame
% Author: Benjamin Cohen-Lhyver
% Date: 16.11.16
% Rev. 1.0

classdef StreamSegregationKS < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
	htm;
	hypotheses = [];
    sources_position;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = StreamSegregationKS (htm)
	obj.htm = htm;
	obj.sources_position = getInfo('sources_position');
end
% === CONSTRUCTOR [END] === %

function execute (obj)
    iStep = obj.htm.iStep;
    streams = zeros(getInfo('nb_sources'), 1);
    for iSource = 1:getInfo('nb_sources')
        if sum(obj.htm.data{iSource}(:, iStep)) ~= 0
            streams(iSource) = iSource;
        end
    end
    obj.hypotheses(:, end+1) = streams;
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end