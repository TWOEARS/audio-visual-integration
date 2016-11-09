% 'EnvironmentalMapKS' class
% This knowledge source aims at providing a representation of the internal representation of the environment
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

classdef EnvironmentalMapKS < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
	htm;
	RIR; % Robot_Internal_Representation class
	MOKS;
	
	figure_handle;
	fov_handle;
	fov_handle2;
	objects_handle;
	emitting_handle;
	robot_handle;
	shm_handle;
	naive_handle;

	statistics_handle;

	text_handle;

	depth_of_view;
	field_of_view;

	object_creation;

	sources = [];

	% angles;

	dmax = 1;
	h1;
	h2;
	h3;

	angles = [];
	angles_rad = [];
	angles_cpt = [];

end

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = EnvironmentalMapKS (htm)
	obj.htm = htm;
	obj.RIR = htm.RIR;
	obj.MOKS = htm.MOKS;

	obj.depth_of_view = 9;
	obj.field_of_view = 30;

	obj.createFigure();
	obj.drawSources();

	% obj.robot_position = RIR.position;

	obj.drawRobot();

	obj.drawFieldOfView('init');


	obj.emitting_handle = zeros(2, getInfo('nb_sources'));

	obj.text_handle = zeros(1, getInfo('nb_sources'));

	obj.shm_handle = zeros(1, getInfo('nb_sources'));

	obj.statistics_handle = zeros(1, 3);

	obj.drawMeanClassificationResults();

	obj.angles = getInfo('sources_position');
	obj.angles_rad = deg2rad(obj.angles);
	obj.angles_cpt = [zeros(1, numel(obj.angles_rad)) ; zeros(1, numel(obj.angles_rad))];
	obj.drawSHM('init');


end
% === CONSTRUCTOR [END] === %

function updateMap (obj)
	obj.drawEmittingSource();
	obj.drawFieldOfView('update');
	obj.drawSeenSources();
	obj.drawClassificationResults();
	obj.drawLocalizationResults();
	obj.drawMeanClassificationResults();
	obj.drawSHM('update');
end

function createFigure (obj)
	obj.figure_handle = axes();
	p = get(obj.figure_handle(), 'Parent');	
	set(p, 'units','normalized','outerposition', [0 0 1 1], 'Tag', 'EMKS');
	obj.h1 = subplot(6, 6, [1:4, 7:10, 13:16, 19:22, 25:28, 31:34], 'Parent', p);
	set(obj.h1, 'XLim', [-10, 10], 'YLim', [-10, 10], 'XTick', [], 'YTick', []);
	axis square;

	obj.h2 = subplot(6, 6, [5, 6, 11, 12, 17, 18])
	set(obj.h2, 'XLim', [0, obj.htm.nb_steps_final+20], 'YLim', [0, 1], 'Parent', p);
	axis square;

	obj.h3 = subplot(6, 6, [23, 24, 29, 30, 35, 36]);
	% set(obj.h3, 'XLim', [-10, 10], 'YLim', [-10, 10], 'XTick', [], 'YTick', []);
	axis square;
end

function endSimulation (obj)
	obj.drawFieldOfView('end');
	obj.drawLocalizationResults();
end

function drawClassificationResults (obj)
	iStep = obj.htm.iStep;
	iSource = obj.htm.sources(iStep);
	if iSource == 0
		return;
    end
    current_object = obj.htm.ODKS.id_object(end);
	l = getObject(obj.htm, current_object, 'label');
	g = obj.htm.gtruth{iStep, 1};
	if strcmp(l, g)
		set(obj.objects_handle(iSource), 'FaceColor', 'blue');
	else
		set(obj.objects_handle(iSource), 'FaceColor', 'red');
	end
end

function drawSeenSources (obj)
	head_position = obj.MOKS.head_position(end);
	for iSource = 1:numel(obj.objects_handle)
		source = find(head_position == getInfo('sources_position'));
		if ~isempty(source)
			set(obj.objects_handle(source), 'LineStyle', '-', 'LineWidth', 2);
			% if 
		end
	end

end

function drawLocalizationResults (obj)
	for iObject = 1:obj.htm.RIR.nb_objects
		tmIdx = getObject(obj.htm, iObject, 'tmIdx');
		tmIdx = tmIdx(1);
		current_theta = getObject(obj.htm, iObject, 'theta');
		current_theta = current_theta(end);

		source = obj.htm.sources(tmIdx);
		
		object_pos = get(obj.objects_handle(source), 'Position');
		
		x = object_pos(1)+object_pos(3);
		y = object_pos(2)+object_pos(4);
		
		if obj.text_handle(source) == 0
			obj.text_handle(source) = text(x+0.2, y+0.2, num2str(current_theta), 'FontSize', 16, 'FontWeight', 'bold', 'Parent', obj.h1);
		else
			set(obj.text_handle(source), 'Position', [x+0.2, y+0.2, 0], 'String', num2str(current_theta));
		end
	end
	% current_object = obj.htm.ODKS.id_object(end);
	% if current_object ~= 0
	% 	iSource = obj.htm.sources(obj.htm.iStep);
	% 	current_theta = getObject(obj.htm, current_object, 'theta');
	% 	current_theta = current_theta(end);
	% 	object_pos = get(obj.objects_handle(iSource), 'Position');
	% 	x = object_pos(1)+object_pos(3);
	% 	y = object_pos(2)+object_pos(4);
	% 	if obj.text_handle(iSource) == 0
	% 		obj.text_handle(iSource) = text(x+0.3, y+0.3, num2str(current_theta), 'FontSize', 12);
	% 	else
	% 		set(obj.text_handle(iSource), 'Position', [x+0.3, y+0.3, 0], 'String', num2str(current_theta));
	% 	end
	% end
	% current_audio_theta = obj.htm.ALKS.hyp_hist(end);
	% angles = getObject(obj.htm, 'all', 'theta');

end

function drawSources (obj, h)
	if nargin == 1
		h = obj.h1;
	end

	info = getInfo('all');
	for iSource = 1:info.nb_sources
		th = info.sources_position(iSource);
		d = info.distances(iSource);
		[x, y] = pol2cart(deg2rad(th), d);
		pos = [x-0.5, y-0.5, 1, 1];
		obj.objects_handle(end+1) = rectangle('Position' , pos ,...
			  		   			 			  'Curvature', 0.4 ,...
			  		   			 			  'LineWidth', 1   ,...
          									  'LineStyle', '--',...
          									  'FaceColor', [201, 230, 204]/255,...
			  		   			 			  'Parent'   , h...
			  		   			 			 );
		obj.sources(:, end+1) = pos;
	end
end

function drawRobot (obj)
	circle_size = 0.5;
	% --- Centering the center around [0, 0]
	% --- 'pos' is: [x, y, width, height]
	pos = [obj.RIR.position(1)-circle_size/2, obj.RIR.position(2)-circle_size/2,...
		   circle_size, circle_size];
	% --- The 'Curvature' is allowing to draw a circle from the 'rectangle' function
	obj.robot_handle = rectangle('Position' , pos  ,...
			  		   			 'Curvature', [1 1],...
			  		   			 'LineWidth', 2,...
			  		   			 'FaceColor', 'black',...
			  		   			 'Parent'   , obj.h1);
			  		   			 % 'Parent'   , obj.figure_handle);
	circle_size = 3;
	% --- Centering the center around [0, 0]
	% --- 'pos' is: [x, y, width, height]
	x0 = obj.RIR.position(1);
	y0 = obj.RIR.position(2);
	pos = [x0-circle_size/2, y0-circle_size/2, circle_size, circle_size];
	% --- The 'Curvature' is allowing to draw a circle from the 'rectangle' function
	obj.shm_handle = rectangle('Position' , pos  ,...
			  		   		   'Curvature', [1 1],...
			  		   		   'LineWidth', 2,...
			  		   		   'FaceColor', 'none',...
			  		   		   'Parent'   , obj.h1);
end


