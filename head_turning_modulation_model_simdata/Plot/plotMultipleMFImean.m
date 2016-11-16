function plotMultipleMFImean(varargin)
	
h_fig = figure;
set(h_fig, 'Color', [1, 1, 1]);
subplot(6, 6, [1:4, 7:10, 13:16, 19:22, 25:28, 31:34]);
axis square;
hold on;
K = [0, 0.5, 1];
C = [0  , 0  , 153 ;...
	 0  , 102, 204 ;...
	 102, 178, 255]/255;

sp = 3;
m = numel(varargin{1}.statistics.mfi_mean);

epsilon = getInfo('epsilon');
line([1, numel(varargin{1}.statistics.mfi_mean)], [1-epsilon 1-epsilon],...
	 'Color', 'k',...
	 'LineWidth', 2,...
	 'LineStyle', ':');

htm = varargin{1};

plot(htm.statistics.max_mean,...
	'LineWidth', 3,...
	'LineStyle', '-.',...
	'Color', [0.6, 0.6, 0.6]);

v = htm.statistics.max_mean(end);
text(m+sp, v, ['\leftarrow y^{max}_{t=500}=', num2str(v)], 'FontSize', 14);

plot(htm.statistics.max_mean_shm,...
	'LineWidth', 3,...
	'LineStyle', '--',...
	'Color', [0.3, 0.3, 0.3]);

v = htm.statistics.max_mean_shm(end);
text(m+sp, v, ['\leftarrow y^{max}_{t=500}=', num2str(v)], 'FontSize', 14);


for iHtm = 1:numel(varargin)
	htm = varargin{iHtm};
	plot(htm.statistics.mfi_mean,...
		'LineWidth', 4             ,...
		'LineStyle', '-'           ,...
		'Color'    , C(iHtm, :));
	v = htm.statistics.mfi_mean(end);
	text(m+sp, v,...
		 ['\leftarrow y^{K=', num2str(K(iHtm)), '}_{t=500}=', num2str(v)],...
		 'FontSize', 14);
end

h_leg = legend(...
			   '1-\epsilon=0.65',...
			   'Fusion_{SHM}^{max}',...
			   'Fusion_{noSHM}^{max}',...
			   'K_{head}^{0.0}',...
			   'K_{head}^{0.5}',...
			   'K_{head}^{1.0}');

line([500, 500], [0 1], 'Color', 'k', 'LineWidth', 1, 'LineStyle', ':');

xlabel('time steps');
ylabel('rates')

set(gca, 'Ylim', [0, 1], 'FontSize', 16, 'box', 'on');


set(h_leg, 'FontSize', 16, 'location', 'southeast');





% ================
% ================
% ================

c = [5, 6, 11, 12 ;...
	 17, 18, 23, 24 ;...
	 29, 30, 35, 36];
for iHtm = 1:numel(varargin)
	subplot(6, 6, c(iHtm, :));
	htm = varargin{iHtm};
	nb_sources = size(htm.EMKS.sources, 2);
    angles_cpt = zeros(2, nb_sources);
    angles = htm.EMKS.angles;
    angles_rad = deg2rad(angles);

    for iStep = 2:htm.nb_steps_final
        mo = htm.MOKS.motor_order(iStep);
        if mo > 0
            pos = find(angles == mo);
            angles_cpt(1, pos) = angles_cpt(1, pos) +  1;
        end
        
        tmp = htm.sources(iStep-1:iStep);
        if tmp(2)-tmp(1) > 1
            angles_cpt(2, tmp(2)) = angles_cpt(2, tmp(2)) + 1;
        end
    end
    [x, y] = pol2cart(angles_rad, angles_cpt(1, :));
    [x2, y2] = pol2cart(angles_rad, angles_cpt(2, :));

    % h_fig = figure;
    % set(h_fig, 'Color', [1, 1, 1]);

    h = compass([x2, x], [y2, y]);
    set(h(nb_sources+1:end), 'LineWidth', 6);
    set(h(1:nb_sources), 'Color', 'red', 'LineWidth', 3);
    
    % set(get(h(1), 'Parent'), 'FontSize', 60);
    title(['K_{head}^{', num2str(K(iHtm)), '}']);
    % text(10, 12, ['K_{head}^{', num2str(K(iHtm)), '}'], 'FontSize', 15);
    text(10, 9, ['n_{SHM}^{K=', num2str(K(iHtm)), '}=', num2str(htm.MOKS.shm)], 'FontSize', 15);
end

end