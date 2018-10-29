% 'DynamicWeighting' class
% This class is part of the HeadTurningModulationKS
% Author: Benjamin Cohen-Lhyver
% Date: 01.11.16
% Rev. 1.0

classdef DynamicWeighting < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
	observed_categories;
	nb_classes;
	classes;

    htm;
    MFI;

    nb_categories = 0;
    labels = {};
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = DynamicWeighting (htm)
	obj.htm = htm;
	obj.MFI = htm.MFI;
	obj.observed_categories = obj.MFI.observed_categories;
end
% === CONSTRUCTOR [END] === %

% === 'execute' function
function execute (obj)

	obj.computeAposterioriProbabilities();

	obj.MFI.computePerformance();

    obj.setClasses();
    
	obj.computeCongruence();

end

function setClasses (obj)
	obj.observed_categories = obj.MFI.observed_categories;
end

% function setClasses (obj)
% 	if isempty(obj.MFI.categories)
% 		obj.MFI.setCategories();
% 	end
% 	categories = obj.MFI.getCategories();
% 	for iClass = 1:numel(categories)
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

function computeAposterioriProbabilities (obj)
	obj.reinitializeClasses();
    if numel(obj.observed_categories) > 1
        av_cats = getObject(obj, 'all', 'audiovisual_category');
        classes = unique(av_cats);
        [~, nb_objects] = obj.computeNbObjects();
        for iCat = classes'
            if iCat ~= 1 && ~isempty(iCat) && isPerformant(obj, iCat)
                % obj.observed_categories{iCat}.cpt = sum(av_cats == iCat);
                obj.MFI.observed_categories{iCat}.cpt = sum(av_cats == iCat);
                % obj.observed_categories{iCat}.proba = obj.observed_categories{iCat}.cpt/obj.htm.RIR.nb_objects;
                obj.MFI.observed_categories{iCat}.proba = obj.MFI.observed_categories{iCat}.cpt/nb_objects;
            end
        end
        obj.nb_classes = numel(classes(classes > 1));
        obj.classes = classes;
    end
end

function [objects, nb_objects] = computeNbObjects (obj)
	nb_objects = 0;
	objects = [];
	for iObject = 1:getEnvironment(obj, 0, 'nb_objects')
		if getObject(obj, iObject, 'audiovisual_category') ~= 1
			nb_objects = nb_objects + 1;
			objects(end+1) = iObject;
		end
	end
end


% function computePerformance (obj)
% 	av_cats = getObject(obj.htm, 'all', 'audiovisual_category');
% 	classes = unique(av_cats);
% 	for iCat = classes'
% 		% if isPerformant(obj, iCat)
% 			obj.observed_categories{iCat}.perf = obj.observed_categories{iCat}.nb_goodInf/obj.observed_categories{iCat}.nb_inf;
% 			if isnan(obj.observed_categories{iCat}.perf) || isinf(obj.observed_categories{iCat}.perf)
% 				obj.observed_categories{iCat}.perf = 0;
% 			end
% 		% end
% 	end
% end

function reinitializeClasses (obj)
    if numel(obj.observed_categories) == 1
        obj.setClasses();
    end
	for iClass = 1:numel(obj.observed_categories)
		obj.observed_categories{iClass}.cpt = 0;
	end
end

function computeCongruence (obj)
	obj.setClasses();
	for iCat = obj.classes'
		if iCat ~= 1
			if isPerformant(obj, iCat)
				if obj.observed_categories{iCat}.proba <= 1/obj.nb_classes
					obj.MFI.observed_categories{iCat}.congruence = -1;
				else
					obj.MFI.observed_categories{iCat}.congruence = 1;
				end
			end
		end
	end
end

function computeWeights (obj)
	env = getEnvironment(obj.htm, 0);
	% for iObj = 1:numel(env.present_objects)
		% iObj = env.present_objects(iObj);
	[objects, ~] = obj.computeNbObjects();
	for iObj = objects
		% obj_label = getObject(obj.htm, iObj, 'label');
		% obj_cat = find(strcmp(obj_label, obj.labels));
		obj_cat = getObject(obj, iObj, 'audiovisual_category');
		if obj_cat > numel(obj.observed_categories)
			obj.setClasses();
		end
		if obj_cat ~= 0
			% === TEMPORAIRE [beg] === %
			% if ~isPerformant(obj.htm, obj_cat)
			if obj_cat == 0
			% === TEMPORAIRE [end] === %
				% obj.observed_categories{obj_cat}.congruence = 0;
			else
			% --- Compute weights thanks to weighting functions
				% --- Incongruent
				% if obj.observed_categories{obj_cat}.proba <= 1/obj.nb_classes
				% obj.observed_categories{obj_cat}
				if obj.observed_categories{obj_cat}.congruence == -1
					increaseObjectWeight(obj.htm, iObj);
				% --- Congruent
				elseif obj.observed_categories{obj_cat}.congruence == 1
					decreaseObjectWeight(obj.htm, iObj);
				end
				% obj.observed_categories{obj_cat}.congruence = obj.objects{iObj}.weight;
			end
		end
	end
end


% function computeCategoryPerformance (obj)
% 	env = getEnvironment(obj.htm, 0);
% 	nb_objects = numel(env.objects);
% 	for iClass = 1:numel(obj.observed_categories)
% 		obj.observed_categories{iClass}.perf = obj.observed_categories{iClass}.nb_goodInf/...
% 											   obj.observed_categories{iClass}.nb_inf;

% 		if isnan(obj.observed_categories{iClass}.perf) || isinf(obj.observed_categories{iClass}.perf)
% 			obj.observed_categories{iClass}.perf = 0;
% 		end

