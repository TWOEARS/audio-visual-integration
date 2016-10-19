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

	text_handle;

	depth_of_view;
	field_of_view;

	object_creation;

	sources = [];

	dmax = 1;

end

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = EnvironmentalMapKS (htm)
	obj.htm = htm;
	obj.RIR = htm.RIR;
	obj.MOKS = htm.MotorOrderKS;

	obj.depth_of_view = 9;
	obj.field_of_view = 30;

	obj.createFigure();
	obj.drawSources();

	% obj.robot_position = RIR.position;

	obj.drawRobot();

	obj.drawFieldOfView('init');

	obj.drawSHM('init');

	obj.emitting_handle = zeros(2, getInfo('nb_sources'));

	obj.text_handle = zeros(1, getInfo('nb_sources'));

	obj.shm_handle = zeros(1, getInfo('nb_sources'));

end
% === CONSTRUCTOR [END] === %

function updateMap (obj)
	obj.drawEmittingSource();
	obj.drawFieldOfView('update');
	obj.drawSeenSources();
	obj.drawClassificationResults();
	obj.drawLocalizationResults();
	% obj.drawSHM('update');
end

function createFigure (obj)
	obj.figure_handle = axes('XLim', [-10, 10], 'YLim', [-10, 10]);
	p = get(obj.figure_handle(), 'Parent');
	set(p, 'units','normalized','outerposition', [0 0 1 1]);
	axis square;
	% axis equal;
end

function endSimulation (obj)
	obj.drawFieldOfView('end');
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
	current_object = obj.htm.ODKS.id_object(end);
	if current_object ~= 0
		iSource = obj.htm.sources(obj.htm.iStep);
		current_theta = getObject(obj.htm, current_object, 'theta');
		current_theta = current_theta(end);
		object_pos = get(obj.objects_handle(iSource), 'Position');
		x = object_pos(1)+object_pos(3);
		y = object_pos(2)+object_pos(4);
		if obj.text_handle(iSource) == 0
			obj.text_handle(iSource) = text(x+0.3, y+0.3, num2str(current_theta), 'FontSize', 12);
		else
			set(obj.text_handle(iSource), 'Position', [x+0.3, y+0.3, 0], 'String', num2str(current_theta));
		end
	end
	% current_audio_theta = obj.htm.ALKS.hyp_hist(end);
	% angles = getObject(obj.htm, 'all', 'theta');

end

function drawSources (obj)
	h = obj.figure_handle;
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
			  		   			 'Parent'   , obj.figure_handle);
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
			l1 = line([x0, x1], [y0, y1], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2);
			l2 = line([x1, x2], [y1, y2], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2);
			l3 = line([x2, x0], [y2, y0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2);
			
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

	hold(obj.figure_handle, 'on');
	
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
	
	hold(obj.figure_handle, 'off');
	
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
					  	  'Parent'   , obj.figure_handle,...
					  	  'Tag', num2str(iSource));
			h2 = rectangle('Position' , pos2  ,...
						  'Curvature', [1 1],...
						  'LineStyle', '-.',...
						  'EdgeColor', [51, 102, 0]/255,...
					  	  'Parent'   , obj.figure_handle,...
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


function drawSHM (obj, k)

	if strcmp(k, 'init')
		circle_size = 3;
		% --- Centering the center around [0, 0]
		% --- 'pos' is: [x, y, width, height]
		pos = [obj.RIR.position(1)-circle_size/2, obj.RIR.position(2)-circle_size/2,...
			   circle_size, circle_size];
		% --- The 'Curvature' is allowing to draw a circle from the 'rectangle' function
		obj.shm_handle = rectangle('Position' , pos  ,...
				  		   		   'Curvature', [1 1],...
				  		   		   'LineWidth', 2,...
				  		   		   'FaceColor', 'none',...
				  		   		   'Parent'   , obj.figure_handle);
		x0 = obj.RIR.position(1);
		y0 = obj.RIR.position(2);
		sources_position = getInfo('sources_position');
		% for iSource = 1:getInfo('nb_sources')
			% theta = sources_position(iSource);
			% [x1, y1] = pol2cart(deg2rad(theta), 2);
			% line([x0, x1], [y0, y1], 'Color', 'b', 'LineStyle', '-', 'LineWidth', 1, 'Parent', obj.figure_handle);
		% end
	elseif strcmp(k, 'update')
		iStep = obj.htm.iStep;
		iSource = obj.htm.sources(iStep);
		if iStep > 1
			motor_order = obj.MOKS.motor_order(iStep-1:iStep);
			focus_hist = obj.htm.HTMFocusKS.focus_hist(iStep-1:iStep);
			if focus_hist(1) == 0 && focus_hist(2) > 0
				if motor_order(1) == 0 && motor_order(2) > 1
					x0 = obj.RIR.position(1);
					y0 = obj.RIR.position(2);
					theta = motor_order(2);
					if obj.shm_handle(iSource) == 0
						d = 1/obj.dmax;
						[x1, y1] = pol2cart(deg2rad(theta), d);
						obj.shm_handle(iSource) = line([x0, x1], [y0, y1],...
													   'Color', 'g',...
													   'LineStyle', '-',...
													   'LineWidth', 1,...
													   'UserData', 1,...
													   'Parent', obj.figure_handle);
					else
						previous_d = get(obj.shm_handle(iSource), 'UserData');
						d = previous_d + 1;
						set(obj.shm_handle(iSource), 'UserData', d);
						if d > obj.dmax
							obj.dmax = d;
						end
						d = d/obj.dmax;
						[x1, y1] = pol2cart(deg2rad(theta), d);
						set(obj.shm_handle(iSource), 'XData', [x0, x1], 'YData', [y0, y1]);

						sources_position = getInfo('sources_position');
						for iHandle = 1:numel(obj.shm_handle)
							if iHandle ~= iSource
								theta = sources_position(iHandle);
								d = get(obj.shm_handle(iHandle), 'UserData')/obj.dmax;
								set(obj.shm_handle(iHandle), 'UserData', d);
								[x1, y1] = pol2cart(deg2rad(theta), d);
								set(obj.shm_handle(iSource), 'XData', [x0, x1], 'YData', [y0, y1]);
							end
						end
					end
				end
			end
		end
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