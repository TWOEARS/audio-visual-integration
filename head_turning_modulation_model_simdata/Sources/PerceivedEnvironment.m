% 'PerceivedEnvironment' class
% This class is part of the HeadTurningModulationKS
% It implements the Environment the robot is currently exploring.
% This class enables it to gather:
% 		1. the congruence distribution of the AV categories it has created
% 		2. the audiovisual objects it has already observed in it.
% Author: Benjamin Cohen-Lhyver
% Date: 01.02.16
% Rev. 2.0

classdef PerceivedEnvironment < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public,
	GetAccess = public)
    present_objects = []; 	% objects present in the environment
    objects = cell(0); 		% all detected objects 
    htm;
    RIR;					% --- Robot Internal Representation
    MFI;					% --- Multimodal Fusion & Inference module
    MSOM;					% --- Multimodal Self Organizing Map
    DW;						% --- Dynamic Weighting module
    behavior = 0;
    classes = [];
    behavior_hist = [];
    temp_dw;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === Constructor [BEG] === %
function obj = PerceivedEnvironment (RIR)
	obj.RIR  = RIR; 	   % --- Robot Internal Representation
	obj.htm  = RIR.htm;    % --- Head Turning Modulation
	obj.MFI  = RIR.MFI;    % --- Multimodal Fusion & Inference module
	obj.MSOM = RIR.MSOM;   % --- Multimodal SelfOrganizing Map
	obj.DW   = DynamicWeighting(RIR.htm); % --- Dynamic Weighting module
end
% === Constructor [END] === %

% --- Other methods --- %
function addObject (obj, iSource)
    iStep = obj.htm.iStep;
    theta = getLastHypothesis(obj, 'ALKS');
    theta = theta(iSource);
    theta_v = getLastHypothesis(obj, 'VLKS');
	% --- Create a new PERCEIVEDOBJECT object
    obj.objects{end+1} = PerceivedObject(obj.htm.data{iSource}(:, obj.htm.iStep),...
    									 theta,...
    									 theta_v,...
    									 iSource);
	obj.objects{end}.updateTime(obj.htm.iStep);
	obj.parseEnvironments();
    obj.addInput(iSource);
end

function parseEnvironments (obj)
	similar_env = 0;
	for iEnv = 1:numel(obj.RIR.environments)-1
		env = obj.RIR.environments{iEnv};
		classes_idx = env.DW.classes;
		labels = cell(numel(classes_idx), 1);
		for iClass = 1:numel(classes_idx)
			labels{iClass} = env.DW.observed_categories{classes_idx(iClass)}.label;
		end
		tmp = zeros(1, numel(obj.objects));
		for iObject = 1:numel(obj.objects)
            if strcmp(obj.objects{iObject}.label, 'none_none')
                tt = - 1;
            else
                tt = find(strcmp(labels, obj.objects{iObject}.label));
            end
			if ~isempty(tt)
				tmp(iObject) = tt;
			end
		end
		if all(tmp > 0)
			similar_env = iEnv;
        elseif ~isempty(find(tmp == -1))
            if isempty(obj.behavior_hist)
                similar_env = 0;
            else
                similar_env = obj.behavior_hist(end);
            end
		end
	end
	% similar_env
	if similar_env == 0
		obj.behavior = numel(obj.RIR.environments);
		obj.classes = obj.DW.classes;
	else
		obj.behavior = similar_env;
		obj.classes = obj.RIR.environments{obj.behavior}.DW.classes;
		if obj.behavior_hist(end) ~= obj.behavior
			obj.createTemporaryDW();
		end
	end
	obj.behavior_hist(end+1) = obj.behavior;
end

function createTemporaryDW (obj)
	env = getEnvironment(obj, obj.behavior);
	obj.temp_dw = DynamicWeighting(obj.htm, env.DW.source_env);
	dw = getEnvironment(obj.htm, obj.behavior, 'DW');
	% obj.temp_dw.observed_categories = dw.observed_categories;
	obj.temp_dw.classes = dw.classes;
	obj.temp_dw.nb_classes = dw.nb_classes;
	obj.temp_dw.execute();
end

function addInput (obj, iSource)
    iObj = getLastHypothesis(obj, 'ODKS', 'id_object');
    iObj = iObj(iSource);
	% --- No data missing
	if ~obj.objects{iObj}.requests.missing
		% --- Train nets
        data = retrieveObservedData(obj, iObj, 'best');
		obj.MFI.newInput(data, iObj);
	end
end

function updateObjectData (obj, iSource)
	iObj = getLastHypothesis(obj, 'ODKS', 'id_object');
    iObj = iObj(iSource);
    
    data = obj.htm.data{iSource}(:, obj.htm.iStep);
	
	theta = getLastHypothesis(obj, 'ALKS');
    theta = theta(iSource);
	
	theta_v = getLastHypothesis(obj, 'VLKS');
	
	obj.objects{iObj}.updateData(data, theta, theta_v);
	obj.objects{iObj}.updateTime(obj.htm.iStep);

	obj.parseEnvironments();
	
	obj.addInput(iSource);
end

