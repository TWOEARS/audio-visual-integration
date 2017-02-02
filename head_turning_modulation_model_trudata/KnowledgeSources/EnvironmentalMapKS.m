
classdef EnvironmentalMapKS < AbstractKS
% EnvironmentalMapKS class
% This knowledge source aims at providing a representation of the internal representation of the environment
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
	bbs;
	htm;
	RIR; % Robot_Internal_Representation class
	MOKS;
	robot;
	
	% figure_handle;
	fov_handle;
	% fov_handle_naive;
	objects_handle;
	robot_handle;
	shm_handle;
	% naive_handle;
    % hist_handle;
    % focus_type_handle;
    % classif_hist_handle;
    % fo_handle;
	% statistics_handle;
	% hl;
	% tl_handle;
	tc_handle;

    % ft_handle;
    % ft_colors;

	depth_of_view;
	field_of_view;

	% object_creation;

	sources = [];
    nb_sources = 0;
    % timeline;
    
    emitting_sources = [];

	% angles;

	dmax = 1;
	h;

	angles = [];
	angles_rad = [];
	angles_cpt = [];

	iStep;

	shms;
    
    nb_objects = 0;
<<<<<<< HEAD
=======
    starting_angle;
    audio_labels = {};
>>>>>>> tmp

end

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = EnvironmentalMapKS (bbs, htm)
	obj = obj@AbstractKS();
    obj.bbs = bbs;
    obj.invocationMaxFrequency_Hz = inf;

    % htm = findKS(obj, 'HeadTurningModulationKS');
	
	obj.htm = htm;

	obj.RIR = htm.RIR;
	obj.robot = bbs.robotConnect;
    obj.MOKS = findKS(obj.bbs, 'MotorOrderKS');
	%obj.MOKS = htm.MOKS;

	obj.depth_of_view = 3;
	obj.field_of_view = 30;
    obj.nb_sources = 0;
<<<<<<< HEAD
=======
    obj.starting_angle = -90;
    
>>>>>>> tmp
    % obj.timeline = getInfo('timeline');
	% obj.angles = getInfo('sources_position');
	% obj.angles_rad = deg2rad(obj.angles);
	% obj.angles_cpt = [zeros(1, numel(obj.angles_rad)) ; zeros(1, numel(obj.angles_rad))];
 

	obj.createFigure();

	% obj.drawSources();

	obj.drawRobot();

	obj.drawFieldOfView('init');

	% --- Maximum 5 sources
	% --- thet_a, theta_v, d
	obj.sources = zeros(5, 1);
<<<<<<< HEAD

	obj.objects_handle = zeros(5, 2);

	obj.emitting_handle = zeros(2, obj.nb_sources);
=======
>>>>>>> tmp

	obj.objects_handle = zeros(5, 2);

	% obj.tl_handle = zeros(1, 3);

	obj.tc_handle = zeros(1, 10);

	obj.shm_handle = zeros(1, obj.nb_sources);
	% obj.writeClassification('init');
end
% === CONSTRUCTOR [END] === %

function execute (obj)
	obj.iStep = obj.htm.iStep;

	if obj.iStep > 1
	    obj.findSources();
	    obj.drawSources();
% 		obj.drawLocalizationResults();
<<<<<<< HEAD
		obj.drawEmittingSource();
=======
		%obj.drawEmittingSource();
>>>>>>> tmp
		% obj.drawSeenSources();
		obj.drawFieldOfView('update');
		obj.writeClassification();
	end
	pause(0.01);
end

<<<<<<< HEAD

% === Execute functionality
function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function finished = isFinished(obj)
    finished = obj.finished;
end

function findSources (obj)
	obj.nb_objects = obj.RIR.nb_objects;

	for iObject = 1:obj.nb_objects
		theta_a = getObject(obj, iObject, 'theta');
		obj.sources(iObject, 1) = deg2rad(theta_a(end));
		% theta_a = theta_a(end);

		theta_v = getObject(obj, iObject, 'theta_v');
		obj.sources(iObject, 2) = deg2rad(theta_v(end));
		% theta_v = theta_v(end);

		d = getObject(obj, iObject, 'd');
		obj.sources(iObject, 3) = d(end);


		% obj.angles = getObject(obj, 'all', 'theta');
		% obj.angles_rad = deg2rad(obj.angles);
		% obj.angles_cpt = [zeros(1, numel(obj.angles_rad)) ; zeros(1, numel(obj.angles_rad))];
=======

% === Execute functionality
function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function finished = isFinished(obj)
    finished = obj.finished;
end

function findSources (obj)
	obj.nb_objects = obj.RIR.nb_objects;

	for iObject = 1:obj.nb_objects
		theta_a = getObject(obj, iObject, 'theta');
		obj.sources(iObject, 1) = deg2rad(theta_a(end)+obj.starting_angle);
		% theta_a = theta_a(end);

		theta_v = getObject(obj, iObject, 'theta_v');
		obj.sources(iObject, 2) = deg2rad(theta_v(end)+obj.starting_angle);
		% theta_v = theta_v(end);

		d = getObject(obj, iObject, 'd');
		obj.sources(iObject, 3) = d(end)+0,5;
>>>>>>> tmp
	end
end

function writeClassification (obj, k)
	% if strcmp(k, 'init')
		% for iSource = 1:obj.nb_sources
<<<<<<< HEAD
		for iSource = 1:obj.objects
=======
		for iSource = 1:obj.nb_objects
>>>>>>> tmp
			pos = get(obj.objects_handle(iSource), 'Position');
			%if obj.angles(iSource) <= 90
            theta = rad2deg(obj.sources(iSource, 2))-obj.starting_angle;
            if theta <= 90
				pos1 = [pos(1)+0.5, pos(2)+0.5];
% 				pos2 = [pos1(1)   , pos1(2)+0.2];
% 				pos3 = [pos1(1)   , pos1(2)+0.7];
			%elseif obj.angles(iSource) <= 180
            elseif theta <= 180
				pos1 = [pos(1)-0.5, pos(2)+0.5];
% 				pos2 = [pos1(1)   , pos1(2)+0.2];
% 				pos3 = [pos1(1)   , pos1(2)+0,7];
			%elseif obj.angles(iSource) <= 270
            elseif theta <= 270
				pos1 = [pos(1)-0.5, pos(2)-0.5];
% 				pos2 = [pos1(1)   , pos1(2)+0.2];
% 				pos3 = [pos1(1)   , pos1(2)+0,7];
			else
<<<<<<< HEAD
				pos1 = [pos(1)+1.5, pos(2)-1.5];
				pos2 = [pos1(1), pos1(2)+0.5];
				pos3 = [pos1(1), pos1(2)+1];
			end
			alabel = getObject(obj.htm, iObject, 'audio_label');
			vlabel = getObject(obj.htm, iObject, 'visual_label');
=======
				pos1 = [pos(1)+0.5, pos(2)-0.5];
% 				pos2 = [pos1(1)   , pos1(2)+0.2];
% 				pos3 = [pos1(1)   , pos1(2)+0,7];
			end
			alabel = getObject(obj.htm, iSource, 'audio_label');
            if strcmp(alabel, 'femaleSpeech')
                alabel = 'speech';
            elseif strcmp(alabel, 'dog')
                alabel = 'barking';
            end
			vlabel = getObject(obj.htm, iSource, 'visual_label');
>>>>>>> tmp
			str = [vlabel, ' ', alabel];
			% obj.tc_handle(1, iSource) = text(pos1(1), pos1(2), '',...
			% 							  'FontSize', 12,...
			% 							  'FontWeight', 'bold',...
			% 							  'Color', [0, 153, 76]/255,...
			% 							  'Parent', obj.h(1));
			% obj.tc_handle(2, iSource) = text(pos2(1), pos2(2), '',...
			% 							  'FontSize', 12,...
			% 							  'FontWeight', 'bold',...
			% 							  'Color', 'black',...
			% 							  'Parent', obj.h(1));
<<<<<<< HEAD
			obj.tc_handle(iSource) = text(pos3(1), pos3(2), str,...
										  'FontSize', 12,...
										  'FontWeight', 'bold',...
										  'Color', 'black',...
										  'Parent', obj.h(1));
=======
            if obj.tc_handle(iSource) == 0
                obj.tc_handle(iSource) = text(pos1(1), pos1(2), str,...
                                              'FontSize', 12,...
                                              'FontWeight', 'bold',...
                                              'Color', 'black',...
                                              'Parent', obj.h(1));
            else
                set(obj.tc_handle(iSource), 'String', str, 'Position', [pos1(1), pos1(2)]);
            end
>>>>>>> tmp
		end
	% elseif strcmp(k, 'update')
	% 	% for iSource = 1:obj.nb_sources
	% 	if obj.htm.RIR.nb_objects > 0
	% 		for iObject = 1:obj.htm.RIR.nb_objects
	% 			% alabel = obj.htm.RIR.environment{end}.objects{iObject}.audio_label;
	% 			% vlabel = obj.htm.RIR.environment{end}.objects{iObject}.visual_label;
	% 			alabel = getObject(obj.htm, iObject, 'audio_label');
	% 			vlabel = getObject(obj.htm, iObject, 'visual_label');
	% 			str = [vlabel, ' ', alabel];
	% 			set(obj.tc_handle(3, iObject),...
	% 				'String', str,...
	% 				'FontSize', 20);
	% 		end
	% 	end
	% end
end
<<<<<<< HEAD

% function drawLocalizationResults (obj)
% 	for iObject = 1:obj.htm.RIR.nb_objects
% 		object = getObject(obj, iObject);
% 		% tmIdx = getObject(obj.htm, iObject, 'tmIdx');
% 		tmIdx = object.tmIdx(1);
% 		current_theta = object.theta(end);
% 		source = object.source;
% 		
% 		object_pos = get(obj.objects_handle(source), 'Position');
% 		
% 		x = object_pos(1)+object_pos(3);
% 		y = object_pos(2)+object_pos(4);
% 		
% 		if obj.text_handle(source) == 0
% 			obj.text_handle(source) = text(x+0.2, y+0.2, num2str(current_theta),...
% 										   'FontSize', 16,...
% 										   'FontWeight', 'bold',...
% 										   'Parent', obj.h(1));
% 		else
% 			set(obj.text_handle(source), 'Position', [x+0.2, y+0.2, 0],...
% 										 'String', [num2str(current_theta), '^\circ']);
% 		end
% 	end
% end
=======
>>>>>>> tmp

function drawFieldOfView (obj, k)
	if strcmp(k, 'init') || strcmp(k, 'end')
		x0 = obj.RIR.position(1);
		y0 = obj.RIR.position(2);
		theta1 = -(obj.field_of_view/2)+obj.starting_angle;
		theta2 = +(obj.field_of_view/2)+obj.starting_angle;
		[x1, y1] = pol2cart(deg2rad(theta1), obj.depth_of_view);
		[x2, y2] = pol2cart(deg2rad(theta2), obj.depth_of_view);

		if strcmp(k, 'init')
			% === HTM robot
			l1 = line([x0, x1], [y0, y1], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h(1));
			l2 = line([x1, x2], [y1, y2], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h(1));
			l3 = line([x2, x0], [y2, y0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h(1));
			
			obj.fov_handle = [l1, l2, l3];
		else
			set(obj.fov_handle(1), 'XData', [x0, x1], 'YData', [y0, y1]);
			set(obj.fov_handle(2), 'XData', [x1, x2], 'YData', [y1, y2]);
			set(obj.fov_handle(3), 'XData', [x2, x0], 'YData', [y2, y0]);
		end
    elseif strcmp(k, 'update')
		x0 = obj.RIR.position(1);
		y0 = obj.RIR.position(2);

<<<<<<< HEAD
=======
        head_position = obj.robot.getCurrentHeadOrientation()+obj.starting_angle;
>>>>>>> tmp
	    % === HTM robot
		if ~isempty(obj.MOKS.head_position(end-1))
			head_position1 = head_position - (obj.field_of_view/2);
			head_position2 = head_position + (obj.field_of_view/2);

			[x1, y1] = pol2cart(deg2rad(head_position1), obj.depth_of_view);
			[x2, y2] = pol2cart(deg2rad(head_position2), obj.depth_of_view);
			
			set(obj.fov_handle(1), 'XData', [x0, x1], 'YData', [y0, y1]);
			set(obj.fov_handle(2), 'XData', [x1, x2], 'YData', [y1, y2]);
			set(obj.fov_handle(3), 'XData', [x2, x0], 'YData', [y2, y0]);
		end
	end
end

<<<<<<< HEAD
function drawEmittingSource (obj, varargin)

	theta = getLocalisationOutput(obj);

	[x, y] = pol2cart(deg2rad(theta), 10);
	if obj.emitting_handle == 0
		obj.emitting_handle = line([0, x], [0, y], 'LineWidth')
	else
		set(obj.emitting_handle, 'XData', [0, x], 'YData', [0, y]);
	end
end

function drawSources (obj)
	for iSource = 1:obj.RIR.nb_objects
		[xa, ya] = pol2cart(obj.sources(iSource, 1), obj.sources(iSource, 3));
		posa = [xa-0.5, ya-0.5, 1, 1];

		[xv, yv] = pol2cart(obj.sources(iSource, 2), obj.sources(iSource, 3));
		posv = [xv-0.5, yv-0.5, 1, 1];
=======
function drawSources (obj)
    head_position = obj.robot.getCurrentHeadOrientation()+obj.starting_angle;
	for iSource = 1:obj.RIR.nb_objects
		[xa, ya] = pol2cart(obj.sources(iSource, 1), obj.sources(iSource, 3));
		posa = [xa-0.5, ya-0.5, 1, 1];

		[xv, yv] = pol2cart(obj.sources(iSource, 2), obj.sources(iSource, 3));
		posv = [xv-0.5, yv-0.5, 1, 1];
        if abs(head_position-rad2deg(obj.sources(iSource, 2))) <= obj.field_of_view
            line_style = '-';
        else
            line_style= '--';
        end
        if isPerformant(obj, iSource, 'Object')
            cat_obj = getCategory(obj, iSource, 'Object');
            if cat_obj.congruence == 1
                col = 'blue';
            else
                col = 'red';
            end
        else
            col = 'none';
        end
>>>>>>> tmp
		if obj.objects_handle(iSource, 1) == 0
			obj.objects_handle(iSource, 1) = rectangle('Position' , posa,...
				  		   			 			    'Curvature', 0.4 ,...
				  		   			 			    'LineWidth', 1   ,...
<<<<<<< HEAD
	          									    'LineStyle', '--',...
	          									    'FaceColor', [201, 230, 204]/255,...
=======
	          									    'LineStyle', line_style,...
	          									    'FaceColor', col,...
>>>>>>> tmp
				  		   			 			    'Parent'   , obj.h(1));
			obj.objects_handle(iSource, 2) = rectangle('Position' , posv,...
				  		   			 			    'Curvature', 0.4 ,...
				  		   			 			    'LineWidth', 1   ,...
<<<<<<< HEAD
	          									    'LineStyle', '--',...
	          									    'FaceColor', [201, 230, 204]/255,...
				  		   			 			    'Parent'   , obj.h(1));
		else
			set(obj.objects_handle(iSource, 1), 'Position', posa);
			set(obj.objects_handle(iSource, 2), 'Position', posv);
=======
	          									    'LineStyle', line_style,...
	          									    'FaceColor', col,...
				  		   			 			    'Parent'   , obj.h(1));
		else
			set(obj.objects_handle(iSource, 1), 'Position', posa, 'FaceColor', col);
			set(obj.objects_handle(iSource, 2), 'Position', posv, 'FaceColor', col);
>>>>>>> tmp
		end
	end
end

function drawRobot (obj)
<<<<<<< HEAD
	circle_size = 0.3;
=======
	circle_size = 0.15;
>>>>>>> tmp
	% --- Centering the center around [0, 0]
	% --- 'pos' is: [x, y, width, height]
	pos = [obj.RIR.position(1)-circle_size/2, obj.RIR.position(2)-circle_size/2,...
		   circle_size, circle_size];
	% --- The 'Curvature' is allowing to draw a circle from the 'rectangle' function
	obj.robot_handle = rectangle('Position' , pos  ,...
			  		   			 'Curvature', [1 1],...
			  		   			 'LineWidth', 2,...
			  		   			 'FaceColor', 'black',...
			  		   			 'Parent'   , obj.h(1));
			  		   			 % 'Parent'   , obj.figure_handle);
<<<<<<< HEAD
	circle_size = 2;
=======
	circle_size = 0.5;
>>>>>>> tmp
	% --- Centering the center around [0, 0]
	% --- 'pos' is: [x, y, width, height]
	% x0 = obj.RIR.position(1);
	% y0 = obj.RIR.position(2);
	x0 = 0;
	y0 = 0;
	pos = [x0-circle_size/2, y0-circle_size/2, circle_size, circle_size];
	% --- The 'Curvature' is allowing to draw a circle from the 'rectangle' function
	obj.shm_handle = rectangle('Position' , pos  ,...
			  		   		   'Curvature', [1 1],...
			  		   		   'LineWidth', 2,...
			  		   		   'FaceColor', 'none',...
			  		   		   'Parent'   , obj.h(1));
end

function createFigure (obj)
	p = figure();
	set(p, 'Units', 'normalized',...
		   'Outerposition', [0 0 1 1],...
		   'Color', [1, 1, 1],...
		   'Tag', 'EMKS');
	obj.h = zeros(1, 6);

	% --- h(1) = environment
	% obj.h(1) = subplot(5, 6, [1:3, 7:9, 13:15], 'Parent', p);
	% obj.h(1) = subplot(3, 7, [1, 2, 3, 4, 8, 9, 10, 11, 15, 16, 17, 18], 'Parent', p);
	obj.h(1) = subplot(1, 1, 1, 'Parent', p);
<<<<<<< HEAD
	set(obj.h(1), 'XLim', [-11, 11],...
				'YLim', [-11, 11])%,...
=======
	set(obj.h(1), 'XLim', [-3.5, 3.5],...
				'YLim', [-3.5, 3.5])%,...
>>>>>>> tmp
	axis square;
                % 'Position', [0.05, 0.4, 0.45, 0.45])
	axis off;
end

function changeScenario (obj)
   obj.objects_handle = zeros(5, 2);
   obj.tc_handle = zeros(1, 10);
   obj.sources = zeros(5, 1);
   obj.shm_handle = zeros(1, obj.nb_sources);
   ch = get(obj.h(1), 'Children');
   for iChild = 1:numel(ch)-5
       delete(ch(iChild));
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
