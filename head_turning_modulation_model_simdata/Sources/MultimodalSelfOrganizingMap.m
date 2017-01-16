% 'MultimodalSelfOrganizingMap' class
% This class implements a modified SOM that aims at clustering the input vectors coming from the classifiers.
% It outputs a categorized 2D map with as many subdimensions (or submaps) as the number of modalities available.
% At the moment, the Two!Ears system an handle two modalities: vision & audition.
% (reference: Benjamin Cohen-Lhyver, Multimodal fusion and inference using binaural audition and vision, ICA 2016)
% Author: Benjamin Cohen-Lhyver
% Date: 21.05.16
% Rev. 2.0

classdef MultimodalSelfOrganizingMap < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    weights_vectors = cell(0);
    connections = [];

    modalities = 0;
    nb_modalities = 0;
    leading = 0;
    idx_mod = [];

    nb_nodes = 0;
    som_dimension = [0, 0];
    
    nb_iterations = 0;

    categories = cell(0);
    cat = cell(0);

    cpt = 0;

    idx_data;
end

properties (SetAccess = private, GetAccess = public)
 	lrates = struct('initial', 0.5,...
    			    'final'  , 0.1);

    sigmas = struct('initial', 1.5e0,...
    				'final'  , 1.0e-1);
    aleph = [];
    mu = [];
    sig = [];
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = MultimodalSelfOrganizingMap (varargin)
	p = inputParser ;
	  p.addOptional('Iterations', 1);
	  p.addOptional('Leading', 1);
	p.parse(varargin{:});
	p = p.Results;

	obj.nb_iterations = p.Iterations;

	obj.nb_modalities = 2;

	na = getInfo('nb_audio_labels');
	nv = getInfo('nb_visual_labels');
	
	tmp = na * nv;
	
	obj.som_dimension = [ceil(sqrt(tmp)), ceil(sqrt(tmp))];

	obj.leading = p.Leading;

	obj.modalities = [na, nv];

	obj.idx_mod = cumsum([1, obj.modalities]);
	
	obj.nb_nodes = obj.som_dimension(1)*obj.som_dimension(2);

	obj.connections = zeros(obj.nb_nodes, 2);
	[obj.connections(:, 1), obj.connections(:, 2)] = ind2sub(obj.som_dimension, 1:obj.nb_nodes);
	
	if getInfo('load')
		obj.weights_vectors = getappdata(0, 'weights_vectors');
	else
		for iMod = 1:obj.nb_modalities
			obj.weights_vectors{iMod} = rand(obj.nb_nodes, obj.modalities(iMod));
		end
		setappdata(0, 'weights_vectors', obj.weights_vectors);
	end

	obj.setParameters(obj.nb_iterations);
end
% === CONSTRUCTOR [END] === %

function setParameters (obj, nb_iterations)

	obj.mu = zeros(1, nb_iterations);
	obj.sig = zeros(1, nb_iterations);
	% === Initializing parameters of learning
	for iStep = 1:nb_iterations
		tfrac = iStep / nb_iterations;
		obj.mu(iStep) = obj.lrates.initial + tfrac * (obj.lrates.final - obj.lrates.initial);
		obj.sig(iStep) = obj.sigmas.initial + tfrac * (obj.sigmas.final - obj.sigmas.initial);
	end
	
	obj.aleph = cell(obj.nb_nodes, nb_iterations);

	for iNode = 1:obj.nb_nodes
		for iStep = 1:nb_iterations
			obj.aleph{iNode, iStep} = exp(-sum((bsxfun(@minus, obj.connections(iNode, :), obj.connections).^2), 2) / (2*obj.sig(iStep).^2));
		end
	end
end

function feed (obj, data)
	% obj.cpt = obj.cpt + 1;

	% for ISTEP = 1:obj.nb_iterations
	% disp('feeding')
	ISTEP = (obj.nb_iterations - obj.idx_data) + 1;
	ISTEP = max([ISTEP, 1]);
	% ISTEP = min([obj.idx_data, obj.nb_iterations]);
	idx = randperm(size(data, 2), size(data, 2));

	for iStep = 1:size(data, 2)
		bmu = obj.getCombinedBMU(data(:, idx(iStep)));
		obj.update_weights(data(:, idx(iStep)), bmu, ISTEP);
	end
	% end

	obj.clusterizeMSOM();
