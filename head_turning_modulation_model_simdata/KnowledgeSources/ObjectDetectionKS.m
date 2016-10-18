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
	
	% MOKS; % Motor_Order KS
	
	ALKS; % Audio_Localization KS
	VLKS; % Visual_Localization KS
	ACKS; % Audio_Classification_Experts KS
	VCKS; % Visual_Classification_Experts KS

	% decision = [];

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
	obj.ALKS = htm.ALKS;
	obj.VLKS = htm.VLKS;
	obj.ACKS = htm.ACKS;
	obj.VCKS = htm.VCKS;
	obj.thr_theta = getInfo('thr_theta');
end
% === CONSTRUCTOR [END] === %

% function [create_new, do_nothing] = simulationStatus (obj, iStep)
function execute (obj)

	obj.getLocalization();

	theta_a = obj.ALKS.hyp_hist(end);
	if theta_a == -1
		% obj.decision(:, end+1) = [0 ; 0];
		obj.create_new(end+1) = 0;
		obj.update_object(end+1) = 0;
		obj.id_object(end+1) = 0;
		return;
	end

	putative_audio_object = [];

	nb_objects = obj.RIR.nb_objects;

	if numel(obj.update_object) > 2
		if obj.update_object(end-1) == 0 && obj.update_object(end) == 1

		end
	end

	% --- Look for an object that has already been observed
	for iObject = 1:nb_objects
		theta_o = getObject(obj.htm, iObject, 'theta');
		% theta_diff_a = abs(theta_o - theta_a);
		theta_diff_a = theta_o - theta_a;

		% --- If the robot is facing an object that has already been observed -> merge the data
		if theta_diff_a <= obj.thr_theta  && theta_diff_a >= -obj.thr_theta %&& obj.htm.sources(obj.htm.iStep) ~= 0
		% if theta_a <= obj.thr_theta %&& obj.htm.sources(obj.htm.iStep) ~= 0
			% putative_audio_object(end+1, :) = [iObject, theta_o];
			putative_audio_object(end+1) = iObject;
			% --- If there is more than one object that could be at the same place
			% if size(putative_audio_object, 1) > 1
			% 	previous_theta = getObject(obj.htm, putative_audio_object(1), 'theta');
			% 	[tmp, pos] = min(putative_audio_object(:, 2));
			% 	if pos == 2
			% 		putative_audio_object = putative_audio_object(pos, :);
			% 	end
			% end
		end
	end

	if isempty(putative_audio_object)
		% --- Create a new object
		obj.create_new(end+1) = 1;
		obj.update_object(end+1) = 0;
		obj.id_object(end+1) = nb_objects+1;
		% hyp = [1 ; nb_objects+1]; 
	else
		obj.create_new(end+1) = 0;
		obj.update_object(end+1) = 1;
		obj.id_object(end+1) = putative_audio_object(1);
		% obj.RIR.getEnv().objects{obj.id_object(end)}.presence = true;
		% hyp = [2 ; putative_audio_object(1)]; % --- The object has already been observed
	end
	% obj.decision(:, end+1) = hyp;
end

function getLocalization (obj)
	obj.ALKS.execute();
	obj.VLKS.execute();
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