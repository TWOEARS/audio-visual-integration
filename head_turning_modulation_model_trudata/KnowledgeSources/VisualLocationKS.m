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
	data = obj.robot.getData();

    data = obj.blackboard.getLastData('visualStreamsHypotheses').data;
    present_objects = data(present_objects);

    theta = arrayfun(@(x) data.triangulation{present_objects}.coordinates.azimuth, present_objects);

    head_orientation = obj.robot.getCurrentHeadOrientation();
    for iTheta = 1:numel(theta)
    	theta = theta - head_orientation;
    end

    d = arrayfun(@(x) data.triangulation{present_objects}.coordinates.z*(-1), present_objects);

    keySet = {'present_objects', 'theta', 'd'};
    valueSet = {present_objects, theta, d};

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