function checkInference (obj)
	for iObj = obj.present_objects'
		[inference, missing, check, verification, label] = obj.getObjectRequests(iObj);
		if inference && missing % --- If an inference has been requested & data is missing
			if check % --- If a CHECK has been requested (-> motor order)
				     % --- Continue to turn the head to the object
				[AVClass, search] = obj.simulateAVInference(iObj);
				if isPerformant(obj, search)
					obj.preventVerification(iObj, search, AVClass);
				end
			else % --- If a CHECK has not been yet requested: trigger a motor order?
				[AVClass, search] = obj.simulateAVInference(iObj);
				% if ~strcmp(AVClass, 'none_none')
					if isPerformant(obj, search) % --- If the category has been correctly inferred in the past: CHECK not needed
						obj.preventVerification(iObj, search, AVClass);
					else % --- If the cat. hasn't been well infered in the past -> CHECK needed
						obj.requestVerification(iObj, AVClass);
						% obj.DW.updateInferenceCpt(AVClass, search);
						obj.MFI.updateInferenceCpt(AVClass, search);
					end
				% end
			end
		% --- If no inference requested (AV data available) but a verification is requested
		% --- ADD A VERIFICATION WITH NO CHECK in order to verify the inference in the case we have AV thanks to DWmod
		elseif verification
			[AVClass, search] = obj.simulateAVInference(iObj);
			if strcmp(AVClass, label) && ~strcmp(AVClass, 'none_none') % --- If inferred AV is the same as observed AV
				obj.preventVerification(iObj, search, AVClass);
				% obj.DW.updateGoodInferenceCpt(AVClass, search);
				obj.MFI.updateGoodInferenceCpt(AVClass, search);
				obj.objects{iObj}.requests.checked = true;
			else % --- If inferred AV is NOT the same as observed AV
                obj.objects{iObj}.requests.label = AVClass;
				% --- Make the network learn with n more iterations
				% obj.highTrainingPhase();
				% obj.objects{iObj}.requests.verification = true;
			end
		elseif ~missing % All data available
			[AVClass, search] = obj.simulateAVInference(iObj);
			obj.objects{iObj}.setLabel(AVClass, search);
			obj.objects{iObj}.requests.check = false;
		end
	end
end

% === Request a CHECK of infered AV vs observed AV
function requestVerification (obj, iObj, AVClass)
	obj.objects{iObj}.requests.check = true;
	obj.objects{iObj}.requests.verification = true;
	obj.objects{iObj}.requests.label = AVClass;
end

function preventVerification (obj, iObj, search, AVClass)
	if numel(obj.objects{iObj}.tmIdx) > 0
		obj.objects{iObj}.requests.check = false;
		obj.objects{iObj}.requests.verification = false;
		obj.objects{iObj}.requests.inference = false;
		obj.objects{iObj}.setLabel(AVClass, search);
	end
end

function [AVClass, search] = simulateAVInference (obj, iObj)
    if getInfo('modules') ~= 1
    	data = retrieveObservedData(obj, iObj, 'best');
		AVClass = obj.MFI.inferCategory(data);
		search = find(strcmp(AVClass, obj.MFI.labels));
	elseif getInfo('modules') == 1
        
		rep = getInfo('repartition');
		scenario = getInfo('scenario');
		avpairs = getInfo('AVPairs');
		avpairs = avpairs(scenario.scene{end});
		source = getObject(obj, iObj, 'source');

		for ii = 1:numel(rep)
			if find(rep{ii} == source)
				idx = ii;
			end
		end
		
		AVClass = avpairs{idx};
		AVClass = strjoin(AVClass, '_');

		search = find(strcmp(AVClass, obj.MFI.labels));
	end

	if isempty(search)
		obj.MFI.createNewCategory(AVClass);
		search = find(strcmp(AVClass, obj.MFI.labels));
	end
end

function [inference, missing, check, verification, label] = getObjectRequests(obj, iObj)
	requests = getObject(obj, iObj, 'requests');
	inference = requests.inference;
	missing = requests.missing;
	check = requests.check;
	verification = requests.verification;
	label = requests.label;
end

function highTrainingPhase (obj)
	% --- Change the number of iterations of the MSOM
	obj.MFI.MSOM.setParameters(20);
	% --- Train again the MSOM with last data
	obj.MFI.trainMSOM();
	obj.MFI.MSOM.setParameters(getInfo('nb_iterations'));
end

function computePresence (obj)
	obj.present_objects = find(getObject(obj, 'all', 'presence'));
	if isempty(obj.present_objects)
		obj.present_objects = [];
	end
end

function request = getCategories (obj, varargin)
	if nargin == 1
		request = obj.observed_categories;
	elseif nargin == 2
		if isstr(varargin{1})
			request = arrayfun(@(x) obj.observed_categories{x}.(varargin{1}),...
							   1:numel(obj.observed_categories),...
							   'UniformOutput', false);
		else
			request = arrayfun(@(x) obj.observed_categories{x}, varargin{1});
		end
	else
		if isstr(varargin{1})
			field = varargin{1};
			idx = varargin{2};
		else
			idx = varargin{1};
			field = varargin{2};
		end
		request = arrayfun(@(x) obj.observed_categories{x}.(field), idx, 'UniformOutput', false);
	end
end

function terminate (obj)
	if obj.behavior ~= numel(obj.RIR.environments)
		obj.DW = obj.temp_dw;
	end
	obj.DW.source_env(end+1) = numel(obj.RIR.environments);
	if obj.DW.source_env(1) == 0
		obj.DW.source_env = obj.DW.source_env(2:end);
	end
end


function updateEnvironment (obj, tmIdx)
	
	obj.computePresence();
	
	obj.MFI.setClasses();

	obj.checkInference();

	if obj.behavior == numel(obj.RIR.environments)
		obj.DW.execute();
		obj.DW.computeWeights();
	else
		obj.DW.execute();
		obj.temp_dw.execute();
		obj.temp_dw.computeWeights();
		% obj.DW.computeWeights();
	end

	arrayfun(@(x) obj.objects{x}.updateObj(), obj.present_objects');
		
end
	
end
% ===================== %
% === METHODS [END] === %
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %