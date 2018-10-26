size_map = 100;

[X, Y] = meshgrid(1:size_map);

d = rand(1, getInfo('nb_sources'));
d = d*50;
d(d < 25) = 25;
d(d>75) = 75;

positions = getInfo('sources_position');

[xs, ys] = pol2cart(deg2rad(positions), d);
xs = round(xs)+size_map/2;
ys = round(ys)+size_map/2;

mat = zeros(size_map, size_map);%+0.08*rand(size_map, size_map);

ws = getObject(htm, 'all', 'weight');

g = fspecial('gaussian', 15, 4);
g = g./(max(max(g)));

tmp = [];
for ii = 1:numel(d)
	c = getCategory(htm, ii, 'Object');
	tmp(end+1) = c.proba;
end

tmp = tmp./max(tmp);
data = modulesActivity(htm);

for iObject = 1:numel(d)
	iSource = getObject(htm, iObject, 'source');
	
	idx_x = [xs(iSource)-7:xs(iSource)+7];
	idx_y = [ys(iSource)-7:ys(iSource)+7];
	% c = getCategory(htm, iObject, 'Object');
	% ws(iSource)
	% mat(xs(iSource), ys(iSource)-1:ys(iSource)+1) = c.proba;
	% mat(xs(iSource)-1:xs(iSource)+1, ys(iSource)) = c.perf;
	% mat(xs(iSource), ys(iSource)+1) = c.congruence;


	% if tmp(iObject) == 0
	% 	data = -0.5;
	% else
	% 	data = tmp(iObject);
	% end

	mat(idx_x, idx_y) = data(iObject).*g;
end

colormap hot;
h1 = surf(X, Y, mat, 'FaceColor','interp',...
				'EdgeColor','none')%,...
   			    % 'FaceLighting','gouraud');

hold on;

h2 = surf(X, Y, ones(size_map, size_map), 'FaceColor', [0.8, 0.8, 0.8],...
								     'EdgeColor', 'none',...
								     'FaceLighting','gouraud',...
								     'FaceAlpha', 0.5);
