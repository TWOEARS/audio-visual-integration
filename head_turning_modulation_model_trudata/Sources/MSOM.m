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

    nb_steps = 1 ;

    categories = cell(0) ;
    cat = cell(0) ;

    aleph = [] ;
    mu = [] ;
    sig = [] ;

end

methods

function obj = MSOM (varargin)

	p = inputParser ;
	  % p.addOptional('Dim', [10, 10]) ;
	  p.addOptional('Steps', 1) ;
	  p.addOptional('Modalities', 0) ;
	  p.addOptional('Leading', 1) ;
	p.parse(varargin{:}) ;
	p = p.Results ;

	obj.nb_steps = p.Steps ;

	obj.nb_modalities = numel(p.Modalities) ;
	
	tmp = p.Modalities(1)*p.Modalities(2) ;
	
	obj.som_dimension = [ceil(sqrt(tmp)), ceil(sqrt(tmp))] ;

	obj.leading = p.Leading ;

	obj.modalities = p.Modalities ;

	obj.idx_mod = cumsum([1, obj.modalities]) ;

	% obj.som_weights = cell(1, obj.nb_modalities) ;
	
	obj.nb_nodes = obj.som_dimension(1)*obj.som_dimension(2) ;

	obj.som_grid = zeros(obj.nb_nodes, 2) ;
	[obj.som_grid(:, 1), obj.som_grid(:, 2)] = ind2sub(obj.som_dimension, 1:obj.nb_nodes) ;
	
	for iMod = 1:obj.nb_modalities
		obj.som_weights{iMod} = rand(obj.nb_nodes, obj.modalities(iMod)) ;
	end

	obj.mu = zeros(1, obj.nb_steps) ;
	obj.sig = zeros(1, obj.nb_steps) ;
	% === Initializing parameters of learning
	for iStep = 1:obj.nb_steps
		tfrac = iStep / obj.nb_steps ; 
		obj.mu(iStep) = obj.lrates.initial + tfrac * (obj.lrates.final - obj.lrates.initial) ;
		obj.sig(iStep) = obj.sigmas.initial + tfrac * (obj.sigmas.final - obj.sigmas.initial) ;
	end
	
	obj.aleph = cell(obj.nb_nodes, obj.nb_steps) ;

	for iNode = 1:obj.nb_nodes
		for iStep = 1:obj.nb_steps
			obj.aleph{iNode, iStep} = exp(-sum((bsxfun(@minus, obj.som_grid(iNode, :), obj.som_grid).^2), 2) / (2*obj.sig(iStep).^2)) ;
		end
	end

end

function feed (obj, data)
	% global ISTEP ;
	% ISTEP = 1 ;

	for ISTEP = 1:obj.nb_steps
		idx = randperm(size(data, 2), size(data, 2)) ;

		for iStep = 1:size(data, 2)
			% bmu = obj.findBMU(data(1:obj.modalities(1), idx(iStep)), 1) ;

			bmu = obj.findBestBMU(data(:, idx(iStep))) ;

			obj.update_weights(data(:, idx(iStep)), bmu, ISTEP) ;

			% obj.update_weights(data(1:21, idx(iStep)), bmu, 1) ;
			% obj.update_weights(data(22:end, idx(iStep)), bmu, 2) ;
		end
	end

	obj.findClusters() ;
end


