classdef EnvironmentalMapKS < handle
% EnvironmentalMapKS class
% This knowledge source aims at providing a representation of the internal representation of the environment
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
	htm;
	RIR; % Robot_Internal_Representation class
	MOKS;
	
	figure_handle;
	fov_handle;
	fov_handle_naive;
	objects_handle;
	emitting_handle;
	robot_handle;
	shm_handle;
	naive_handle;
    hist_handle;

	statistics_handle;
	hl;
	tl_handle;

	text_handle;

	depth_of_view;
	field_of_view;

	object_creation;

	sources = [];
    nb_sources = 0;
    timeline;
    
    emitting_sources = [];

	% angles;

	dmax = 1;
	h1;
	h2;
	h3;

	angles = [];
	angles_rad = [];
	angles_cpt = [];

	iStep;

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
    obj.nb_sources = getInfo('nb_sources');
    obj.timeline = getInfo('timeline');
    

	obj.createFigure();
	obj.drawSources();
    obj.drawHistograms('init');

	% obj.robot_position = RIR.position;

	obj.drawRobot();

	obj.drawFieldOfView('init');

	obj.emitting_handle = zeros(2, getInfo('nb_sources'));

	obj.text_handle = zeros(1, getInfo('nb_sources'));

	obj.tl_handle = zeros(1, 3);

	obj.shm_handle = zeros(1, getInfo('nb_sources'));

	obj.statistics_handle = zeros(1, 3);

	obj.drawMeanClassificationResults();

	obj.angles = getInfo('sources_position');
	obj.angles_rad = deg2rad(obj.angles);
	obj.angles_cpt = [zeros(1, numel(obj.angles_rad)) ; zeros(1, numel(obj.angles_rad))];
	obj.drawSHM('init');

	% obj.drawSilence();

end
% === CONSTRUCTOR [END] === %

function updateMap (obj)
	obj.iStep = obj.htm.iStep;
    timeline = obj.timeline;
	sources = zeros(1, obj.nb_sources);
	for iSource = 1:obj.nb_sources
		tmp = find(timeline{iSource} <= obj.iStep, 1, 'last');
		if ~isempty(tmp) && mod(tmp, 2) == 0
			sources(iSource) = 1;
		end
    end
    obj.emitting_sources = sources;
	obj.drawLocalizationResults();
	obj.drawEmittingSource();
	obj.drawFieldOfView('update');
	obj.drawSeenSources();
	obj.drawClassificationResults();
	obj.drawMeanClassificationResults();
	obj.drawHistograms('update');
	if obj.iStep > 2
		obj.drawSHM('update');
	end
	pause(0.01);
end

function createFigure (obj)
	obj.figure_handle = axes();
	p = get(obj.figure_handle(), 'Parent');	
	set(p, 'Units', 'Normalized',...
		   'Outerposition', [0 0 1 1],...
		   'Tag', 'EMKS');
	obj.h1 = subplot(6, 6, [1:4, 7:10, 13:16, 19:22, 25:28, 31:34], 'Parent', p);
	set(obj.h1, 'XLim', [-11, 11],...
				'YLim', [-11, 11],...
				'Position', [0.01, 0.1, 0.6, 0.8]);%, 'XTick', [], 'YTick', []);
	% set(htm.EMKS.h1, 'Position', [0, 0.11, 0.5, 0.8150])
	axis off;
	axis square;

	obj.h2 = subplot(6, 6, [5, 6, 11, 12, 17, 18]);
	set(obj.h2, 'XLim', [0, obj.htm.nb_steps_final+20],...
				'YLim', [0, 1],...
				'Position', [0.52, 0.5374, 0.6, 0.45],...
				'Parent', p);
	axis square;

	obj.h3 = subplot(6, 6, [23, 24, 29, 30, 35, 36]);
	set(obj.h3, 'Position', [0.52, 0.05, 0.6, 0.45]);
	axis square;
end

function drawClassificationResults (obj)
	%sources = obj.emitting_sources;
    if obj.htm.RIR.nb_objects == 0,
        return;
    end
	objects = getLastHypothesis(obj, 'ODKS', 'id_object');
    
    for iSource = 1:obj.nb_sources
        if objects(iSource) ~= 0
	        current_object = objects(iSource);
	        l = getObject(obj, current_object, 'label');
	        g = obj.htm.gtruth{iSource}{obj.iStep, 1};
	        if strcmp(l, g)
	            set(obj.objects_handle(iSource), 'FaceColor', 'blue');
	        else
	            set(obj.objects_handle(iSource), 'FaceColor', 'red');
	        end
	    end
    end
