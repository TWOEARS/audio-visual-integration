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
		v1 = obj.weights_vectors{1}(iNode, :);
		v2 = obj.weights_vectors{2}(iNode, :);

		d(iNode) = mean(sqrt(sum(bsxfun(@minus, v1, obj.weights_vectors{1}(idx, :)).^2, 2)));
		dv(iNode) = mean(sqrt(sum(bsxfun(@minus, v2, obj.weights_vectors{2}(idx, :)).^2, 2)));
	end

	% d = d+0.5;
	% dv = dv+0.5;
	d = reshape(d, som_d, som_d);
	dv = reshape(dv, som_d, som_d);
    
 %    d2 = d./(max(max(d)));
	% d2v = dv./(max(max(dv)));





fo_mfi = zeros(1000, 1);
fo_dw = zeros(1000, 1);

for ii = 2:1000
	if dw_mfi(ii, 1) == 0
		fo_dw(ii) = fo_dw(ii-1);
		% fo_dw(ii) = ;
	else
		% cumsum(fo_dw(1:ii)) ./ (1:ii)';
		fo_dw(ii) = fo_dw(ii-1) + 1;
	end

	if dw_mfi(ii, 2) == 0
		fo_mfi(ii) = fo_mfi(ii-1);
		% fo_mfi(ii) = 0;
	else
		% cumsum(fo_mfi(1:ii)) ./ (1:ii)';
		fo_mfi(ii) = fo_mfi(ii-1) + 1;
	end
end

for ii = 2:1000

	if dw_mfi(ii, 1) == 0 && dw_mfi(ii, 2) == 0
		dw_mfi(ii, 3) = dw_mfi(ii-1, 3);
	else
		dw_mfi(ii, 3) = dw_mfi(ii, 2) / dw_mfi(ii, 1);
	end





	

x1 = htm1.statistics.mfi_mean(:, end);
x2 = htm2.statistics.mfi_mean(:, end);
x3 = htm3.statistics.mfi_mean(:, end);
x4 = htm4.statistics.mfi_mean(:, end);
x5 = htm5.statistics.mfi_mean(:, end);

x = [x1, x2, x3, x4, x5];

t = (1:500)';

s_min = min(x')';
s_max = max(x')';

m = mean([x1, x2, x3, x4, x5], 2);
s = std([x1, x2, x3, x4, x5]');

s = s(50:50:500);

X = [t', fliplr(t')];
Y = [s_min', fliplr(s_max')];

figure('Color', 'white');
hold on;
h1 = fill(X, Y, [51, 153, 255]/255);
set(h1, 'EdgeAlpha', 0);
plot(t, m);
% errorbar(50:50:500, m(50:50:500), s)


x1 = htm1.statistics.max_mean(:, end);
x2 = htm2.statistics.max_mean(:, end);
x3 = htm3.statistics.max_mean(:, end);
x4 = htm4.statistics.max_mean(:, end);
x5 = htm5.statistics.max_mean(:, end);

x = [x1, x2, x3, x4, x5];

t = (1:500)';

s_min = min(x')';
s_max = max(x')';

m = mean([x1, x2, x3, x4, x5], 2);

X = [t', fliplr(t')];
Y = [s_min', fliplr(s_max')];

h2 = fill(X, Y, [0, 102, 204]/255);
set(h2, 'EdgeAlpha', 0);

plot(t, m)




