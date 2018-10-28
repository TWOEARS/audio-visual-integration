lrates = struct('initial', 0.9,...
    			    'final'  , 0.02);

sigmas = struct('initial', 3e0,...
				'final'  , 1);


nb_iterations = 10;

mu = zeros(1, nb_iterations);
sig = zeros(1, nb_iterations);

for iStep = 1:nb_iterations
	tfrac = iStep / nb_iterations;
	mu(iStep) = lrates.initial + tfrac * (lrates.final - lrates.initial);
	sig(iStep) = sigmas.initial + tfrac * (sigmas.final - sigmas.initial);
end

na = 8;
nv= 6;

tmp = (na * nv)/1;

som_dimension = [ceil(sqrt(tmp)), ceil(sqrt(tmp))];
nb_nodes = som_dimension(1)*som_dimension(2);
aleph = cell(nb_nodes, nb_iterations);

connections = zeros(nb_nodes, 2);
[connections(:, 1), connections(:, 2)] = ind2sub(som_dimension, 1:nb_nodes);

gaussian_coeff = 1;
for iNode = 1:nb_nodes
	for iStep = 1:nb_iterations
		aleph{iNode, iStep} = exp(-sum((bsxfun(@minus, connections(iNode, :), connections).^2), 2) / (gaussian_coeff*sig(iStep).^2));
	end
end





for ii = 1:10
	figure;
	set(gcf, 'Color', 'white');
	plot(aleph{24, ii}*mu(ii), 'LineWidth', 2);
	set(gca, 'XLim', [0, nb_nodes], 'YLim', [0, 1], 'FontSize', 20);
	xlabel('nodes');
	ylabel('standard deviation'),
end