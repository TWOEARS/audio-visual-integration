% 'VisualIdentityKS' class
% Author: Benjamin Cohen-Lhyver
% Date: 19.10.16
% Rev. 1.0

classdef VisualStreamSegregationKS < AbstractKS
% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = private)
    robot; % the robot environment interface
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
function obj = VisualStreamSegregationKS (robot)
    obj = obj@AbstractKS();
    global ROBOT_PLATFORM;
    if strcmp(ROBOT_PLATFORM, 'JIDO')
        obj.robot_platform = 1;
    elseif strcmp(ROBOT_PLATFORM, 'ODI')
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
    visual_vec = zeros(getInfo('nb_visual_labels'), 1);

    % visual_labels = getInfo('visual_labels');
    data = obj.robot.getVisualData();

    switch case obj.robot_platform
    case 1
        present_objects = find(arrayfun(@(x) data.triangulation{x}.triangulated, 1:getInfo('nb_visual_labels')));
    case 2
        present_objects = 1;
    end

    % push the visual identity hypothesis to the blackboard
    % visualStreamsHypotheses = containers.Map(present_objects, numel(present_objects));
    keySet = {'present_objects', 'nb_objects'};
    valueSet = {present_objects, numel(present_objects)};

    visualStreamsHypotheses = containers.Map(keySet, valueSet);
    
    obj.blackboard.addData('visualStreamsHypotheses', visualStreamsHypotheses,...
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
