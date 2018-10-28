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
properties (SetAccess = public, GetAccess = public)
    present_objects = [] 	 ; % objects present in the environment
    objects = cell(0); % all detected objects
    htm;
    RIR;					% --- Robot Internal Representation
    MFI;					% --- Multimodal Fusion & Inference module
    MSOM;					% --- Multimodal Self Organizing Map
    DW;						% --- Dynamic Weighting module
    behavior = 0;
    classes = [];
    behavior_hist = [];
    nb_objects = 0;
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
	theta_a = getLocalisationOutput(obj.htm);
	theta_v = obj.htm.blackboard.getLastData('visualLocationHypotheses').data;
	theta_v = theta_v('theta');
	% data = getClassifiersOutput(obj.htm);
	data = getClassifiersOutput(obj.htm);

    obj.nb_objects = obj.nb_objects + 1;

	if all(data(getInfo('nb_audio_labels')+1:end) == 0)
		theta_v = -1;
	end

	% --- Create a new PERCEIVEDOBJECT object
    obj.objects{end+1} = PerceivedObject(data,...
    									 theta_a,...
    									 theta_v,...
    									 iSource);
	obj.objects{end}.updateTime(iStep);
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
			tt = find(strcmp(labels, obj.objects{iObject}.label));
			if ~isempty(tt)
				tmp(iObject) = tt;
			end
		end
		if all(tmp)
			similar_env = iEnv;
		end
	end
	if similar_env == 0
		obj.behavior = numel(obj.RIR.environments);
		obj.classes = obj.DW.classes;
	else
		obj.behavior = similar_env;
		obj.classes = obj.RIR.environments{obj.behavior}.DW.classes;
	end
	obj.behavior_hist(end+1) = obj.behavior;
end

function addInput (obj, iSource)
	hyp = obj.htm.blackboard.getLastData('objectDetectionHypotheses').data;
	iObj = hyp.id_object;
	requests = getObject(obj, iObj, 'requests');
	% --- No data missing
	if requests.missing == 0
		% --- Train nets
        data = retrieveObservedData(obj, iObj, 'best');
		obj.MFI.newInput(data, iObj);
	end
end

function updateObjectData (obj, iSource)
	hyp = obj.htm.blackboard.getLastData('objectDetectionHypotheses').data;
	iObj = hyp.id_object;

	data = getClassifiersOutput(obj.htm);

	theta_a = getLocalisationOutput(obj.htm);
	theta_v = obj.htm.blackboard.getLastData('visualLocationHypotheses').data;
	theta_v = theta_v('theta');
    

	obj.objects{iObj}.updateData(data,...
								 theta_a,...
								 theta_v);
	obj.objects{iObj}.updateTime(obj.htm.iStep);
	% obj.objects{iObj}.presence = true;

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
                if isPerformant(obj, search) % --- If the category has been correctly inferred in the past: CHECK not needed
					obj.preventVerification(iObj, search, AVClass);
                end
			else % --- If a CHECK has not been yet requested: trigger a motor order?
				[AVClass, search] = obj.simulateAVInference(iObj);
				% if ~strcmp(AVClass, 'none_none')
					if isPerformant(obj, search) % --- If the category has been correctly inferred in the past: CHECK not needed
						obj.preventVerification(iObj, search, AVClass);
					else % --- If the cat. hasn't been well infered in the past -> CHECK needed
						obj.requestVerification(iObj, AVClass);
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
				obj.MFI.updateGoodInferenceCpt(AVClass, search);
				obj.objects{iObj}.requests.checked = true;
			else % --- If infered AV is NOT the same as observed AV
                obj.objects{iObj}.requests.label = AVClass;
				% --- Make the network learn with n more iterations
				% obj.highTrainingPhase();
				% obj.objects{iObj}.requests.verification = true;
			end
		elseif ~missing % All data available
			[AVClass, search] = obj.simulateAVInference(iObj);
			obj.objects{iObj}.setLabel(AVClass, search);
			obj.objects{iObj}.requests.check = false;
			% obj.MFI.observed_categories{search}.perf = getInfo('q')+0.05;
			% disp(getCategory(obj, search))
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
		% obj.objects{iObj}.requests.checked = false;
		obj.objects{iObj}.setLabel(AVClass, search);
	end
end

function [AVClass, search] = simulateAVInference (obj, iObj)
    data = retrieveObservedData(obj, iObj, 'best');
	AVClass = obj.MFI.inferCategory(data);
	search = find(strcmp(AVClass, obj.MFI.labels));
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
	% obj.MFI.MSOM.setParameters(20);
	% % --- Train again the MSOM with last data
	% obj.MFI.trainMSOM();
	% obj.MFI.MSOM.setParameters(10);
end

function computePresence (obj)
	present_objects = find(getObject(obj, 'all', 'presence'));
	if isempty(present_objects)
		obj.present_objects = [];
	else
		for iObj = 1:numel(present_objects)
			tmIdx = getObject(obj, present_objects(iObj), 'tmIdx');
			if numel(tmIdx) < 2
				present_objects(iObj) = 0;
			end
		end
		present_objects(present_objects == 0) = [];
		if isempty(present_objects)
			present_objects = [];
		end
	end
	obj.present_objects = present_objects;
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


function updateEnvironment (obj, tmIdx)
	
	obj.computePresence();
	
	obj.MFI.setClasses();

	obj.checkInference();

	obj.DW.execute();

	dw = getEnvironment(obj.htm, obj.behavior, 'DW');
	dw.computeWeights();

	arrayfun(@(x) obj.objects{x}.updateObj(), obj.present_objects);
		
end
	
end
% ===================== %
% === METHODS [END] === %
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %