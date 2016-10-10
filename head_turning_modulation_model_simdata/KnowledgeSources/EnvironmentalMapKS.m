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
	MotorOrderKS;
	
	figure_handle;
	fov_handle;
	fov_handle2;
	objects_handle;
	emitting_handle;
	robot_handle;
	shm_handle;

	depth_of_view;
	field_of_view;

	object_creation;

	sources = [];

end

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = EnvironmentalMapKS (htm)
	obj.htm = htm;
	obj.RIR = htm.RIR;
	obj.MotorOrderKS = htm.MotorOrderKS;

	obj.depth_of_view = 9;
	obj.field_of_view = 30;

	obj.createFigure();
	obj.drawSources();

	% obj.robot_position = RIR.position;

	obj.drawRobot();

	obj.drawFieldOfView('init');

	obj.drawSHM('init');

	obj.emitting_handle = zeros(2, getInfo('nb_sources'));

end
% === CONSTRUCTOR [END] === %

function updateMap (obj)
	obj.drawFieldOfView('update');
	obj.drawEmittingSource();
	obj.drawSeenSources();
	obj.drawClassificationResults();
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
	l = getObject(obj.htm, obj.htm.current_object, 'label');
	g = obj.htm.gtruth{iStep, 1};
	if strcmp(l, g)
		set(obj.objects_handle(iSource), 'FaceColor', 'blue');
	else
		set(obj.objects_handle(iSource), 'FaceColor', 'red');
	end
end

function drawSeenSources (obj)
	head_position = obj.MotorOrderKS.head_position_hist(end);
	for iSource = 1:numel(obj.objects_handle)
		source = find(head_position == getInfo('sources_position'));
		if ~isempty(source)
			set(obj.objects_handle(source), 'LineStyle', '-', 'LineWidth', 2);
			% if 
		end
	end

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

	if isempty(obj.MotorOrderKS.head_position_hist)
		return;
	end

	hold(obj.figure_handle, 'on');
	
	x0 = obj.RIR.position(1);
	y0 = obj.RIR.position(2);
	
	theta1 = obj.MotorOrderKS.head_position_hist(end) - (obj.field_of_view/2);
	theta2 = obj.MotorOrderKS.head_position_hist(end) + (obj.field_of_view/2);

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
		for iSource = 1:getInfo('nb_sources')
			theta = sources_position(iSource);
			[x1, y1] = pol2cart(deg2rad(theta), 2);
			line([x0, x1], [y0, y1], 'Color', 'b', 'LineStyle', '-', 'LineWidth', 1, 'Parent', obj.figure_handle);
		end
	end

	% angles = 1 :360/(getInfo('nb_AVPairs')+1): 360;
 %    angles = round(angles(1:end));
 %    cpt = zeros(numel(AVPairs), 1);
 %    positions = [];
 %    positions_naive = [];

 %    for iObj = 1:htm.RIR.nb_objects
 %        idx = find(strcmp(getObject(htm, iObj, 'label'), AVPairs));
 %        if ~isempty(idx) && getObject(htm, iObj, 'theta') == 0
 %        % --- Object focused
 %        % if htm.RIR.getObj(iObj).theta == 0
 %            % ff = [ff, htm.RIR.getObj(iObj).theta_hist(1)] ;
 %            % cpt(idx) = cpt(idx)+1 ;
 %            positions(end+1) = angles(idx+1);
 %        % --- Object NOT focused
 %        else
 %            % ff = [ff, 0] ;
 %            % positions = [positions ; 0] ;
 %        end
 %        positions_naive = [positions_naive, angles(idx+1)];
 %    end

 %    % angles = 0 :360/(9*(3+1)): 359;
 %    angles = 0 :360/(9*(getInfo('nb_AVPairs')+1)): 359;
 %    angles = deg2rad(angles);
 %    positions = deg2rad(positions);
 %    positions_naive = deg2rad(positions_naive);

 %    figure;

 %    h1 = rose(positions_naive, angles); 
 %    hold on;
 %    h2 = rose(positions, angles);


 %    pos = get(gca, 'XLim');
 %    set(gca, 'FontSize', 55)

 %    angles = angles(1 :9: end);

 %    h3 = polar(angles(2:end), ones(1, getInfo('nb_AVPairs'))*pos(2));

 %    % set(h1, 'Color', 'red',...
 %    set(h1, 'Color', [0.2, 0.2, 0.2],...
 %            'LineWidth', 7,...
 %            'LineStyle', '-');
 %    % set(h2, 'Color', [0.6, 0.6, 0.6],...
 %    set(h2, 'Color', 'red',...
 %            'LineWidth', 5,...
 %            'LineStyle', '-');

 %    set(h3, 'LineStyle', 'none',...
 %            'Marker', '.',...
 %            'MarkerSize', 50,...
 %            'Color', [0, 0, 0]);

 %    th = findall(gcf,'Type','text');
 %    for i = 1:length(th),
 %        set(th(i),'FontSize',20)
 %    end
end

% function drawObject (obj)
% 	object_creation = obj.htm.ObjectDetectionKS.decision(end);
% 	% --- No object active in the scene
% 	if object_creation == 0
% 		if numel(obj.objects_handle) > 0
% 			for iObject = 1:numel(obj.objects_handle)
% 				% set(obj.objects_handle(iObject), 'LineStyle', 'none');
% 				if strcmp(get(obj.objects_handle(iObject), 'FaceColor'), 'red')
% 					set(obj.objects_handle(iObject), 'FaceColor', [255, 102, 102]/255);
% 				else
% 					set(obj.objects_handle(iObject), 'FaceColor', [201, 201, 255]/255);
% 				end
% 			end
% 		end
% 		return;
% 	% --- Create a new object
% 	elseif object_creation == 1
% 		object = getObject(obj.htm, 0);
% 		% th = object.theta_hist(1);
% 		th = object.theta;
% 		d = object.d;
% 		l = object.label;
% 		if strcmp(l, obj.htm.gtruth{obj.htm.iStep})
% 			face_color = 'blue';
% 		else
% 			face_color = 'red';
% 		end
% 		[x, y] = pol2cart(deg2rad(th), d);
% 		pos = [x-0.5, y-0.5, 1, 1];
% 		obj.objects_handle(end+1) = rectangle('Position' , pos ,...
% 			  		   			 			  'Curvature', 0.4 ,...
% 			  		   			 			  'LineWidth', 2   ,...
%           									  'LineStyle', 'none',...
%           									  'FaceColor', face_color,...
% 			  		   			 			  'Parent'   , obj.figure_handle...
% 			  		   			 			 );
% 		set(obj.figure_handle, 'XLim', [-10, 10], 'YLim', [-10, 10]);
% 	% --- Update current object
% 	elseif object_creation == 2
% 		object = getObject(obj.htm, 0);
% 		l = object.label;
% 		if strcmp(l, obj.htm.gtruth{obj.htm.iStep})
% 			set(obj.objects_handle(end), 'FaceColor', 'blue');
% 		end
% 		% set(obj.objects_handle(end), )
% 	end

% end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === END OF FILE === % 
% =================== %
end