% 		if isPerformant(obj.htm, iClass)
% 			obj.observed_categories{iClass}.proba = obj.observed_categories{iClass}.cpt/nb_objects;

% 			if isnan(obj.observed_categories{iClass}.proba) || isinf(obj.observed_categories{iClass}.proba)
% 				obj.observed_categories{iClass}.proba = 0;
% 			end
% 		end
% 	end
% end

% function updateGoodInferenceCpt (obj, search)
% 	obj.observed_categories{search}.nb_goodInf = obj.observed_categories{search}.nb_goodInf + 1;
% end

% function updateInferenceCpt (obj, search)
% 	obj.observed_categories{search}.nb_inf = obj.observed_categories{search}.nb_inf + 1;
% end

% function checkConnectivity (obj, input_vector, inferred_label)
% 	[data, value] = obj.MFI.checkMissingModality(input_vector);

% 	switch value
% 	case 0    % ---------------------------- no data
% 		AVCategory = 'none_none';
% 	   	return;
% 	case 3    % ---------------------------- full data
% 		% bmu = obj.MSOM.getCombinedBMU(data);
% 		return;
% 		na = getInfo('nb_audio_labels');
% 		% --- Euclidian distance
% 		audio_distance = obj.MSOM.euclidianDistance(data(1:na), 1);
% 		visual_distance = obj.MSOM.euclidianDistance(data(na+1:end), 2);
% 		d = audio_distance.*visual_distance;
%     case 1 % ---------------------------- vision missing
%         % bmu = obj.MSOM.getBMU(data, value);
%         % vector = input_vector(1:getInfo('nb_audio_labels'));
%         d = obj.MSOM.euclidianDistance(data, value);
%     case 2 % ---------------------------- audio missing
%         % vector = input_vector(getInfo('nb_audio_labels')+1:end);
%         d = obj.MSOM.euclidianDistance(data, value);
% 	end

% 	nodes = obj.processDistances(d);
% 	labels = obj.getLabels(nodes);
% 	labels_idx = obj.processLabels(labels, value, inferred_label);

% 	c = cell(0);
% 	for iLabel = labels_idx
% 		tmp = [labels{iLabel}{2}, '_', labels{iLabel}{1}];
% 		BOOL = true;
% 		for ii = 1:numel(c)
% 			if strcmp(c{ii}, tmp)
% 				BOOL = false;
% 			end
% 		end
% 		if BOOL
% 			c{end+1} = tmp;
% 		end
% 	end

% 	if ~isempty(c)
% 		obj.createHyperCategory(inferred_label, c);
% 	end

% end

% function createHyperCategory (obj, inferred_label, c)
% 	new_hyper_cat = sort([obj.labels{inferred_label}, c]);
% 	if isempty(obj.hyper_categories)
% 		obj.hyper_categories{end+1} = new_hyper_cat;
% 	else
% 		iCat = 1;
% 		while iCat <= numel(obj.hyper_categories)
% 			inter = intersect(obj.hyper_categories{iCat}, new_hyper_cat);
%             %disp(new_hyper_cat);
% 			if isempty(inter)
% 				obj.hyper_categories{end+1} = new_hyper_cat;
% 			else
% 				new_hyper_cat = [obj.hyper_categories{iCat}, new_hyper_cat];
% 				obj.hyper_categories{iCat} = unique(new_hyper_cat);
% 			end
% 			iCat = iCat+1;
% 		end
% 	end
% end

% function nodes = processDistances (obj, d)
% 	m = mean(d);
% 	s = std(d);
% 	thr = m - 1*s;
% 	nodes = find(d <= thr);
% end

% function labels = getLabels (obj, nodes)
% 	audio_labels = getInfo('audio_labels');
% 	visual_labels = getInfo('visual_labels');
% 	labels = cell(numel(nodes), 1);
% 	for iNode = 1:numel(nodes)
% 		[a, v] = obj.MFI.findLabels(nodes(iNode));
% 		% labels{iNode} = mergeLabels(v, a);
% 		labels{iNode} = {audio_labels{a}, visual_labels{v}};
%     end
%     iLabel = 1;
%     while iLabel <= numel(labels)
%         iLabel2 = iLabel+1;
%         while iLabel2 <= numel(labels)
%             if sum(strcmp(labels{iLabel}, labels{iLabel2})) == 2
%                 labels(iLabel2) = [];
%             else
%                 iLabel2 = iLabel2+1;
%             end
%         end
%         iLabel = iLabel+1;
%     end
% end

% function tmp2 = processLabels (obj, labels, modality, inferred_label)
% 	%[v, a] = unmergeLabels(inferred_label);
% %     [a, v] = obj.MFI.findLabels(inferred_label);
% %     info = getInfo('audio_labels', 'visual_labels');
% %     v = info.visual_labels{v};
% %     a = info.audio_labels{a};
%     inferred_label = obj.labels{inferred_label};
%     [v, a] = unmergeLabels(inferred_label);
% 	if modality == 1
% 		c = a;
% 		d = v;
% 		other_modality = 2;
% 	else
% 		c = v;
% 		d = a;
% 		other_modality = 1;
% 	end
	
% 	tmp = [];
% 	for iLabel = 1:numel(labels)
% 		if strcmp(labels{iLabel}{modality}, c)
% 			tmp(end+1) = iLabel;
% 		end
% 	end

% 	tmp2 = [];
% 	for iLabel = tmp
% 		if ~strcmp(labels{iLabel}{other_modality}, d)
% 			tmp2(end+1) = iLabel;
% 		end
% 	end
% end


end
% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %