% 'VisualIdentityKS' class
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

    head_orientation = obj.robot.getCurrentHeadOrientation();
    for iTheta = 1:numel(theta)
    	theta = mod(head_orientation, 360) + theta;
        if isempty(obj.detected_sources)
            obj.detected_sources = theta;
        else
            dif = obj.detected_sources - theta;
            tmp = find(dif <= obj.sensitivity)
            if isempty(tmp)
                obj.detected_sources(end+1) = theta;
            end
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