end

function best_matching_unit = getBMU (obj, vector, modality)
	% --- Euclidian distance
	% euclidian_distance = euclidianDistance(vector, modality);
	d = obj.euclidianDistance(vector, modality);
	[~, best_matching_unit] = min(d);
	% [~, best_matching_unit] = min(sqrt(sum(bsxfun(@minus, vector', obj.weights_vectors{modality}).^2, 2)));
end

function best_matching_unit = getCombinedBMU (obj, vector)
	na = getInfo('nb_audio_labels');
	% --- Euclidian distance
	audio_distance = obj.euclidianDistance(vector(1:na), 1);
	visual_distance = obj.euclidianDistance(vector(na+1:end), 2);
	combined_distance = audio_distance.*visual_distance;
	[~, best_matching_unit] = min(combined_distance);
end

% function [audio_distance, visual_distance, combined_distance] = findBestBMU2 (obj, vector)
% 	% --- Euclidian distance
% 	audio_distance = sqrt(sum(bsxfun(@minus, vector(1:getInfo('nb_audio_labels'))', obj.weights_vectors{1}).^2, 2));
% 	visual_distance = sqrt(sum(bsxfun(@minus, vector(getInfo('nb_audio_labels')+1:end)', obj.weights_vectors{2}).^2, 2));
% 	combined_distance = audio_distance.*visual_distance;
% 	% [~, best_matching_unit] = min(combined_weights);
% end

function euclidian_distance = euclidianDistance (obj, vector, modality)
	euclidian_distance = sqrt(sum(bsxfun(@minus, vector', obj.weights_vectors{modality}).^2, 2));
end

function update_weights (obj, vector, bmu, ISTEP)

	na = getInfo('nb_audio_labels');
	tmp = obj.mu(ISTEP) * obj.aleph{bmu, ISTEP};
	% dw = mu * aleph * bsxfun(@minus, vector', obj.weights_vectors{modality}) ;
	vec = vector(1:na);
	dw = bsxfun(@times, tmp, bsxfun(@minus, vec', obj.weights_vectors{1}));
	obj.weights_vectors{1} = obj.weights_vectors{1} + dw;

	vec = vector(na+1:end);
	dw = bsxfun(@times, tmp, bsxfun(@minus, vec', obj.weights_vectors{2}));
	obj.weights_vectors{2} = obj.weights_vectors{2} + dw;
end

function clusterizeMSOM (obj)

	[~, max_a] = max(obj.weights_vectors{1}, [], 2);
	[~, max_v] = max(obj.weights_vectors{2}, [], 2);

	obj.categories = unique([max_v, max_a], 'Rows');
end

function assignNodesToCategories (obj)

	[~, max_a] = max(obj.weights_vectors{1}, [], 2);
	[~, max_v] = max(obj.weights_vectors{2}, [], 2);

	obj.cat = cell(size(obj.categories, 1), 1);
	for iCat = 1:size(obj.categories, 1)
		f1 = find(obj.categories(iCat, 1) == max_v);
		f2 = find(obj.categories(iCat, 2) == max_a);
		f = intersect(f1, f2);
		obj.cat{iCat} = f';
	end
end

function request = getDistances (obj, data)
	request = [] ;
	for iVec = 1:size(data, 2)
		tmp1 = sqrt(sum(bsxfun(@minus, data(1:obj.modalities(1), iVec)', obj.weights_vectors{1}).^2, 2)) ;
		tmp2 = sqrt(sum(bsxfun(@minus, data(obj.modalities(1)+1:end, iVec)', obj.weights_vectors{2}).^2, 2)) ;
		tmp = tmp1.*tmp2 ;
		request = [request, tmp] ;
	end
end
% ===================== %
% === METHODS [END] === %
% ===================== %
end

% =================== %
% === END OF FILE === %
% =================== %
end