function drawFieldOfView (obj, k)

	if strcmp(k, 'init') || strcmp(k, 'end')
		x0 = obj.RIR.position(1);
		y0 = obj.RIR.position(2);
		theta1 = -(obj.field_of_view/2);
		theta2 = +(obj.field_of_view/2);
		[x1, y1] = pol2cart(deg2rad(theta1), obj.depth_of_view);
		[x2, y2] = pol2cart(deg2rad(theta2), obj.depth_of_view);

		% X1 = [x0, x1];
		% Y1 = [y0, y1];
		% X2 = [x0, x2];
		% Y2 = [y0, y2];

		if strcmp(k, 'init')
			l1 = line([x0, x1], [y0, y1], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h1);
			l2 = line([x1, x2], [y1, y2], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h1);
			l3 = line([x2, x0], [y2, y0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h1);
			
			obj.fov_handle = [l1, l2, l3];
			% hold on;
			% obj.fov_handle2(1) = area(X1, Y1);
			% obj.fov_handle2(2) = area(X2, Y2);
			% hold off;
		else
			set(obj.fov_handle(1), 'XData', [x0, x1], 'YData', [y0, y1]);
			set(obj.fov_handle(2), 'XData', [x1, x2], 'YData', [y1, y2]);
			set(obj.fov_handle(3), 'XData', [x2, x0], 'YData', [y2, y0]);
		end
		return;
	end

	if isempty(obj.MOKS.head_position)
		return;
	end

	% hold(obj.figure_handle, 'on');
	hold(obj.h1, 'off');
	
	x0 = obj.RIR.position(1);
	y0 = obj.RIR.position(2);
	
	theta1 = obj.MOKS.head_position(end) - (obj.field_of_view/2);
	theta2 = obj.MOKS.head_position(end) + (obj.field_of_view/2);

	[x1, y1] = pol2cart(deg2rad(theta1), obj.depth_of_view);
	[x2, y2] = pol2cart(deg2rad(theta2), obj.depth_of_view);
	
	set(obj.fov_handle(1), 'XData', [x0, x1], 'YData', [y0, y1]);
	set(obj.fov_handle(2), 'XData', [x1, x2], 'YData', [y1, y2]);
	set(obj.fov_handle(3), 'XData', [x2, x0], 'YData', [y2, y0]);

	% set(obj.fov_handle2(1), 'XData', [x0, x1], 'YData', [y0, y1]);
	% set(obj.fov_handle2(2), 'XData', [x0, x2], 'YData', [y0, y2]);
	% obj.fov_handle = [l1, l2, l3];
	
	% hold(obj.figure_handle, 'off');
	hold(obj.h1, 'off');
	
	pause(0.1);
end

function drawEmittingSource (obj)
	iSource = obj.htm.sources(obj.htm.iStep);
	if iSource == 0
		obj.removeEmittingSources();
	else
		info = getInfo('all');
		circle_size = 2;
		circle_size2 = 3;
		% --- Centering the center around [0, 0]
		% --- 'pos' is: [x, y, width, height]
		pos1 = [obj.sources(1, iSource)-circle_size/4, obj.sources(2, iSource)-circle_size/4,...
			   circle_size, circle_size];
		pos2 = [obj.sources(1, iSource)-circle_size2/3, obj.sources(2, iSource)-circle_size2/3,...
			   circle_size2, circle_size2];
		% --- The 'Curvature' is allowing to draw a circle from the 'rectangle' function
		if obj.emitting_handle(1, iSource) == 0
			h1 = rectangle('Position' , pos1  ,...
						  'Curvature', [1 1],...
						  'LineStyle', '-.',...
						  'EdgeColor', [51, 102, 0]/255,...
					  	  'Parent'   , obj.h1,...
					  	  'Tag', num2str(iSource));
			h2 = rectangle('Position' , pos2  ,...
						  'Curvature', [1 1],...
						  'LineStyle', '-.',...
						  'EdgeColor', [51, 102, 0]/255,...
					  	  'Parent'   , obj.h1,...
					  	  'Tag', num2str(iSource));

			obj.emitting_handle(1, iSource) = h1;
			obj.emitting_handle(2, iSource) = h2;
		else
			set(obj.emitting_handle(1, iSource), 'Visible', 'on');
			set(obj.emitting_handle(2, iSource), 'Visible', 'on');
		end
	end
end

function removeEmittingSources (obj)
	for iSource = 1:size(obj.emitting_handle, 2)
		% if ~isempty(obj.emitting_handle)
		if obj.emitting_handle(1, iSource) ~= 0
			set(obj.emitting_handle(1, iSource), 'Visible', 'off');
			set(obj.emitting_handle(2, iSource), 'Visible', 'off');
		end
	end
end

function drawMeanClassificationResults (obj)
	RIR = obj.htm.RIR;
	iStep = obj.htm.iStep;

	cpt21 = zeros(iStep, 1);
    cpt22 = zeros(iStep, 1);
    
    cpt21 = strcmp(obj.htm.classif_mfi(1:iStep), obj.htm.gtruth(1:iStep, 1));
    
    cpt22 = cumsum(cpt21) ./ (1:iStep)';

    % statistics.max_mean_shm = cumsum(obj.htm.statistics.max_shm(1:iStep)) ./ (1:iStep)';

    % statistics = htm.statistics;
    
    % cpt21 = statistics.mfi(1:iStep);
    % cpt22 = statistics.mfi_mean(1:iStep);
    cpt11 = obj.htm.statistics.max(1:iStep);
    cpt12 = obj.htm.statistics.max_mean(1:iStep);

    correct = zeros(RIR.nb_objects, 1);
    correct2 = zeros(RIR.nb_objects, 1);
    for iObj = 1:RIR.nb_objects
        % --- If object focused -> system had access to whole data
        % if getObject(RIR, iObj, 'theta') == 0
            data = retrieveObservedData(RIR, iObj);

            audio_data = data(1:getInfo('nb_audio_labels'), :);
            visual_data = data(getInfo('nb_audio_labels')+1:end, :);

            idx_audio = find(sum(audio_data) == 0, 1, 'last');
            idx_vision = find(sum(visual_data) == 0, 1, 'last');

            tmIdx = getObject(RIR, iObj, 'tmIdx');
            if ~isempty(idx_audio)
                t = tmIdx(idx_audio);
            else
                t = tmIdx(1);
            end

            if ~isempty(idx_vision)
                % tidx = RIR.getObj(iObj).tmIdx(idx_vision) ;
                t = tmIdx(idx_vision);
            else
                t = tmIdx(1);
            end

            % --- Statistics MAX
            if mean(cpt21(tmIdx(1):t)) > 0.5
                correct(iObj) = 1;
            else
                correct(iObj) = -1;
            end
            % --- Statistics MEAN(MAX)
            if mean(cpt11(tmIdx(1):t)) >= 0.5
                correct2(iObj) = 1;
            else
                correct2(iObj) = -1;
            end
        % end
    end

    % correct(p.Objects(1):p.Objects(end))

    C_0 = [0.2, 0.2, 0.2];
    C_1 = [0.4, 0.4, 0.4];
    C_2 = [0.75, 0.75, 0.75];
    C_3 = [1, 1, 1];

    % figure ;
    hold(obj.h2, 'on');

    % if p.Rect
    %     for iObj = 1:RIR.nb_objects
    %         tmIdx = getObject(RIR, iObj, 'tmIdx');
    %         x = tmIdx(1);
    %         X = [x, x, x+getInfo('cpt_object'), x+getInfo('cpt_object')];
    %         if p.Max
    %             Y1 = [0.5, 1, 1, 0.5];
    %         else
    %             Y1 = [0, 1, 1, 0];
    %         end
    %         Y2 = [0, 0.5, 0.5, 0];

    %         if correct(iObj) == -1
    %             C1 = C_0;
    %         elseif correct(iObj) == 1
    %             data = getData(htm, iObj);
    %             if sum(data(getInfo('nb_audio_labels')+1:end, 3)) > 0
    %                 C1 = C_2;
    %             else
    %                 C1 = C_3;
    %             end
    %         end

    %         if correct2(iObj) == -1
    %             C2 = C_0;
    %         elseif correct2(iObj) == 1
    %             C2 = C_2;
    %         else
    %             C2 = C_3;
    %         end

    %         if p.MFI
    %             h1 = patch(X, Y1, C1);%, 'FaceAlpha', 0.6) ;
    %         end
    %         if p.Max
    %             h2 = patch(X, Y2, C2);%, 'FaceAlpha', 0.6) ;
    %         end
    %         if all(C1 == C_3)
    %             % hp = findobj(h,'type','patch');
    %             % hatch(h1, 45, [0.5, 0.5, 0.5], '-', 12, 2) ;
    %         end
    %     end
    % end

    % if p.Curv
    if ~isempty(cpt22)
	    if sum(obj.statistics_handle(1)) == 0 
	        h1 = plot(cpt22(1:end)                  ,...
	                'LineWidth', 4             ,...
	                'LineStyle', '-'           ,...
	                'Color'    , [0.1, 0.1, 0.1],...
	                'Parent', obj.h2...
	            );
	        obj.statistics_handle(1) = h1;
	        h2 = plot(cpt12(1:end)                  ,...
	                'LineWidth', 4             ,...
	                'LineStyle', '-'           ,...
	                'Color'    , [0.6, 0.6, 0.6],...
	                'Parent', obj.h2...
	            );
	        obj.statistics_handle(2) = h2;
	        h3 = plot(obj.htm.statistics.max_mean_shm(1:iStep),...
	             'LineWidth', 4,...
	             'LineStyle', '-',...
	             'Color', [0.8, 0.8, 0.8],...
	                'Parent', obj.h2...
	                );
	        obj.statistics_handle(3) = h3;
	    else
	    	pdata = get(obj.statistics_handle(1), 'YData');
	    	set(obj.statistics_handle(1), 'XData', 1:iStep, 'YData', [pdata, cpt22(end)]);
	    	pdata = get(obj.statistics_handle(2), 'YData');
	    	set(obj.statistics_handle(2),'XData', 1:iStep, 'YData', [pdata, cpt12(end)]);
	    	pdata = get(obj.statistics_handle(3), 'YData');
	    	set(obj.statistics_handle(3),'XData', 1:iStep, 'YData', [pdata, obj.htm.statistics.max_mean_shm(iStep)]);
	    end
	end
    % end

    legend({'HTMmodel', 'Naive robot'});
    hold(obj.h2, 'off');


    % lim = [0, obj.htm.nb_steps_final];
    % if sum(p.Objects) == 0
    %     if sum(p.Lim) == 0
    %         if p.MinLim == 0
    %             lim(1) = 1;
    %         else
    %             lim(1) = p.MinLim-10;
    %         end
    %         if p.MaxLim == 0
    %             lim(2) = numel(cpt12)+10;
    %         else
    %             lim(2) = p.MaxLim+10;
    %         end
    %     else
    %         lim = p.Lim;
    %     end
    % else
    %     tmIdx = getObject(RIR, p.Objects(1), 'tmIdx');
    %     lim(1) = tmIdx(1)-20;
    %     lim(2) = tmIdx(end)+20;
    % end
