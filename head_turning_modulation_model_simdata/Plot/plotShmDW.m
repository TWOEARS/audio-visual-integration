function plotShmDW (angles_cpt, angles_rad)

nb_sources = numel(angles_rad);
% nb_sources = getInfo('nb_sources');
% angles_rad = deg2rad(getInfo('sources_position'));


figure('Color', 'white');
% h = axes('FontSize', 16);
h = subplot(1, 5, 1:4);

[x, y] = pol2cart(angles_rad, angles_cpt(1, :));
shm_handle = compass([x, x], [y, y], 'Parent', h);

[x2, y2] = pol2cart(angles_rad, angles_cpt(2, :));
shm_handle = compass([x2, x], [y2, y], 'Parent', h);

set(shm_handle(nb_sources+1:end), 'LineWidth', 5);
set(shm_handle(1:nb_sources), 'Color', 'red', 'LineWidth',3);

hold(h, 'on');
x_lim = get(h, 'XLim');
a = 1.3;
x_lim = x_lim(2)+a;

for iAngle = 1:numel(angles_rad)
	if iAngle == 2
    	[x, y] = pol2cart(angles_rad(iAngle)-0.05, x_lim);
    else
    	[x, y] = pol2cart(angles_rad(iAngle), x_lim);
    end
    text(x, y, num2str(iAngle), 'FontSize', 26, 'Color', [0, 0.8, 1], 'Parent', h);
    [x, y] = pol2cart(angles_rad(iAngle), x_lim-a);
    plot(x, y, '*', 'MarkerSize', 10, 'Color', [0, 0.8, 1], 'Parent', h);
end

ht = findall(h, 'Type', 'Text');

for iHandle = nb_sources+13:numel(ht)
	set(ht(iHandle), 'Color', [0, 0, 1], 'FontSize', 30);
end

for iHandle = nb_sources+1:nb_sources+12
	set(ht(iHandle), 'FontSize', 18);
end

% figure('Color', 'white');
% ha = axes();
ha = subplot(1, 5, 5);
hold on;
h(1) = bar(1, sum(angles_cpt(1, :)'));
h(2) = bar(2, sum(angles_cpt(2, :)'));
set(h(2), 'FaceColor', 'red', 'EdgeColor', 'none')
set(h(1), 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none')
set(ha, 'FontSize', 20, 'XTick', [1, 2], 'XTickLabels', '', 'XLim', [0.7, 2.3])

