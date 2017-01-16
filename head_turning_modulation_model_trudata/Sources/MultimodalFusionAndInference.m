% 'MultimodalFusionAndInference' class
% This class is part of the HeadTurningModulationKS
% Author: Benjamin Cohen-Lhyver
% Date: 01.02.16
% Rev. 2.0

classdef MultimodalFusionAndInference < handle

% --- Properties --- %
properties (SetAccess = public, GetAccess = public)
    categories = {};
    inputs = [];
    htm;
    MSOM; % Multimodal Self-Organizing Map
    nb_categories = 0;
    labels = {};
end
% === Methods === %
methods

% --- Constructor (BEG) --- %
function obj = MultimodalFusionAndInference (htm)
	% --- Initialize MSOM
	obj.htm = htm;
	obj.MSOM = htm.MSOM;
end
% --- Constructor (END) --- %

% --- 
function newInput (obj, input_vector)
	obj.inputs = [obj.inputs, input_vector];
	obj.trainMSOM();
	obj.setCategories();
end

function setCategories (obj)
	MSOM_categories = obj.MSOM.categories;

	obj.categories = arrayfun(@(x) mergeLabels(MSOM_categories(x, 1) ,...
											   MSOM_categories(x, 2)),...
							  1:size(MSOM_categories, 1)			 ,...
							  'UniformOutput', false	 			  ...
							 );

	obj.nb_categories = numel(obj.categories);
end

function trainMSOM (obj)
	obj.MSOM.feed(obj.inputs(:, end));
end

function AVCategory = inferCategory (obj, input_vector)
	
	AVCategory = '' ;
	
	if isempty(obj.MSOM.categories)
		AVCategory = 'none_none';
		return ;
	end

	[data, value] = obj.checkMissingModality(input_vector);

	switch value
	case 0
		AVCategory = 'none_none';
	   	return;
	case 3
		bmu = obj.MSOM.getCombinedBMU(data);
	otherwise
		bmu = obj.MSOM.getBMU(data, value);
	end
	
	[alabel, vlabel] = obj.findLabels(bmu);

	AVCategory = mergeLabels(vlabel, alabel);
end

function [alabel, vlabel] = findLabels (obj, bmu)
	[~, alabel] = max(obj.MSOM.som_weights{1}(bmu, :));
	[~, vlabel] = max(obj.MSOM.som_weights{2}(bmu, :));
end

% === TO BE CHANGED >>> NO ROBUST TO TRUE DATA === %
function [data, value] = checkMissingModality (obj, input_vector)
	nb_audio_labels = getInfo('nb_audio_labels');

	if sum(input_vector(1:nb_audio_labels)) < 0.2 &&...
	   sum(input_vector(nb_audio_labels+1:end)) < 0.2
	   value = 0;
	   AVCategory = 'none_none';
	   return;
	% --- Audio missing
	% --- Find BMU with VISUAL components
	elseif sum(input_vector(1:nb_audio_labels)) < 0.2
		value = 2;
		data = input_vector(nb_audio_labels+1:end);
	% --- Vision missing
	% --- Find BMU with AUDIO components
	elseif sum(input_vector(nb_audio_labels+1:end)) < 0.2
		value = 1;
		data = input_vector(1:nb_audio_labels);
	% --- Full vector
	% --- Find BMU with both VISUAL & AUDIO components
	else
		value = 3;
		data = input_vector;
	end
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