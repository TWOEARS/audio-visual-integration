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
    robot_platform;
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
    global ROBOT_PLATFORM;
    if strcmp(ROBOT_PLATFORM, 'JIDO')
        obj.robot_platform = 1;
    else
        obj.robot_platform = 2;
    end
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
    switch obj.robot_platform
    case 1
        theta = arrayfun(@(x) visual_data.triangulation{x}.coordinates.azimuth, present_objects);
        head_orientation = obj.robot.getCurrentHeadOrientation();
        
        theta = round(mod(head_orientation+theta, 360));
        
        % if numel(theta) == 2
        %     if abs(theta(1)-theta(2)) < 10
        %         theta = theta(1);
        %     end
        % end
        d = arrayfun(@(x) visual_data.triangulation{x}.coordinates.z*(-1), present_objects);
    case 2
        % theta = obj.robot.getCurrentHeadOrientation();
        theta = round(mod(obj.robot.getCurrentHeadOrientation(), 360));
        d = 1;
    end

    for iTheta = 1:data('nb_objects')
        % theta(iTheta) = mod(head_orientation+theta(iTheta), 360);
        if isempty(obj.detected_sources)
            obj.detected_sources = theta(iTheta);
        else
            obj.detected_sources(end+1) = theta(iTheta);
        end
    end


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
