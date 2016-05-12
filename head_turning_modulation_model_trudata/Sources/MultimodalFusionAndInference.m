% 'MultimodalFusionAndInference' class
% This class is part of the HeadTurningModulationKS
% Author: Benjamin Cohen-Lhyver
% Date: 01.02.16
% Rev. 2.0

classdef MultimodalFusionAndInference < handle

% --- Properties --- %
properties (SetAccess = public, GetAccess = public)
    categories = {} ;
    inputs = [] ;
    nb_modalities = 2 ;
    MSOM = [] ;
    nb_categories = 0 ;
    labels = {} ;
end

% === Methods === %
methods

% --- Constructor (BEG) --- %
function obj = MultimodalFusionAndInference ()

	% --- Retrieve audio and visual data
	obj.nb_modalities = 2 ;
	% --- Initialize MSOM
	obj.createMSOM() ;
end
% --- Constructor (END) --- %

function createMSOM (obj)
	obj.MSOM = MSOM() ;
end

% --- 
function newInput (obj, input_vector)
	obj.inputs = [obj.inputs, input_vector] ;
	obj.trainMSOM() ;
	obj.setCategories() ;
	% obj.labels = [obj.labels ; obj.inferCategory(input_vector)] ;
end

function setCategories (obj)
	
	v = getInfo('visual_labels');
	a = getInfo('audio_labels');
	
	MSOM_categories = obj.MSOM.categories ;
	obj.categories = cell(size(MSOM_categories, 1), 1) ;

	
	for iCat = 1:size(MSOM_categories, 1)
		obj.categories{iCat} = [v{MSOM_categories(iCat, 1)}, '_', a{MSOM_categories(iCat, 2)}] ;
	end
	obj.nb_categories = numel(obj.categories) ;
	% obj.assignNodesToCategories() ;
	% obj.contributions_of_nodes = obj.MSOM.cat ;
end

function trainMSOM (obj)
	obj.MSOM.feed(obj.inputs) ;
end

function AVCategory = inferCategory (obj, input_vector)
	AVCategory = '' ;
	if isempty(obj.MSOM.categories)
		AVCategory = 'none_none' ;
		return ;
	end

	a = getInfo('nb_audio_labels');

	if sum(input_vector(1:a)) < 0.2 &&...
	   sum(input_vector(a+1:end)) < 0.2
	   AVCategory = 'none_none' ;
	   return ;
	% --- Audio missing
	elseif sum(input_vector(1:a)) < 0.2
		bmu = obj.MSOM.findBMU(input_vector(a+1:end), 2) ;
	% --- Vision missing
	elseif sum(input_vector(a+1:end)) < 0.2
		bmu = obj.MSOM.findBMU(input_vector(1:a), 1) ;
	% --- If vector is complete
	else
		bmu = obj.MSOM.findBestBMU(input_vector) ;
	end

	visual_labels = getInfo('visual_labels');
	audio_labels = getInfo('audio_labels');

	[~, alabel] = max(obj.MSOM.som_weights{1}(bmu, :)) ;
	[~, vlabel] = max(obj.MSOM.som_weights{2}(bmu, :)) ;
	vlabel = visual_labels{vlabel} ;
	alabel = audio_labels{alabel} ;
	AVCategory = [vlabel, '_', alabel] ;
end

function request = getCategories (obj)
	request = obj.categories ;
end

% --- END PROPERTIES
end
% --- END OBJECT
end