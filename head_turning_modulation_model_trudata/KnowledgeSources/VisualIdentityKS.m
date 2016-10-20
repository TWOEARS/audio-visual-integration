% 'VisualIdentityKS' class
% Author: Benjamin Cohen-Lhyver
% Date: 19.10.16
% Rev. 1.0

classdef VisualIdentityKS < AbstractKS
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
function obj = VisualIdentityKS (robot)
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
    visual_vec = zeros(getInfo('nb_visual_labels'), 1);

    visual_labels = getInfo('visual_labels');
    visual_data = obj.robot.getData();

    data = obj.blackboard.getLastData('visualStreamsHypotheses').data;
    present_objects = data('present_objects');

    visual_vec(present_objects) = 1;

    keySet = {'present_objects', 'visual_labels'};
    valueSet = {present_objects, visual_labels(present_objects)};

    visualIdentityHypotheses = containers.Map(keySet, valueSet);

    obj.blackboard.addData('visualIdentityHypotheses', visualIdentityHypotheses,...
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
