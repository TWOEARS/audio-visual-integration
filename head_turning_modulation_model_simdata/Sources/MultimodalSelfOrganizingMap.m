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

properties (SetAccess = public, GetAccess = public)
    vec;
    sub_vec;

 	lrates = struct('initial', 0.9,...
    			    'final'  , 0.02);

    sigmas = struct('initial', 3e0,...
    				'final'  , 1);
    % sigmas = struct('initial', 3.0,...
    % 				'final'  , 1.0);
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
function obj = MultimodalSelfOrganizingMap ()
	% p = inputParser ;
	%   p.addOptional('Iterations', 10);
	%   p.addOptional('Leading', 1);
	% p.parse(varargin{:});
	% p = p.Results;

	obj.nb_iterations = getInfo('nb_iterations');

	obj.nb_modalities = 2;

	na = getInfo('nb_audio_labels');
	nv = getInfo('nb_visual_labels');
	
	tmp = (na * nv)/1;
	
	obj.som_dimension = [ceil(sqrt(tmp)), ceil(sqrt(tmp))];

	obj.leading = 2;

	obj.modalities = [na, nv];

	obj.idx_mod = cumsum([1, obj.modalities]);
	
	obj.nb_nodes = obj.som_dimension(1)*obj.som_dimension(2);

	obj.connections = zeros(obj.nb_nodes, 2);
	[obj.connections(:, 1), obj.connections(:, 2)] = ind2sub(obj.som_dimension, 1:obj.nb_nodes);
	
	init_msom = 1;	
	if getInfo('load')
		obj.weights_vectors = getappdata(0, 'weights_vectors');
	else
		for iMod = 1:obj.nb_modalities
			if init_msom == 1
				obj.weights_vectors{iMod} = rand(obj.nb_nodes, obj.modalities(iMod));
			elseif init_msom == 2
				obj.weights_vectors{iMod} = zeros(obj.nb_nodes, obj.modalities(iMod))+0.5;
				if iMod == 1 
					for iNode = 1:obj.nb_nodes
						tmp = rand(1, obj.modalities(iMod));
						tmp(tmp > 0.4) = 0.4;
						obj.weights_vectors{iMod}(iNode, :) = tmp;
						idx_mod = randi(obj.modalities(iMod));
						obj.weights_vectors{iMod}(iNode, idx_mod) = 1;
					end
				else
					% obj.weights_vectors{iMod} = rand(obj.nb_nodes, obj.modalities(iMod));
					obj.weights_vectors{iMod} = zeros(obj.nb_nodes, obj.modalities(iMod))+0.5;
				end
			elseif init_msom == 3
				obj.weights_vectors{iMod} = 0.4*rand(obj.nb_nodes, obj.modalities(iMod))+0.6;
			end
		end
		setappdata(0, 'weights_vectors', obj.weights_vectors);
	end

	vec = fliplr(reshape(prod(obj.som_dimension):-1:1, obj.som_dimension(1), obj.som_dimension(2))');
	obj.vec = repmat(vec, 3, 3);
	obj.sub_vec = obj.vec(obj.som_dimension(1)+1:2*obj.som_dimension(1), obj.som_dimension(1)+1:2*obj.som_dimension(1));

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

 	gaussian_coeff = 1;

	for iNode = 1:obj.nb_nodes
		for iStep = 1:nb_iterations
			obj.aleph{iNode, iStep} = exp(-sum((bsxfun(@minus, obj.connections(iNode, :), obj.connections).^2), 2) / (gaussian_coeff*obj.sig(iStep).^2));
		end
	end
end

function feed (obj, data, idx_data)
	% obj.cpt = obj.cpt + 1;

	% for ISTEP = 1:obj.nb_iterations
	% disp('feeding')
	ISTEP = (obj.nb_iterations - idx_data) + 1;
	ISTEP = max([ISTEP, 1]);
	% ISTEP = min([obj.idx_data, obj.nb_iterations]);
	idx = randperm(size(data, 2), size(data, 2));

	for iStep = 1:size(data, 2)
		% bmu = obj.getCombinedBMU(data(:, idx(iStep)));
		% bmu = obj.getBMU(data(1:getInfo('nb_audio_labels'), idx(iStep)), 1);
		bmu = obj.getBMU(data(getInfo('nb_audio_labels')+1:end, idx(iStep)), 2);
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

function plotND(obj)
	if isappdata(0, 'wvectors')
		wvectors = getappdata(0, 'wvectors');
	else
		wvectors = {obj.weights_vectors};
	end

	for iVectors = 1:numel(wvectors)
		weights_vector = wvectors{iVectors};

		d = zeros(obj.nb_nodes, 1);
		dv = zeros(obj.nb_nodes, 1);
		som_d = obj.som_dimension(1);
		for iNode = 1:obj.nb_nodes
			% idx = [iNode-1, iNode-22, iNode+1, iNode+22];
			idx = [iNode-1, iNode-(som_d-1), iNode-som_d, iNode-(som_d+1), iNode+1, iNode+(som_d-1), iNode+som_d, iNode+(som_d+1)];
			idx(idx <= 0) = [];
			idx(idx > obj.nb_nodes) = [];
			if mod(iNode, som_d) == 1 || mod(iNode, som_d) == 0
				idx_mod = mod(idx, som_d)+mod(iNode, som_d);
				idx(idx_mod == 1) = [];
			end
			v1 = weights_vector{1}(iNode, :);
			v2 = weights_vector{2}(iNode, :);

			d(iNode) = mean(sqrt(sum(bsxfun(@minus, v1, weights_vector{1}(idx, :)).^2, 2)));
			dv(iNode) = mean(sqrt(sum(bsxfun(@minus, v2, weights_vector{2}(idx, :)).^2, 2)));
		end

		% d = d+0.5;
		% dv = dv+0.5;
		d = reshape(d, som_d, som_d);
		dv = reshape(dv, som_d, som_d);
	    
	    d2 = 1-(d./(max(max(d))));
		d2v = 1-(dv./(max(max(dv))));

		d_all = d2.*d2v;
		d_all = d_all./(max(max(d_all)));

		seuil = 0.2;
		d2(d2 < seuil) = seuil;
		d2v(d2v < seuil) = seuil;
		d_all(d_all < seuil) = seuil;

		[X, Y] = meshgrid(1:som_d);

		figure('Color', 'White');

		hs = surf(X, Y, d2);%, gradient(dist1));
		% c = colorbar;
		set(gca, 'XLim', [0, som_d]+1,...
				 'YLim', [0, som_d]+1,...
				 'ZGrid', 'off',...
				 'ZColor', [1, 1, 1],...
				 'View', [-131.5000 66]);

		figure('Color', 'White');
		hs = surf(X, Y, d2v);%, gradient(dist1));
		% c = colorbar;
		set(gca, 'XLim', [0, som_d]+1,...
				 'YLim', [0, som_d]+1,...
				 'ZGrid', 'off',...
				 'ZColor', [1, 1, 1],...
				 'View', [-131.5000 66]);

		figure('Color', 'White');
		hs = surf(X, Y, d_all);%, gradient(dist1));
		% c = colorbar;
		set(gca, 'XLim', [0, som_d]+1,...
				 'YLim', [0, som_d]+1,...
				 'ZGrid', 'off',...
				 'ZColor', [1, 1, 1],...
				 'View', [-131.5000 66]);
	end

	% subplot(1, 2, 1);
	% axis;
	% set(gca, 'XLim' , [1, obj.som_dimension(1)+1],...
	%          'YLim' , [1, obj.som_dimension(1)+1],...
	%          'XTick', [1:obj.som_dimension(1)],...
	%          'YTick', [1:obj.som_dimension(1)]);
	% grid on;
	% hold on;


	% [I, J] = ind2sub(som_d, 1:obj.nb_nodes);

	% for iNode = 1:obj.nb_nodes
	%     x = I(iNode);
	%     y = J(iNode);

	%     % patch([x, x+1, x+1, x], [y, y, y+1, y+1], 'blue', 'FaceAlpha', d2(x, y));
	%     patch([x, x+1, x+1, x], [y, y, y+1, y+1], [1, 1, 1]-d2(x, y));
	% end

	% subplot(1, 2, 2);
	% axis;
	% set(gca, 'XLim' , [1, som_d+1],...
	%          'YLim' , [1, som_d+1],...
	%          'XTick', [1:som_d],...
	%          'YTick', [1:som_d]);
	% grid on;
	% hold on;
	% for iNode = 1:obj.nb_nodes
	%     x = I(iNode);
	%     y = J(iNode);

	%     % patch([x, x+1, x+1, x], [y, y, y+1, y+1], 'blue', 'FaceAlpha', d2v(x, y));
	%     patch([x, x+1, x+1, x], [y, y, y+1, y+1], [1, 1, 1]-d2v(x, y));
	% end
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