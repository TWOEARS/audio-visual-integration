% 'MotorOrderKS' class
% Author: Benjamin Cohen-Lhyver
% Date: 01.06.16
% Rev. 1.0
classdef MotorOrderKS < AbstractKS

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    head_position = [];
    motor_order = [];
    htm;
    RIR;
    HTMFocusKS;
    
    shm;
    robot;
    bbs;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = MotorOrderKS (bbs, robot)
    obj = obj@AbstractKS();
    obj.invocationMaxFrequency_Hz = inf;
    obj.robot = robot;
    
    obj.htm = findKS(obj.bbs, 'HeadTurningModulationKS');
    obj.RIR = htm.RIR;
    % obj.RIR = htm.RIR;
end
% === CONSTRUCTOR [END] === %

function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)
    
    focus = obj.blackboard.getLastData('FocusedObject');
    focus = focus.data('focus');

    currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;
    
    if obj.isFocusedObjectPresent(focus)  % --- move the head to 'theta'
        theta = getObject(obj.RIR, focus, 'theta');
    elseif focus == 0 && numel(obj.head_position) > 0 % --- go back to resting position (O°)
        theta = -obj.head_position(end);
    else
        theta = 0;
    end

    obj.motor_order(end+1) = theta;

    if numel(obj.head_position) > 1
        obj.head_position(end+1) = mod(obj.head_position(end)+theta, 360);
    else
        obj.head_position(end+1) = theta;
    end
    
    obj.RIR.head_position = obj.head_position;

    obj.computeSHM();

    obj.robot.moveRobot(0, 0, theta);
    
    obj.blackboard.addData('motorOrder', [currentHeadOrientation, theta],...
                           true, obj.trigger.tmIdx);
    notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
end

function bool = isFocusedObjectPresent (obj, focus)
    % focus = obj.HTMFocusKS.focus(end);

    if obj.RIR.nb_objects == 0
        bool = false;
    elseif getObject(obj.RIR, focus, 'presence')
        bool = true;
    else
        bool = false;
    end
end

function computeSHM (obj)
    if numel(obj.head_position) > 1
        if obj.head_position(end-1) ~= obj.head_position(end)
            obj.shm = obj.shm+1;
        end
    end
end

function finished = isFinished(obj)
    finished = obj.finished;
end

% ===================== %
% === METHODS [END] === %
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %
end