function best_matching_unit = findBMU (obj, vector, modality)
	% --- One-line version
	[~, best_matching_unit] = min(sqrt(sum(bsxfun(@minus, vector', obj.som_weights{modality}).^2, 2))) ;
end

function best_matching_unit = findBestBMU (obj, vector)
	
	tmp1 = sqrt(sum(bsxfun(@minus, vector(1:obj.modalities(1))', obj.som_weights{1}).^2, 2)) ;
	tmp2 = sqrt(sum(bsxfun(@minus, vector(obj.modalities(1)+1:end)', obj.som_weights{2}).^2, 2)) ;
	tmp = tmp1.*tmp2 ;
	[~, best_matching_unit] = min(tmp) ;

	% [bmu_a, tmp1] = min(sqrt(sum(bsxfun(@minus, vector(1:obj.modalities(1))', obj.som_weights{1}).^2, 2))) ;
	% [bmu_v, tmp2] = min(sqrt(sum(bsxfun(@minus, vector(obj.modalities(1)+1:end)', obj.som_weights{2}).^2, 2))) ;

	% if bmu_a < bmu_v
	% 	best_matching_unit = tmp1 ;
	% else
	% 	best_matching_unit = tmp2 ;
	% end
end

function update_weights (obj, vector, bmu, ISTEP)
	% global ISTEP ;

	% tfrac = ISTEP / obj.nb_steps ;
	% % --- mu = parameter for the learning function
	% mu = obj.lrates.initial + tfrac * (obj.lrates.final - obj.lrates.initial) ;
	% % --- sig = parameter for the neighborhood function
	% sig = obj.sigmas.initial + tfrac * (obj.sigmas.final - obj.sigmas.initial) ;

	% aleph = exp(-sum((bsxfun(@minus, obj.som_grid(bmu, :), obj.som_grid).^2), 2) / (2*sig^2)) ;

	tmp = obj.mu(ISTEP) * obj.aleph{bmu, ISTEP} ;

	% dw = mu * aleph * bsxfun(@minus, vector', obj.som_weights{modality}) ;
	vec = vector(1:obj.modalities(1)) ;
	dw = bsxfun(@times, tmp, bsxfun(@minus, vec', obj.som_weights{1})) ;
	obj.som_weights{1} = obj.som_weights{1} + dw ; 
	

	vec = vector(obj.modalities(1)+1:end) ;
	dw = bsxfun(@times, tmp, bsxfun(@minus, vec', obj.som_weights{2})) ;
	obj.som_weights{2} = obj.som_weights{2} + dw ; 


		% for iNode = 1:obj.nb_nodes
		% 	% --- aleph = learning rate
		    % aleph = exp(-sum((obj.som_grid(bmu, :) - obj.som_grid(iNode, :)).^2) / (2*sig^2)) ;

		%     % dw = mu * aleph * (vector' - obj.som_weights{modality}(iNode, :)) ;
		%     % dw = mu * aleph(iNode) * (vector' - obj.som_weights{modality}(iNode, :)) ;
		%     % dw = tmp(iNode) * (vector' - obj.som_weights{iI}(iNode, :)) ;
		%     dw = tmp(iNode) * (vec' - obj.som_weights{iI}(iNode, :)) ;

		%     % --- Update iNode(th) node's weights
		%     obj.som_weights{iI}(iNode, :) = obj.som_weights{iI}(iNode, :) + dw ; 
		% end
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


% ==================================== %
% ========== PLOT FUNCTIONS ========== %
% ==================================== %

function plotHits (obj, vec)

	axis ;
	set(gca, 'XLim' , [1, obj.som_dimension(1)+1],...
			 'YLim' , [1, obj.som_dimension(1)+1],...
			 'XTick', [1:obj.som_dimension(1)],...
			 'YTick', [1:obj.som_dimension(1)]) ;
	grid on ;
	hold on ;

	s = size(vec, 2) ;
	% d1 = data(:, 4) ;
	dist1 = zeros(obj.nb_nodes, s) ;
	dist2 = zeros(obj.nb_nodes, s) ;
	dist3 = zeros(obj.nb_nodes, s) ;

	for iVec = 1:s
		dist1(:, iVec) = sqrt(sum(bsxfun(@minus, vec(1:obj.modalities(1), iVec)', obj.som_weights{1}).^2, 2)) ;
		dist2(:, iVec) = sqrt(sum(bsxfun(@minus, vec(obj.modalities(1)+1:end, iVec)', obj.som_weights{2}).^2, 2)) ;
		dist3(:, iVec) = dist1(:, iVec).*dist2(:, iVec) ;
	end

	dist1 = mean(dist1, 2) ;
	dist2 = mean(dist2, 2) ;
	dist3 = mean(dist3, 2) ;

	dist1 = 1./dist1 ;
	dist1 = (dist1 - min(dist1))/max(dist1) ;
	
	dist2 = 1./dist2 ;
	dist2 = (dist2 - min(dist2))/max(dist2) ;
	
	dist3 = 1./dist3 ;
	dist3 = (dist3 - min(dist3))/max(dist3) ;


	[I, J] = ind2sub(obj.som_dimension(1), 1:obj.nb_nodes) ;

	for iNode = 1:obj.nb_nodes
		x = I(iNode) ;
		y = J(iNode) ;

		x1 = x + ((1-dist1(iNode))/2) ;
		y1 = y + ((1-dist1(iNode))/2) ;

		x1 = [x1, x1+dist1(iNode), x1+dist1(iNode), x1] ;
		y1 = [y1, y1, y1+dist1(iNode), y1+dist1(iNode)] ;

		x2 = x + ((1-dist2(iNode))/2) ;
		y2 = y + ((1-dist2(iNode))/2) ;

		x2 = [x2, x2+dist2(iNode), x2+dist2(iNode), x2] ;
		y2 = [y2, y2, y2+dist2(iNode), y2+dist2(iNode)] ;

		x3 = [x, x+1, x+1, x] ;
		y3 = [y, y, y+1, y+1] ;
		patch(x3, y3, 'blue', 'FaceAlpha', dist3(iNode)) ;

		if dist1(iNode) >= dist2(iNode)
			patch(x1, y1, 'red') ;
			patch(x2, y2, 'black') ;
		else
			patch(x2, y2, 'black') ;
			patch(x1, y1, 'red') ;
		end
	end

	% bmu = obj.findBestBMU(vec) ;
	% x = I(bmu) ;
	% y = J(bmu) ;
	% rectangle('Position', [x, y, 1, 1],...
	% 		  'EdgeColor', 'green',...
	% 		  'LineWidth', 4,...
 %          	  'LineStyle', '--') ;
end


function plotMultipleHits (obj, data)
	for iVec = 1:size(data, 2)

	end
end


end

end