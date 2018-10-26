function plotHeadMovements (obj)

nb_sources = obj.nb_sources;

figure('Color', 'white');
h = axes('FontSize', 16);

[x, y] = pol2cart(obj.angles_rad, obj.angles_cpt(1, :));
shm_handle = compass([x, x], [y, y], 'Parent', h);

[x2, y2] = pol2cart(obj.angles_rad, obj.angles_cpt(2, :));
shm_handle = compass([x2, x], [y2, y], 'Parent', h);

set(shm_handle(nb_sources+1:end), 'LineWidth', 4);
set(shm_handle(1:nb_sources), 'Color', 'red', 'LineWidth', 2);

hold(h, 'on');

x_lim = get(h, 'XLim');
x_lim = x_lim(2)+1;

for iAngle = 1:numel(obj.angles_rad)
    [x, y] = pol2cart(obj.angles_rad(iAngle), x_lim);
    text(x, y, num2str(iAngle), 'FontSize', 26, 'Parent', h);
end