classdef MSOM < handle

% --- Properties --- %
properties (SetAccess = public, GetAccess = public)
    lrates = struct('initial', 0.5,...
    			    'final'  , 0.1) ;

    sigmas = struct('initial', 3.0e0,...
    				'final'  , 1.0e-1) ;

    % som_weights = 0 ;
    som_weights = cell(0) ;
    som_grid = [] ;

    modalities = 0 ;
    nb_modalities = 0 ;
    leading = 0 ;
    idx_mod = [] ;

    nb_nodes = 0 ;
    som_dimension = [0, 0] ;

    INIT = false ;

    nb_iterations = 0 ;

    categories = cell(0) ;
    cat = cell(0) ;

    aleph = [] ;
    mu = [] ;
    sig = [] ;

    cpt = 0;

end

methods

function obj = MSOM (varargin)

	p = inputParser ;
	  % p.addOptional('Dim', [10, 10]) ;
	  p.addOptional('Iterations', 1) ;
	  % p.addOptional('Modalities', 0) ;
	  p.addOptional('Leading', 1) ;
	p.parse(varargin{:}) ;
	p = p.Results ;

	obj.nb_iterations = p.Iterations ;

	obj.nb_modalities = 2;

	na = getInfo('nb_audio_labels');
	nv = getInfo('nb_visual_labels');
	
	tmp = na * nv;
	
	obj.som_dimension = [ceil(sqrt(tmp)), ceil(sqrt(tmp))];

	obj.leading = p.Leading;

	obj.modalities = [na, nv];

	obj.idx_mod = cumsum([1, obj.modalities]);

	% obj.som_weights = cell(1, obj.nb_modalities) ;
	
	obj.nb_nodes = obj.som_dimension(1)*obj.som_dimension(2) ;

	obj.som_grid = zeros(obj.nb_nodes, 2) ;
	[obj.som_grid(:, 1), obj.som_grid(:, 2)] = ind2sub(obj.som_dimension, 1:obj.nb_nodes) ;
	
	for iMod = 1:obj.nb_modalities
		obj.som_weights{iMod} = rand(obj.nb_nodes, obj.modalities(iMod)) ;
	end

	obj.setParameters(obj.nb_iterations) ;

end

function setParameters (obj, nb_iterations)

	obj.mu = zeros(1, nb_iterations) ;
	obj.sig = zeros(1, nb_iterations) ;
	% === Initializing parameters of learning
	for iStep = 1:nb_iterations
		tfrac = iStep / nb_iterations ; 
		obj.mu(iStep) = obj.lrates.initial + tfrac * (obj.lrates.final - obj.lrates.initial) ;
		obj.sig(iStep) = obj.sigmas.initial + tfrac * (obj.sigmas.final - obj.sigmas.initial) ;
	end
	
	obj.aleph = cell(obj.nb_nodes, nb_iterations) ;

	for iNode = 1:obj.nb_nodes
		for iStep = 1:nb_iterations
			obj.aleph{iNode, iStep} = exp(-sum((bsxfun(@minus, obj.som_grid(iNode, :), obj.som_grid).^2), 2) / (2*obj.sig(iStep).^2)) ;
		end
	end
end

function feed (obj, data)
	obj.cpt = obj.cpt+1;

	for ISTEP = 1:obj.nb_iterations
		idx = randperm(size(data, 2), size(data, 2)) ;

		for iStep = 1:size(data, 2)
			bmu = obj.findBestBMU(data(:, idx(iStep)));
			obj.update_weights(data(:, idx(iStep)), bmu, ISTEP);
		end
	end

	obj.findClusters() ;
end


function best_matching_unit = findBMU (obj, vector, modality)
	% --- Euclidian distance
	[~, best_matching_unit] = min(sqrt(sum(bsxfun(@minus, vector', obj.som_weights{modality}).^2, 2))) ;
end

function best_matching_unit = findBestBMU (obj, vector)
	% --- Euclidian distance
	tmp1 = sqrt(sum(bsxfun(@minus, vector(1:getInfo('nb_audio_labels'))', obj.som_weights{1}).^2, 2));
	tmp2 = sqrt(sum(bsxfun(@minus, vector(getInfo('nb_audio_labels')+1:end)', obj.som_weights{2}).^2, 2));
	tmp = tmp1.*tmp2;
	[~, best_matching_unit] = min(tmp);
end

function update_weights (obj, vector, bmu, ISTEP)

	tmp = obj.mu(ISTEP) * obj.aleph{bmu, ISTEP} ;

	% dw = mu * aleph * bsxfun(@minus, vector', obj.som_weights{modality}) ;
	vec = vector(1:getInfo('nb_audio_labels')) ;
	dw = bsxfun(@times, tmp, bsxfun(@minus, vec', obj.som_weights{1})) ;
	obj.som_weights{1} = obj.som_weights{1} + dw ; 
	

	vec = vector(getInfo('nb_audio_labels')+1:end) ;
	dw = bsxfun(@times, tmp, bsxfun(@minus, vec', obj.som_weights{2})) ;
	obj.som_weights{2} = obj.som_weights{2} + dw ; 
end

function findClusters (obj)

	[~, max_a] = max(obj.som_weights{1}, [], 2) ;
	[~, max_v] = max(obj.som_weights{2}, [], 2) ;

	% obj.categories = [max_v(1), max_a(1)] ;
	obj.categories = unique([max_v, max_a], 'Rows') ;
end

function assignNodesToCategories (obj)

	[~, max_a] = max(obj.som_weights{1}, [], 2) ;
	[~, max_v] = max(obj.som_weights{2}, [], 2) ;

	obj.cat = cell(size(obj.categories, 1), 1) ;
	for iCat = 1:size(obj.categories, 1)
		f1 = find(obj.categories(iCat, 1) == max_v) ;
		f2 = find(obj.categories(iCat, 2) == max_a) ;
		f = intersect(f1, f2) ;
		obj.cat{iCat} = f' ;
	end
end

function request = getDistances (obj, data)
	request = [] ;
	for iVec = 1:size(data, 2)
		tmp1 = sqrt(sum(bsxfun(@minus, data(1:obj.modalities(1), iVec)', obj.som_weights{1}).^2, 2)) ;
		tmp2 = sqrt(sum(bsxfun(@minus, data(obj.modalities(1)+1:end, iVec)', obj.som_weights{2}).^2, 2)) ;
		tmp = tmp1.*tmp2 ;
		request = [request, tmp] ;
	end
end


end

end