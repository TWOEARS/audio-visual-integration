% VisualIdentityKS class
% Author: Benjamin Cohen-Lhyver
% Date: 19.10.16
% Rev. 1.0

classdef VisualLocationKS < AbstractKS
% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = private)
    robot; % the robot environment interface
    detected_sources = [];
    sensitivity = 10;
    fov=45;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = VisualLocationKS (robot)
    obj = obj@AbstractKS(); 
    % initialize class members
    obj.robot = robot;
    % run continuously
    obj.invocationMaxFrequency_Hz = inf;
end
% === CONSTRUCTOR [END] === %

% === execute functionality
function [b, wait] = canExecute( obj )
    % self-explanatory
    b = true;
    wait = false;
end

function execute (obj)
	visual_data = obj.robot.getVisualData();

    data = obj.blackboard.getLastData('visualStreamsHypotheses').data;
    present_objects = data('present_objects');

    theta = arrayfun(@(x) visual_data.triangulation{x}.coordinates.azimuth, present_objects);
    theta = round(theta);
    if numel(theta) == 2
        if theta(1)-theta(2) < 10
            theta = theta(1);
        end
    end

    head_orientation = obj.robot.getCurrentHeadOrientation();
    for iTheta = 1:numel(theta)
    	theta(iTheta) = mod(head_orientation+theta, 360);
        if isempty(obj.detected_sources)
            obj.detected_sources = theta(iTheta);
        else
            if isInFieldOfView(theta(iTheta))
                obj.detected_sources(end+1) = theta(iTheta);
            end
            % dif = obj.detected_sources - theta;
            % tmp = find(dif <= obj.sensitivity)
            % if isempty(tmp)
            %     obj.detected_sources(end+1) = theta;
            % end
        end
    end

    d = arrayfun(@(x) visual_data.triangulation{x}.coordinates.z*(-1), present_objects);

    keySet = {'present_objects', 'theta', 'd', 'detected_sources'};
    valueSet = {present_objects, theta, d, obj.detected_sources};

    visualLocationHypotheses = containers.Map(keySet, valueSet);

    obj.blackboard.addData('visualLocationHypotheses', visualLocationHypotheses,...
                           false, obj.trigger.tmIdx);
    notify(obj, 'KsFiredEvent');
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end
