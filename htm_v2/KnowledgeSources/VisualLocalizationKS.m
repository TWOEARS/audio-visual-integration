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
	
	hypotheses = [];

	nb_angles;
	correct = [];
	true_angles = [];

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
function obj = VisualLocalizationKS (htm)
	global information;
	obj.htm = htm;
	obj.MOKS = htm.MOKS;

	obj.nb_angles = 360/information.loca_sensitivity;
	obj.sources_position = information.sources_position;
end
% === CONSTRUCTOR [END] === %

function execute (obj)
    global information;

	iStep = obj.htm.iStep;
	hyp = zeros(1, 72);
	theta_vec = 0:5:359;
	dif = abs(obj.sources_position - obj.htm.MOKS.head_position(end));
	pos = find(dif <= information.fov);
	if ~isempty(pos)
		for iPos = 1:numel(pos)
			decision = rand();
			if decision > 0.2
				s = find(theta_vec == obj.sources_position(pos(iPos)));
            else
                s = randi(72, 1);
            end
            hyp(s) = (1-0.7)*rand() + 0.7;
            idx = 1:72;
            idx(idx == s) = [];
            hyp(idx) = (1-0.8)*rand(1, 71);
        end
		%[hyp, ~, bool] = degradeLocalisation(obj.htm.MOKS.head_position(end), obj.nb_angles);
    end

    new_hyp = zeros(72, 1);
	% vec1 = 1:5:355;
	pos = obj.htm.MOKS.head_position(end)/5+1;
	vec2 = [pos:72, 1:pos-1];
	for iAngle = 1:72
		new_hyp(vec2(iAngle)) = hyp(iAngle);
	end
	obj.hypotheses(:, end+1) = new_hyp;
                
    % obj.hypotheses(:, end+1) = hyp;
    %obj.correct(end+1) = bool;
    %obj.true_angles(end+1) = obj.htm.MOKS.head_position(end);
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === END OF FILE === % 
% =================== %
end