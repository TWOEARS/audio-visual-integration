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
    objects 		= cell(0); % all detected objects 
    % labels = {};
    % nb_classes = 0;
    % observed_categories = cell(0);
    % hyper_categories = cell(0);
    htm;
    RIR;					% --- Robot Internal Representation
    MFI;					% --- Multimodal Fusion & Inference module
    MSOM;					% --- Multimodal Self Organizing Map
    DW;						% --- Dynamic Weighting module
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
	obj.DW   = obj.htm.DW; % --- Dynamic Weighting module
	% --- Initialize categories
	%obj.observed_categories{1} = getInfo('obs_struct');
end
% === Constructor [END] === %

% --- Other methods --- %
function addObject (obj)
	% --- Create a new PERCEIVEDOBJECT object
    obj.objects{end+1} = PerceivedObject(obj.RIR.data(:, end),...
    									 obj.RIR.theta_hist(end),...
    									 obj.RIR.theta_v_hist(end));
    % obj.objects{end}.updateTime(obj.htm.iStep);
                                    %obj.RIR.dist_hist(end)  ...
	obj.objects{end}.updateTime(obj.htm.iStep);
    obj.addInput();
end

function addInput (obj)
	iObj = obj.htm.ODKS.id_object(end);
	% --- No data missing
	if ~obj.objects{iObj}.requests.missing
		% --- Train nets
        data = retrieveObservedData(obj, iObj, 'best');
		obj.MFI.newInput(data);
	end
end

function updateObjectData (obj)
	iObj = obj.htm.ODKS.id_object(end);
	% theta = abs(obj.RIR.head_position - theta);
	data = obj.RIR.data(:, end);
	theta = obj.RIR.theta_hist(end);
	theta_v = obj.RIR.theta_v_hist(end);
	obj.objects{iObj}.updateData(data, theta, theta_v);
	obj.objects{iObj}.updateTime(obj.htm.iStep);
	obj.objects{iObj}.presence = true;
	obj.addInput();
end

% function setClasses (obj)
% 	if isempty(obj.MFI.categories)
% 		obj.MFI.setCategories();
% 	end
% 	categories = obj.MFI.getCategories();
% 	for iClass = 1:numel(categories)
% 		% labels = obj.getCategories('label') ;
% 		search = find(strcmp(categories{iClass}, obj.labels));
% 		if isempty(search)
% 			obj.createNewCategory(categories{iClass});
% 		end			
% 	end
% end

% function createNewCategory (obj, label)
% 	obj.observed_categories{end+1} = getInfo('obs_struct');
% 	obj.observed_categories{end}.label = label;
% 	obj.labels = [obj.labels, label];
% end

function checkInference (obj)
	for iObj = obj.present_objects
		[inference, missing, check, verification, label] = obj.getObjectRequests(iObj);
		if inference && missing % --- If an inference has been requested & data is missing
			if check % --- If a CHECK has been requested (-> motor order)
				% --- Continue to turn the head to the object
			else % --- If a CHECK has not been yet requested: trigger a motor order?
				[AVClass, search] = obj.simulateAVInference(iObj);
				if isPerformant(obj, search) % --- If the category has been correctly inferred in the past: CHECK not needed
					obj.preventVerification(iObj, search, AVClass);
				else % --- If the cat. hasn't been well infered in the past -> CHECK needed
					obj.requestVerification(iObj, AVClass);
					obj.DW.updateInferenceCpt(search);
				end
			end
		% --- If no inference requested (AV data available) but a verification is requested
		% --- ADD A VERIFICATION WITH NO CHECK in order to verify the inference in the case we have AV thanks to DWmod
		elseif verification
			[AVClass, search] = obj.simulateAVInference(iObj);
			if strcmp(AVClass, label) % --- If inferred AV is the same as observed AV
				obj.preventVerification(iObj, search, AVClass);
				obj.DW.updateGoodInferenceCpt(search);
			else % --- If infered AV is NOT the same as observed AV
				% --- Make the network learn with n more iterations
				obj.highTrainingPhase();
				% obj.objects{iObj}.requests.verification = true;
			end
		elseif ~missing % All data available
			[AVClass, search] = obj.simulateAVInference(iObj);
			obj.objects{iObj}.setLabel(AVClass, search);
			% obj.objects{iObj}.audiovisual_category = search;
			obj.objects{iObj}.requests.check = false;
		end
	end
end

% function updateGoodInferenceCpt (obj, search)
% 	obj.observed_categories{search}.nb_goodInf = obj.observed_categories{search}.nb_goodInf+1;
% end

% function updateInferenceCpt (obj, search)
% 	obj.observed_categories{search}.nb_inf = obj.observed_categories{search}.nb_inf + 1;
% end

% === Request a CHECK of infered AV vs observed AV
function requestVerification (obj, iObj, AVClass)
	obj.objects{iObj}.requests.check = true;
	obj.objects{iObj}.requests.label = AVClass;