end


function drawSHM (obj, k)

	if strcmp(k, 'init')
		[x, y] = pol2cart(obj.angles_rad, obj.angles_cpt(1, :));
		obj.shm_handle = compass([x, x], [y, y], 'Parent', obj.h3);
		% obj.naive_handle = compass(x, y, 'Parent', obj.h3);

	elseif strcmp(k, 'update')
		% source = obj.htm.sources(iStep);
		% if source == 1
		mo = obj.htm.MOKS.motor_order(obj.htm.iStep);
		if mo > 0
			pos = find(obj.angles == mo);
			obj.angles_cpt(1, pos) = obj.angles_cpt(1, pos) + 1;
		end
		[x, y] = pol2cart(obj.angles_rad, obj.angles_cpt(1, :));
		
		iStep = obj.htm.iStep;
		if iStep > 1
			tmp = obj.htm.sources(iStep-1:iStep);
			if tmp(2)-tmp(1) > 1
				obj.angles_cpt(2, tmp(2)) = obj.angles_cpt(2, tmp(2)) + 1;
			end
			% hold on;
			[x2, y2] = pol2cart(obj.angles_rad, obj.angles_cpt(2, :));
			% obj.naive_handle = compass(x, y, 'red');
			% set(obj.naive_handle(:), 'LineWidth', 1);
			
			nb_sources = getInfo('nb_sources');
			obj.shm_handle = compass([x2, x], [y2, y], 'Parent', obj.h3);
			set(obj.shm_handle(nb_sources+1:end), 'LineWidth', 4);
			set(obj.shm_handle(1:nb_sources), 'Color', 'red', 'LineWidth', 2);
			% hold off;
		end
		%legend({'HTMKS', 'Naive robot'});%, 'Color', {'blue', 'red'});

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