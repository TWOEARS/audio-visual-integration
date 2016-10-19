% 'VisualIdentityKS' class
% Author: Benjamin Cohen-Lhyver
% Date: 19.10.16
% Rev. 1.0

classdef AudioVisualFusionKS < AbstractKS
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
function obj = AudioVisualFusionKS (robot)
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

    present_objects = obj.blackboard.getLastData('visualStreamsHypotheses').present_objects;
    v = obj.blackboard.getLastData('visualLocationHypotheses');
    visual_angles = v.theta;
    d = v.d;
    audio_angles = getLocalisationOutput();

    [~, p] = min(visual_angles - audio_angles);
    present_objects = present_objects(p);
    theta = theta(p);
    d = d(p);

    audiovisualHypotheses = containers.Map(present_objects, theta, d);

    obj.blackboard.addData('audiovisualHypotheses', audiovisualHypotheses,...
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