end

function drawLocalizationResults (obj)
	for iObject = 1:obj.htm.RIR.nb_objects
		object = getObject(obj, iObject);
		% tmIdx = getObject(obj.htm, iObject, 'tmIdx');
		tmIdx = object.tmIdx(1);
		% current_theta = getObject(obj, iObject, 'theta');
		current_theta = object.theta(end);

		%source = obj.htm.sources(tmIdx);
        % source = getObject(obj, iObject, 'source');
        source = object.source;
		
		object_pos = get(obj.objects_handle(source), 'Position');
		
		x = object_pos(1)+object_pos(3);
		y = object_pos(2)+object_pos(4);
		
		if obj.text_handle(source) == 0
			obj.text_handle(source) = text(x+0.2, y+0.2, num2str(current_theta),...
										   'FontSize', 16,...
										   'FontWeight', 'bold',...
										   'Parent', obj.h1);
		else
			set(obj.text_handle(source), 'Position', [x+0.2, y+0.2, 0],...
										 'String', [num2str(current_theta), '^\circ']);
		end
	end
end


function drawFieldOfView (obj, k)

	if strcmp(k, 'init') || strcmp(k, 'end')
		x0 = obj.RIR.position(1);
		y0 = obj.RIR.position(2);
		theta1 = -(obj.field_of_view/2);
		theta2 = +(obj.field_of_view/2);
		[x1, y1] = pol2cart(deg2rad(theta1), obj.depth_of_view);
		[x2, y2] = pol2cart(deg2rad(theta2), obj.depth_of_view);

		if strcmp(k, 'init')
			% === Naive robot
			l1 = line([x0, x1], [y0, y1], 'Color', 'g', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h1);
			l2 = line([x1, x2], [y1, y2], 'Color', 'g', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h1);
			l3 = line([x2, x0], [y2, y0], 'Color', 'g', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h1);
			obj.fov_handle_naive = [l1, l2, l3];

			% === HTM robot
			l1 = line([x0, x1], [y0, y1], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h1);
			l2 = line([x1, x2], [y1, y2], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h1);
			l3 = line([x2, x0], [y2, y0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h1);
			
			obj.fov_handle = [l1, l2, l3];
		else
			set(obj.fov_handle(1), 'XData', [x0, x1], 'YData', [y0, y1]);
			set(obj.fov_handle(2), 'XData', [x1, x2], 'YData', [y1, y2]);
			set(obj.fov_handle(3), 'XData', [x2, x0], 'YData', [y2, y0]);

			set(obj.fov_handle_naive(1), 'XData', [x0, x1], 'YData', [y0, y1]);
			set(obj.fov_handle_naive(2), 'XData', [x1, x2], 'YData', [y1, y2]);
			set(obj.fov_handle_naive(3), 'XData', [x2, x0], 'YData', [y2, y0]);
		end
	else
		% hold(obj.h1, 'on');
		x0 = obj.RIR.position(1);
		y0 = obj.RIR.position(2);

		% === Naive robot
		if ~isempty(obj.htm.naive_shm)
			naive_shm = obj.htm.naive_shm{end};
	        if ~isempty(naive_shm)
	            sources = getObject(obj, naive_shm, 'source');
	            % obj.angles_cpt(2, sources) = obj.angles_cpt(2, sources) + 1;

	            theta  = obj.angles(sources);
	            % [x2, y2] = pol2cart(obj.angles_rad, obj.angles_cpt(2, :));

				theta1 = theta - (obj.field_of_view/2);
				theta2 = theta + (obj.field_of_view/2);

				[x1, y1] = pol2cart(deg2rad(theta1), obj.depth_of_view);
				[x2, y2] = pol2cart(deg2rad(theta2), obj.depth_of_view);

				set(obj.fov_handle_naive(1), 'XData', [x0, x1], 'YData', [y0, y1]);
				set(obj.fov_handle_naive(2), 'XData', [x1, x2], 'YData', [y1, y2]);
				set(obj.fov_handle_naive(3), 'XData', [x2, x0], 'YData', [y2, y0]);

	        end
	    end

	    % === HTM robot
		if ~isempty(obj.MOKS.head_position)
			theta1 = obj.MOKS.head_position(end) - (obj.field_of_view/2);
			theta2 = obj.MOKS.head_position(end) + (obj.field_of_view/2);

			[x1, y1] = pol2cart(deg2rad(theta1), obj.depth_of_view);
			[x2, y2] = pol2cart(deg2rad(theta2), obj.depth_of_view);
			
			set(obj.fov_handle(1), 'XData', [x0, x1], 'YData', [y0, y1]);
			set(obj.fov_handle(2), 'XData', [x1, x2], 'YData', [y1, y2]);
			set(obj.fov_handle(3), 'XData', [x2, x0], 'YData', [y2, y0]);
		end
		% hold(obj.h1, 'off');
	end
	pause(0.01);
end

function drawMeanClassificationResults (obj)
	if obj.iStep == 0
		return;
	end
    if sum(obj.statistics_handle(1)) == 0 || obj.iStep <= 1
    	% hold(obj.h2, 'on');

        obj.statistics_handle(1) = plot(obj.htm.statistics.mfi_mean(1, end),...
					                    'LineWidth', 4             ,...
					                    'LineStyle', '-'           ,...
					                    'Color'    , [0.1, 0.1, 0.1],...
					                    'Parent'   , obj.h2);
        obj.hl(1) = line([1, 1], [obj.htm.statistics.mfi_mean(1, end), obj.htm.statistics.mfi_mean(1, end)],...
                                 'Color', [0.1, 0.1, 0.1],...
                                 'LineWidth', 3,...
	                             'LineStyle', ':',...
	                             'Parent', obj.h2);

        obj.statistics_handle(2) = plot(obj.htm.statistics.max_mean(1),...
					                    'LineWidth', 4             ,...
					                    'LineStyle', '-'           ,...
					                    'Color'    , [0.6, 0.6, 0.6],...
					                    'Parent'   , obj.h2);
        obj.hl(2) = line([1, 1], [obj.htm.statistics.max_mean(1), obj.htm.statistics.max_mean(1)],...
	                             'Color', [0.6, 0.6, 0.6],...
                                 'LineWidth', 3,...
	                             'LineStyle', ':',...
	                             'Parent', obj.h2);

        obj.statistics_handle(3) = plot(obj.htm.statistics.max_mean_shm(1),...
						                'LineWidth', 4,...
						                'LineStyle', '-',...
						                'Color'    , [0.8, 0.8, 0.8],...
						                'Parent'   , obj.h2);
        obj.hl(3) = line([1, 1], [obj.htm.statistics.max_mean_shm(1), obj.htm.statistics.max_mean_shm(1)],...
                            	 'Color', [0.8, 0.8, 0.8],...
                                 'LineWidth', 3,...
                            	 'LineStyle', ':',...
                            	 'Parent', obj.h2);


        obj.tl_handle(1) = text(5, obj.htm.statistics.mfi_mean(1)+0.02,...
        						num2str(obj.htm.statistics.mfi_mean(1)),...
        						'Parent', obj.h2);
        obj.tl_handle(2) = text(5, obj.htm.statistics.max_mean(1)+0.02,...
        						num2str(obj.htm.statistics.max_mean(1)),...
        						'Parent', obj.h2);
		obj.tl_handle(3) = text(5, obj.htm.statistics.max_mean_shm(1)+0.02,...
								num2str(obj.htm.statistics.max_mean_shm(1)),...
								'Parent', obj.h2);


    	% hold(obj.h2, 'off');
    else
    	data1 = obj.htm.statistics.mfi_mean(obj.iStep-1, end);
    	data2 = obj.htm.statistics.max_mean(obj.iStep-1, end);
    	data3 = obj.htm.statistics.max_mean_shm(obj.iStep-1, end);

		set(obj.statistics_handle(1), 'XData', 1:obj.iStep-1, 'YData', obj.htm.statistics.mfi_mean(1:obj.iStep-1, end));
    	set(obj.hl(1), 'XData', [1, obj.iStep-1], 'YData', [data1, data1]);

    	set(obj.statistics_handle(2),'XData', 1:obj.iStep-1, 'YData', obj.htm.statistics.max_mean(1:obj.iStep-1, end));
    	set(obj.hl(2), 'XData', [1, obj.iStep-1], 'YData', [data2, data2]);

		set(obj.statistics_handle(3),'XData', 1:obj.iStep-1, 'YData', obj.htm.statistics.max_mean_shm(1:obj.iStep-1, end));
    	set(obj.hl(3), 'XData', [1, obj.iStep-1], 'YData', [data3, data3]);


    	str = num2str(data1);
    	tmp = strfind(str, '.');
		if numel(str) > 3
    		str = str(1:tmp+2);
    	else
    		str = str(1:tmp+1);
    	end
        set(obj.tl_handle(1), 'Position', [5, data1+0.02, 0],...
        					  'String'  , [str,'%']);

        str = num2str(data2);
    	tmp = strfind(str, '.');
    	tt = min([numel(str), 4])
    	% if numel(str) > 4
    		str = str(1:tt);
    	% else
    	% 	str = str(1:tmp+1);
    	% end
		set(obj.tl_handle(2), 'Position', [5, data2+0.02, 0],...
							  'String'  , [str,'%']);

    	str = num2str(data3);
    	tmp = strfind(str, '.');
    	if numel(str) > 3
    		str = str(1:tmp+2);
    	else
    		str = str(1:tmp+1);
    	end
    	set(obj.tl_handle(3), 'Position', [5, data3+0.02, 0],...
    						  'String'  , [str,'%']);

    end

end

function drawSHM (obj, k)
	if strcmp(k, 'init')
		[x, y] = pol2cart(obj.angles_rad, obj.angles_cpt(1, :));
		obj.shm_handle = compass([x, x], [y, y], 'Parent', obj.h3);

	elseif strcmp(k, 'update')
		mo = obj.MOKS.motor_order(obj.iStep-1);
        fo = obj.htm.FCKS.focus(obj.iStep-1);
		if mo > 0
			%pos = find(obj.angles == mo);
            pos = getObject(obj, fo, 'source');
			obj.angles_cpt(1, pos) = obj.angles_cpt(1, pos) + 1;
		end
		[x, y] = pol2cart(obj.angles_rad, obj.angles_cpt(1, :));
		
		naive_shm = obj.htm.naive_shm{end};
        if ~isempty(naive_shm)
            sources = getObject(obj, naive_shm, 'source');
            obj.angles_cpt(2, sources) = obj.angles_cpt(2, sources) + 1;

            [x2, y2] = pol2cart(obj.angles_rad, obj.angles_cpt(2, :));

            obj.shm_handle = compass([x2, x], [y2, y], 'Parent', obj.h3);
            set(obj.shm_handle(obj.nb_sources+1:end), 'LineWidth', 4);
            set(obj.shm_handle(1:obj.nb_sources), 'Color', 'red', 'LineWidth', 2);
        end

        pause(0.01);
	end
end

function drawHistograms (obj, k)
    if strcmp(k, 'init')
        for iSource = 1:obj.nb_sources
            h = obj.objects_handle(iSource);
            pos = get(h, 'Position');
            x = pos(1);
            y = pos(2)+pos(4);
            new_pos = [x, y, 0.32, 1];
            obj.hist_handle(1, end+1) = rectangle('Position' , new_pos,...
                                                  'Curvature', 0.1 ,...
                                              	  'LineWidth', 1   ,...
                                                  'LineStyle', 'none',...
                                                  'FaceColor', [0.2, 0.2, 0.2],...
                                                  'Visible'  , 'off',...
                                                  'Parent'   , obj.h1);
            new_pos = [x+0.33, y, 0.32, 1];
            obj.hist_handle(2, end) = rectangle('Position' , new_pos,...
                                                'Curvature', 0.1 ,...
                                                'LineWidth', 1   ,...
                                                'LineStyle', 'none',...
                                                'FaceColor', [0.6, 0.6, 0.6],...
                                                'Visible'  , 'off',...
                                                'Parent'   , obj.h1);
            new_pos = [x+0.66, y, 0.32, 1];
            obj.hist_handle(3, end) = rectangle('Position' , new_pos,...
                                                'Curvature', 0.1 ,...
                                                'LineWidth', 1   ,...
                                                'LineStyle', 'none',...
                                                'FaceColor', [0.8, 0.8, 0.8],...
                                                'Visible'  , 'off',...
                                                'Parent'   , obj.h1);
            % ===
            new_pos = [x, pos(2), 0.32, 1];
            obj.hist_handle(4, end) = rectangle('Position' , new_pos,...
                                                'Curvature', 0.1 ,...
                                                'LineWidth', 1   ,...
                                                'LineStyle', 'none',...
                                                'FaceColor', [0.2, 0.2, 0.2],...
                                                'Visible'  , 'off',...
                                                'Parent'   , obj.h1);
            new_pos = [x+0.33, pos(2), 0.32, 1];
            obj.hist_handle(5, end) = rectangle('Position' , new_pos,...
                                                'Curvature', 0.1 ,...
                                                'LineWidth', 1   ,...
                                                'LineStyle', 'none',...
                                                'FaceColor', [0.6, 0.6, 0.6],...
                                                'Visible'  , 'off',...
                                                'Parent'   , obj.h1);
            new_pos = [x+0.66, pos(2), 0.32, 1];
            obj.hist_handle(6, end) = rectangle('Position' , new_pos,...
                                                'Curvature', 0.1 ,...
                                                'LineWidth', 1   ,...
                                                'LineStyle', 'none',...
                                                'FaceColor', [0.8, 0.8, 0.8],...
                                                'Visible'  , 'off',...
                                                'Parent'   , obj.h1);
        end
    else
        nb_objects = obj.htm.RIR.nb_objects;
        for iObject = 1:nb_objects
            iSource = getObject(obj, iObject, 'source');
            pos = get(obj.hist_handle(1, iSource), 'Position');
            % x = pos(1);
            % y = pos(2);%+pos(4);

            y_end = 2*obj.htm.statistics.mfi_mean(obj.iStep-1, iSource);
            new_pos = [pos(1), pos(2), 0.32, y_end];
            set(obj.hist_handle(1, iSource), 'Position', new_pos, 'Visible', 'on');
            
            y_end = 2*obj.htm.statistics.max_mean(obj.iStep-1, iSource);
            new_pos = [pos(1)+0.33, pos(2), 0.32, y_end];
            set(obj.hist_handle(2, iSource), 'Position', new_pos, 'Visible', 'on');
            
            y_end = 2*obj.htm.statistics.max_mean_shm(obj.iStep-1, iSource);
            new_pos = [pos(1)+0.66, pos(2), 0.32, y_end];
            set(obj.hist_handle(3, iSource), 'Position', new_pos, 'Visible', 'on');

            % ===

			% avcat = getObject(obj, iObject, 'audiovisual_category');
			avcat = getCategory(obj, iObject, 'Object');
            y_end = 1;
            new_pos = [pos(1), pos(2)-1-y_end, 0.32, y_end];
            set(obj.hist_handle(4, iSource), 'Position', new_pos, 'Visible', 'on');

            y_end = 1/(avcat.nb_inf/avcat.nb_goodInf);
            if isinf(y_end) || isnan(y_end), y_end = 0; end
            new_pos = [pos(1)+0.33, pos(2)-1-y_end, 0.32, y_end];
            set(obj.hist_handle(5, iSource), 'Position', new_pos, 'Visible', 'on');

            new_pos = [pos(1)+0.66, pos(2)-1-avcat.perf, 0.32, avcat.perf];
            set(obj.hist_handle(6, iSource), 'Position', new_pos, 'Visible', 'on');
        end
    end
end


function drawEmittingSource (obj, varargin)
    sources = obj.emitting_sources;
	for iSource = 1:obj.nb_sources

		if sources(iSource) == 0
			obj.removeEmittingSources(iSource);
		else
			%info = getInfo('all');
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

function drawSources (obj, h)
	if nargin == 1
		h = obj.h1;
	end

	info = getInfo('all');
	for iSource = 1:obj.nb_sources
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

function drawSilence (obj)
	info = getInfo('cpt_silence', 'cpt_object', 'nb_steps');
	vec = 1 :(info.cpt_silence+info.cpt_object): info.nb_steps;
	hold(obj.h2, 'on');

	for iSilence = 1:numel(vec)
		x = vec(iSilence);
        X = [x, x, x+info.cpt_silence, x+info.cpt_silence];
        Y1 = [0, 1, 1, 0];
        C = [0.75, 0.75, 0.75];
		patch(X, Y1, C,...
			  'FaceAlpha', 0.6,...
			  'EdgeColor', 'none',...
			  'Parent', obj.h2);
	end

	hold(obj.h2, 'off');
end

function removeEmittingSources (obj, iSource)
	% for iSource = 1:obj.nb_sources
		% if ~isempty(obj.emitting_handle)
		if obj.emitting_handle(1, iSource) ~= 0
			set(obj.emitting_handle(1, iSource), 'Visible', 'off');
			set(obj.emitting_handle(2, iSource), 'Visible', 'off');
		end
	% end
end

function removeAllEmittingSources (obj)
    for iSource = 1:obj.nb_sources
		set(obj.emitting_handle(1, iSource), 'Visible', 'off');
		set(obj.emitting_handle(2, iSource), 'Visible', 'off');
    end
end


function endSimulation (obj)
	obj.drawFieldOfView('end');
	obj.drawLocalizationResults();
	obj.removeAllEmittingSources();
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === END OF FILE === % 
% =================== %
end