end

function preventVerification (obj, iObj, search, AVClass)
	if numel(obj.objects{iObj}.tmIdx) > 0
		obj.objects{iObj}.requests.check = false;
		obj.objects{iObj}.requests.verification = false;
		obj.objects{iObj}.requests.inference = false;
		obj.objects{iObj}.setLabel(AVClass, search);
		% obj.objects{iObj}.audiovisual_category = search;
	end
end

function [AVClass, search] = simulateAVInference (obj, iObj)
    data = retrieveObservedData(obj, iObj, 'best');
	AVClass = obj.MFI.inferCategory(data);
	search = find(strcmp(AVClass, obj.DW.labels));
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
	obj.MFI.MSOM.setParameters(10);
	% --- Train again the MSOM with last data
	obj.MFI.trainMSOM();
	obj.MFI.MSOM.setParameters(1);
end

% === Compute the level of correct inferences by category
% function computeCategoryPerformance (obj)
% 	for iClass = 1:numel(obj.observed_categories)
% 		obj.observed_categories{iClass}.perf = obj.observed_categories{iClass}.nb_goodInf/...
% 											   obj.observed_categories{iClass}.nb_inf;

% 		if isnan(obj.observed_categories{iClass}.perf) || isinf(obj.observed_categories{iClass}.perf)
% 			obj.observed_categories{iClass}.perf = 0;
% 		end

% 		if isPerformant(obj.htm, iClass)
% 			obj.observed_categories{iClass}.proba = obj.observed_categories{iClass}.cpt/numel(obj.objects);

% 			if isnan(obj.observed_categories{iClass}.proba) || isinf(obj.observed_categories{iClass}.proba)
% 				obj.observed_categories{iClass}.proba = 0;
% 			end
% 		end
% 	end
% end

% function computeCategoryProba (obj)
% 	for iClass = 1:numel(obj.observed_categories)
% 		obj.observed_categories{iClass}.proba = obj.observed_categories{iClass}.cpt/numel(obj.objects) ;

% 		if isnan(obj.observed_categories{iClass}.proba) || isinf(obj.observed_categories{iClass}.proba)
% 			obj.observed_categories{iClass}.proba = 0 ;
% 		end
% 	end
% end


% function reinitializeClasses (obj)
% 	for iClass = 1:numel(obj.observed_categories)
% 		obj.observed_categories{iClass}.cpt = 0;
% 	end
% end

% function categorizeObjects (obj)

% 	obj.reinitializeClasses() ;
% 	for iObj = 1:obj.RIR.nb_objects
% 		c = getObject(obj, iObj, 'audiovisual_category');
% 		if c > 0
% 			obj.observed_categories{c}.cpt = obj.observed_categories{c}.cpt + 1;
% 		else
% 			obj.observed_categories{1}.cpt = obj.observed_categories{1}.cpt + 1;
% 		end
% 	end

% 	cpts = cell2mat(arrayfun(@(x) obj.observed_categories{x}.cpt > 0,...
% 							 1:numel(obj.observed_categories),...
% 							 'UniformOutput', false));
% 	obj.nb_classes = sum(cpts);
% end

% function countObjects (obj)
% 	for iObj = 1:numel(obj.objects)
% 		if iObj ~= obj.present_objects
% 			[AVClass, search] = obj.simulateAVInference(iObj);
%             obj.objects{iObj}.audiovisual_category = search;
% 		end
% 	end
% end

function computePresence (obj)
	obj.present_objects = find(getObject(obj, 'all', 'presence'));
	if isempty(obj.present_objects)
		obj.present_objects = [];
	end
end

% function computeWeights (obj)
% 	% for iObj = 1:numel(obj.objects)
% 	for iObj = obj.present_objects
% 		obj_cat = obj.objects{iObj}.audiovisual_category;
% 		if obj_cat ~= 0
% 			if ~isPerformant(obj.htm, obj_cat)
% 				% obj.observed_categories{obj_cat}.congruence = 0;
% 			else
% 			% --- Compute weights thanks to weighting functions
% 				% --- Incongruent
% 				if obj.observed_categories{obj_cat}.proba <= 1/obj.nb_classes
% 					increaseObjectWeight(obj.htm, iObj);
% 				% --- Congruent
% 				else
% 					decreaseObjectWeight(obj.htm, iObj);
% 				end
% 				obj.observed_categories{obj_cat}.congruence = obj.objects{iObj}.weight;
% 			end
% 		end
% 	end
% end

% function cpt = getCounter (obj)
% 	cpt = obj.counter;
% end

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
	
	% obj.labels = getCategory(obj, 'all', 'label');

	obj.DW.setClasses();

	obj.checkInference();

	obj.DW.execute();

	% obj.categorizeObjects();

	% obj.countObjects();

	% obj.computeCategoryPerformance();

	% obj.computeWeights();
	
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