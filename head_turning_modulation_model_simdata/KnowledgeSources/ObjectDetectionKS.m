% 'ObjectDetectionKS' class
% This knowledge source aims at determining if a new object has appeared in the scene or not
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

classdef ObjectDetectionKS < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
	htm; % Head_Turning_Modulation KS
	RIR; % Robot_Internal_Representation KS
	
	create_new = [];
	update_object = [];
	id_object = [];
end

properties (SetAccess = private, GetAccess = private)
	thr_theta;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = ObjectDetectionKS (htm)
	obj.htm = htm;
	obj.RIR = htm.RIR;
	obj.thr_theta = getInfo('thr_theta');
end
% === CONSTRUCTOR [END] === %

function execute (obj)

	theta_a = getLastHypothesis(obj.htm, 'ALKS');
	if theta_a == -1
		hyp = [0, 0, 0];
	else
		putative_audio_object = [];
		nb_objects = obj.RIR.nb_objects;
		% --- Look for an object that has already been observed
		for iObject = 1:nb_objects
			theta_o = getObject(obj.htm, iObject, 'theta');
			theta_o = theta_o(end);
			% theta_diff_a = abs(theta_o - theta_a);
			theta_diff_a = theta_o - theta_a;
			if theta_diff_a <= obj.thr_theta  && theta_diff_a >= -obj.thr_theta %&& obj.htm.sources(obj.htm.iStep) ~= 0
				putative_audio_object(end+1) = iObject;
			end
		end

		if isempty(putative_audio_object) % --- Create a new object
			hyp = [1, 0, nb_objects+1];
		else % --- Update already existing object
			hyp = [0, 1, putative_audio_object(1)];
			
		end
	end
	obj.setHypotheses(hyp);
end

function setHypotheses (obj, hyp)
	obj.create_new = hyp(1);
	obj.update_object = hyp(2);
	obj.id_object = hyp(3);
end

function plotDecisions (obj)
	figure;
	hold all;
	line(1:getInfo('nb_steps'), obj.create_new, 'Marker', '*', 'LineStyle', 'none', 'Color', 'r', 'MarkerSize', 16);
	line(1:getInfo('nb_steps'), obj.update_object, 'Marker', 'o', 'LineStyle', 'none', 'MarkerSize', 16);
	plot(1:getInfo('nb_steps'), obj.id_object, 'LineWidth', 2, 'LineStyle', '-');
	legend({'Create', 'Update', 'ID'}, 'FontSize', 12);
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end