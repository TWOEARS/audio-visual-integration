% 'MultimodalFusionAndInference' class
% This class is part of the HeadTurningModulationKS
% Author: Benjamin Cohen-Lhyver
% Date: 01.02.16
% Rev. 2.0

classdef MultimodalFusionAndInference < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    categories = {};
    inputs = [];
    htm;
    MSOM; % --- Multimodal Self-Organizing Map
    nb_categories = 0;
    observed_categories;
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
function obj = MultimodalFusionAndInference (htm)
	% --- Initialize MSOM
	obj.htm = htm;
	obj.MSOM = htm.MSOM;
	obj.observed_categories{1} = getInfo('obs_struct');
	obj.labels{1} = 'none_none';
end
% === CONSTRUCTOR [END] === %

% --- 
function newInput (obj, input_vector, iObj)
	obj.inputs(:, end+1) = input_vector;
	obj.trainMSOM(iObj);
	obj.setCategories();
	obj.setClasses();
	% obj.computePerformance();
end

function computePerformance (obj)
	av_cats = getObject(obj.htm, 'all', 'audiovisual_category');
	classes = unique(av_cats);
	for iCat = classes'
		% if isPerformant(obj, iCat)
			obj.observed_categories{iCat}.perf = obj.observed_categories{iCat}.nb_goodInf/obj.observed_categories{iCat}.nb_inf;
			if isnan(obj.observed_categories{iCat}.perf) || isinf(obj.observed_categories{iCat}.perf)
				obj.observed_categories{iCat}.perf = 0;
			end
			if obj.observed_categories{iCat}.perf > 1
				obj.observed_categories{iCat}.perf = 1;
				obj.observed_categories{iCat}.nb_inf = obj.observed_categories{iCat}.nb_goodInf;
			end
		% end
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
% 			if obj.observed_categories{iCat}.perf > 1
% 				obj.observed_categories{iCat}.perf = 1;
% 				obj.observed_categories{iCat}.nb_inf = obj.observed_categories{iCat}.nb_goodInf;
% 			end
% 		% end
% 	end
% end

function setClasses (obj)
	if isempty(obj.categories)
		obj.setCategories();
	end
	categories = obj.categories;
	for iClass = 1:numel(obj.categories)
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

function setCategories (obj)
	MSOM_categories = obj.MSOM.categories;

	obj.categories = arrayfun(@(x) mergeLabels(MSOM_categories(x, 1), MSOM_categories(x, 2)),...
							  1:size(MSOM_categories, 1),...
							  'UniformOutput', false);
	obj.nb_categories = numel(obj.categories);
	% obj.observed_categories = getInfo('obs_struct');
	% for ii = 1:numel(obj.categories)
	% 	obj.observed_categories.label = obj.nb
end

function trainMSOM (obj, iObj)
	% nb_env = numel(obj.htm.RIR.environments);
	% nb_objects = arrayfun(@(x) numel(getEnvironment(htm, x, 'objects')), nb_env);
	% for iEnv = 1:nb_env
	% 	env = getEnvironment(obj, iEnv);
	% 	for iObj = 1:nb_objects
			
			idx_data = getObject(obj, iObj, 'idx_data');
			obj.MSOM.feed(obj.inputs(:, end), idx_data);
	% end
end

function AVCategory = inferCategory (obj, input_vector)
	
	AVCategory = '';
	
	if isempty(obj.MSOM.categories)
		AVCategory = 'none_none';
		return;
	end

	[data, value] = obj.checkMissingModality(input_vector);

	switch value
	case 0    % --- no data
		AVCategory = 'none_none';
	   	return;
	case 3    % --- full data
		bmu = obj.MSOM.getCombinedBMU(data);
	otherwise % --- one of the modality is missing
		bmu = obj.MSOM.getBMU(data, value);
	end
	
	[alabel, vlabel] = obj.findLabels(bmu);

	AVCategory = mergeLabels(vlabel, alabel);
end

% --- Find the corresponding labels given the BMU computed earlier
function [alabel, vlabel] = findLabels (obj, bmu)
	[~, alabel] = max(obj.MSOM.weights_vectors{1}(bmu, :));
	[~, vlabel] = max(obj.MSOM.weights_vectors{2}(bmu, :));
end

% --- From the INPUT_VECTOR, find what modality seems to be missing and output the present modality
function [data, value] = checkMissingModality (obj, input_vector)
	nb_audio_labels = getInfo('nb_audio_labels');

	if sum(input_vector(1:nb_audio_labels)) < 0.2 &&...
	   sum(input_vector(nb_audio_labels+1:end)) < 0.2
	   value = 0;
	   data = input_vector;
	% --- Audio missing --> Find BMU with VISUAL components
	elseif sum(input_vector(1:nb_audio_labels)) < 0.2
		value = 2;
		data = input_vector(nb_audio_labels+1:end);
	% --- Vision missing --> Find BMU with AUDIO components
	elseif sum(input_vector(nb_audio_labels+1:end)) < 0.2
		value = 1;
		data = input_vector(1:nb_audio_labels);
	% --- Full vector --> Find BMU with both VISUAL & AUDIO components
	else
		value = 3;
		data = input_vector;
	end
end


function updateGoodInferenceCpt (obj, AVClass, search)
    if isempty(search)
        obj.createNewCategory(AVClass);
        search = find(strcmp(obj.labels, AVClass));
    else
		obj.observed_categories{search}.nb_goodInf = obj.observed_categories{search}.nb_goodInf + 1;
	end
end

function updateInferenceCpt (obj, AVClass, search)
    if isempty(search)
        obj.createNewCategory(AVClass);
        search = find(strcmp(obj.labels, AVClass));
    end
	obj.observed_categories{search}.nb_inf = obj.observed_categories{search}.nb_inf + 1;
end



function request = getCategories (obj)
	request = obj.categories ;
end

end
% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %