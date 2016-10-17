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
    labels = {};
    nb_classes = 0;
    observed_categories = cell(0);
    hyper_categories = cell(0);
    htm;
    RIR;					% RobotInternalRepresentation class -> The representation the robot has of itself
    MFI;					% MultimodalFusion&Inference class 
    MSOM;					% MultimodalSelfOrganizingMap class
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
	obj.RIR = RIR;
	obj.htm = RIR.htm;
	obj.MFI = RIR.MFI;
	obj.MSOM = RIR.MSOM;

	% --- Initialize categories
	obj.observed_categories{1} = getInfo('obs_struct');
end
% === Constructor [END] === %

% --- Other methods --- %
function addObject (obj)
	% --- Create a new PERCEIVEDOBJECT object
    obj.objects{end+1} = PerceivedObject(obj.RIR.data(:, end),...
    									 obj.RIR.theta_hist(end));
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

% function updateLabel (obj, data)
% 	% obj.noveltyDetection(data) ;
% 	obj.objects{end}.addData(data) ;
% 	obj.addInput();
% end

function updateObjectData (obj)
	iObj = obj.htm.ODKS.id_object(end);
	% theta = abs(obj.RIR.head_position - theta);
	data = obj.RIR.data(:, end);
	theta = obj.RIR.theta_hist(end);
	obj.objects{iObj}.updateData(data, theta);
	obj.objects{iObj}.updateTime(obj.htm.iStep);
	obj.objects{iObj}.presence = true;
	obj.addInput();
end

% function noveltyDetection (obj, data)
% 	if isempty(obj.preclasses)
% 		obj.preclasses{1} = data ;
% 		return ;
% 	end
% 	for iPreclass = 1:numel(obj.preclasses)
% 		x = corr(obj.preclasses{iPreclass}, data) ;
% 		NEW_CLASS = true ;
% 		if x > 0.8
% 			obj.preclasses{iPreclass} = mean([obj.preclasses{iPreclass}, data]) ;
% 			NEW_CLASS = false ;
% 		end
% 	end
% 	obj.TRIGGER_LEARNING = false ;
% 	if NEW_CLASS
% 		obj.preclasses{end+1} = data ;
% 		obj.TRIGGER_LEARNING = true ;
% 	end
% end

% function trainMSOM (obj)
% 	obj.MFI.trainMSOM();
% end

%%set quality threshold
% function setQ (obj, qThreshold)
% 	obj.q = qThreshold ;
% end

function setClasses (obj)
	if isempty(obj.MFI.categories)
		obj.MFI.setCategories();
	end
	categories = obj.MFI.getCategories();
	for iClass = 1:numel(categories)
		% labels = obj.getCategories('label') ;
		search = find(strcmp(categories{iClass}, obj.labels));
		if isempty(search)
			obj.createNewCategory(categories{iClass});
		end			
	end
end

function createNewCategory (obj, label)
	obj.observed_categories{end+1} = getInfo('obs_struct');
	obj.observed_categories{end}.label = label;
	obj.labels = [obj.labels, label];
end

function checkInference (obj)
	labels = obj.labels ;
	for iObj = obj.present_objects
		% --- If an inference has been requested
		if obj.objects{iObj}.requests.inference
			% --- If visual data is still not available
			if obj.objects{iObj}.requests.missing
				% --- If a CHECK has been requested (-> motor order)
				if obj.objects{iObj}.requests.check
					% --- Continue to turn the head to the object
				% --- If a CHECK has not been yet requested -> trigger the motor order
				else
					% --- Simulate an AV inference
                    data = retrieveObservedData(obj, iObj, 'best');
					AVClass = obj.MFI.inferCategory(data);
					search = find(strcmp(AVClass, labels));
					% --- If the category has been correctly inferred in the past
					% --- CHECK is not needed -> we trust the inference
					if obj.isPerformant(search)
						if numel(obj.objects{iObj}.tmIdx) >= 1
							obj.objects{iObj}.requests.check = false;
							obj.objects{iObj}.requests.verification = false;
							obj.objects{iObj}.setLabel(AVClass);
							obj.objects{iObj}.cat = search;
						end
					% --- If the category has not been well infered in the past
					% --- CHECK is needed -> we don't trust the inference
					else
						% --- Request a CHECK of infered AV vs observed AV
						obj.objects{iObj}.requests.check = true;
						obj.objects{iObj}.requests.label = AVClass;
						obj.observed_categories{search}.nb_inf = obj.observed_categories{search}.nb_inf + 1;
					end
				end
			end
		% --- If no inference requested (AV data available)
		% --- But a verification is requested
		% --- ADD A VERIFICATION WITH NO CHECK in order to verify the inference in the case we have AV thanks to DWmod
		elseif obj.objects{iObj}.requests.verification
			% --- We now have the full AV data
            data = retrieveObservedData(obj, iObj, 'best');
			AVClass = obj.MFI.inferCategory(data);
			search = find(strcmp(AVClass, labels));
			% --- If infered AV is the same as observed AV
			if strcmp(AVClass, obj.objects{iObj}.requests.label)
				obj.objects{iObj}.requests.verification = false;
				obj.objects{iObj}.requests.check = false;

				obj.observed_categories{search}.nb_goodInf = obj.observed_categories{search}.nb_goodInf+1;

				obj.objects{iObj}.setLabel(AVClass);
				obj.objects{iObj}.cat = search;
			% --- If infered AV is NOT the same as observed AV
			else
				% --- Make the network learn with n more iterations
				obj.highTrainingPhase();
			end
		% Else if all data available
		elseif ~obj.objects{iObj}.requests.missing
			% --- Infer AV class
            data = retrieveObservedData(obj, iObj, 'best');
			AVClass = obj.MFI.inferCategory(data);
			search = find(strcmp(AVClass, labels));

			obj.objects{iObj}.setLabel(AVClass);
			obj.objects{iObj}.cat = search;
			obj.objects{iObj}.requests.check = false;
		end
	end
end

function checkConnectivity (obj, input_vector, inferred_label)
	[data, value] = obj.MFI.checkMissingModality(input_vector);

	switch value
	case 0    % ---------------------------- no data
		AVCategory = 'none_none';
	   	return;
	case 3    % ---------------------------- full data
		% bmu = obj.MSOM.getCombinedBMU(data);
		return;
		na = getInfo('nb_audio_labels');
		% --- Euclidian distance
		audio_distance = obj.MSOM.euclidianDistance(data(1:na), 1);
		visual_distance = obj.MSOM.euclidianDistance(data(na+1:end), 2);
		d = audio_distance.*visual_distance;
    case 1 % ---------------------------- vision missing
        % bmu = obj.MSOM.getBMU(data, value);
        % vector = input_vector(1:getInfo('nb_audio_labels'));
        d = obj.MSOM.euclidianDistance(data, value);
    case 2 % ---------------------------- audio missing
        % vector = input_vector(getInfo('nb_audio_labels')+1:end);
        d = obj.MSOM.euclidianDistance(data, value);
	end

	nodes = obj.processDistances(d);
	labels = obj.getLabels(nodes);
	labels_idx = obj.processLabels(labels, value, inferred_label);

	c = cell(0);
	for iLabel = labels_idx
		tmp = [labels{iLabel}{2}, '_', labels{iLabel}{1}];
		BOOL = true;
		for ii = 1:numel(c)
			if strcmp(c{ii}, tmp)
				BOOL = false;
			end
		end
		if BOOL
			c{end+1} = tmp;
		end
	end

	if ~isempty(c)
		obj.createHyperCategory(inferred_label, c);
	end

end

function createHyperCategory (obj, inferred_label, c)
	new_hyper_cat = sort([obj.labels{inferred_label}, c]);
	if isempty(obj.hyper_categories)
		obj.hyper_categories{end+1} = new_hyper_cat;
	else
		iCat = 1;
		while iCat <= numel(obj.hyper_categories)
			inter = intersect(obj.hyper_categories{iCat}, new_hyper_cat);
            %disp(new_hyper_cat);
			if isempty(inter)
				obj.hyper_categories{end+1} = new_hyper_cat;
			else
				new_hyper_cat = [obj.hyper_categories{iCat}, new_hyper_cat];
				obj.hyper_categories{iCat} = unique(new_hyper_cat);
			end
			iCat = iCat+1;
		end
	end
end

function nodes = processDistances (obj, d)
	m = mean(d);
	s = std(d);
	thr = m - 1*s;
	nodes = find(d <= thr);
end

function labels = getLabels (obj, nodes)
	audio_labels = getInfo('audio_labels');
	visual_labels = getInfo('visual_labels');
	labels = cell(numel(nodes), 1);
	for iNode = 1:numel(nodes)
		[a, v] = obj.MFI.findLabels(nodes(iNode));
		% labels{iNode} = mergeLabels(v, a);
		labels{iNode} = {audio_labels{a}, visual_labels{v}};
    end
    iLabel = 1;
    while iLabel <= numel(labels)
        iLabel2 = iLabel+1;
        while iLabel2 <= numel(labels)
            if sum(strcmp(labels{iLabel}, labels{iLabel2})) == 2
                labels(iLabel2) = [];
            else
                iLabel2 = iLabel2+1;
            end
        end
        iLabel = iLabel+1;
    end
end

function tmp2 = processLabels (obj, labels, modality, inferred_label)
	%[v, a] = unmergeLabels(inferred_label);
%     [a, v] = obj.MFI.findLabels(inferred_label);
%     info = getInfo('audio_labels', 'visual_labels');
%     v = info.visual_labels{v};
%     a = info.audio_labels{a};
    inferred_label = obj.labels{inferred_label};
    [v, a] = unmergeLabels(inferred_label);
	if modality == 1
		c = a;
		d = v;
		other_modality = 2;
	else
		c = v;
		d = a;
		other_modality = 1;
	end
	
	tmp = [];
	for iLabel = 1:numel(labels)
		if strcmp(labels{iLabel}{modality}, c)
			tmp(end+1) = iLabel;
		end
	end

	tmp2 = [];
	for iLabel = tmp
		if ~strcmp(labels{iLabel}{other_modality}, d)
			tmp2(end+1) = iLabel;
		end
	end
end

function highTrainingPhase (obj)
% 	% --- Change the number of iterations of the MSOM
% 	obj.MFI.MSOM.setParameters(10) ;
% 	% --- Train again the MSOM with last data
% 	obj.MFI.trainMSOM() ;
% 	obj.MFI.MSOM.setParameters(1) ;
end

function bool = isPerformant (obj, idx)
	perf = cell2mat(getCategory(obj, idx, 'perf'));
	if perf >= getInfo('q') && perf < 1
	% if obj.observed_categories{idx}.perf >= getInfo('q') && obj.observed_categories{idx}.perf < 1
		bool = true;
		% if obj.observed_categories{idx}.perf == 1 && obj.observed_categories{idx}.nb_inf < 7
		% 	bool = false;
		% end
	else
		bool = false;
	end
end


function computeCategoryPerformance (obj)
	for iClass = 1:numel(obj.observed_categories)
		obj.observed_categories{iClass}.perf = obj.observed_categories{iClass}.nb_goodInf/...
											   obj.observed_categories{iClass}.nb_inf;

		if isnan(obj.observed_categories{iClass}.perf) || isinf(obj.observed_categories{iClass}.perf)
			obj.observed_categories{iClass}.perf = 0;
		end

		obj.observed_categories{iClass}.proba = obj.observed_categories{iClass}.cpt/numel(obj.objects);

		if isnan(obj.observed_categories{iClass}.proba) || isinf(obj.observed_categories{iClass}.proba)
			obj.observed_categories{iClass}.proba = 0;
		end
	end
end

% function computeCategoryProba (obj)
% 	for iClass = 1:numel(obj.observed_categories)
% 		obj.observed_categories{iClass}.proba = obj.observed_categories{iClass}.cpt/numel(obj.objects) ;

% 		if isnan(obj.observed_categories{iClass}.proba) || isinf(obj.observed_categories{iClass}.proba)
% 			obj.observed_categories{iClass}.proba = 0 ;
% 		end
% 	end
% end


function reinitializeClasses (obj)
	for iClass = 1:numel(obj.observed_categories)
		obj.observed_categories{iClass}.cpt = 0;
	end
end

function categorizeObjects (obj)

	obj.reinitializeClasses() ;
	for iObj = 1:numel(obj.objects)
		if obj.objects{iObj}.cat > 0
			obj.observed_categories{obj.objects{iObj}.cat}.cpt = obj.observed_categories{obj.objects{iObj}.cat}.cpt + 1 ;
		else
			obj.observed_categories{1}.cpt = obj.observed_categories{1}.cpt + 1 ;
		end
	end

	cpts = cell2mat(arrayfun(@(x) obj.observed_categories{x}.cpt > 0,...
							 1:numel(obj.observed_categories),...
							 'UniformOutput', false)) ;
	obj.nb_classes = sum(cpts) ;

end

function countObjects (obj)
	for iObj = 1:numel(obj.objects)
		if iObj ~= obj.present_objects
            data = retrieveObservedData(obj, iObj, 'best');
			AVClass = obj.MFI.inferCategory(data) ;
			obj.objects{iObj}.setLabel(AVClass) ;
			search = find(strcmp(AVClass, obj.labels)) ;
			obj.objects{iObj}.cat = search ;
		end
	end
end

function computePresence (obj)
	obj.present_objects = [] ;
	for iObj = 1:obj.RIR.nb_objects
		if obj.objects{iObj}.presence
			obj.present_objects(end+1) = iObj;
		end
	end
end

function computeWeights (obj)
	% for iObj = 1:numel(obj.objects)
	for iObj = obj.present_objects
		obj_cat = obj.objects{iObj}.cat;
		if obj_cat ~= 0
		% --- Compute weights thanks to weighting functions
			% --- Incongruent
			if obj.observed_categories{obj_cat}.proba <= 1/obj.nb_classes
				increaseObjectWeight(obj.objects{iObj});
			% --- Congruent
			else
				decreaseObjectWeight(obj.objects{iObj});
			end
			obj.observed_categories{obj_cat}.congruence = obj.objects{iObj}.weight;
		end
	end
end

function cpt = getCounter (obj)
	cpt = obj.counter ;
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
		request = arrayfun(@(x) obj.observed_categories{x}.(field), idx);
	end
end


function updateObjects (obj, tmIdx)
	
	% if obj.htm.current_object ~= 0
	% 	obj.objects{obj.htm.current_object}.updateTime(tmIdx);
	% end
	% obj.objects{end}.updateTime(tmIdx);
	obj.computePresence();

	% obj.labels = arrayfun(@(x) obj.observed_categories{x}.label,...
	% 				  	  1:numel(obj.observed_categories),...
	% 				  	  'UniformOutput', false);
	obj.labels = getCategory(obj, 'all', 'label');

	obj.setClasses();

	obj.checkInference();

	obj.categorizeObjects();

	obj.countObjects();

	obj.computeCategoryPerformance();

	% obj.computeCategoryProba() ;

	obj.computeWeights();
	
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