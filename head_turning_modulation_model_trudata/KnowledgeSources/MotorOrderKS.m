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
    
    shm = 0;
    robot;
    bbs;

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
function obj = MotorOrderKS (bbs, robot)
    obj = obj@AbstractKS();
    obj.invocationMaxFrequency_Hz = inf;
    obj.robot = robot;
    obj.bbs = bbs;
    
    obj.htm = findKS(obj.bbs, 'HeadTurningModulationKS');
    obj.RIR = obj.htm.RIR;
end
% === CONSTRUCTOR [END] === %

function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)
    
    focus = obj.blackboard.getLastData('FocusedObject').data;
    focus = focus('focus');

    currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;

    if focus > 0
        % theta = getObject(obj, focus, 'theta_v');
        % theta = theta(end);
        % if theta == -1
            theta = getObject(obj, focus, 'theta');
            theta = theta(theta ~= -1);
            unique_values = unique(theta);
            tmp = histc(theta, unique_values);
            theta = unique_values(find(max(tmp)));
        % end

        % d = obj.blackboard.getLastData('visualLocationHypotheses').data;
        % detected_sources = d('detected_sources');
        % if ~isempty(detected_sources)
        %     dif = abs(theta-detected_sources);
        %     pos = find(dif <= obj.sensitivity);
        %     if ~isempty(pos)
        %         theta = detected_sources(pos);
        %     end
        % end
    elseif obj.RIR.nb_objects > 0 && ~isempty(obj.RIR.environments{end}.present_objects)
        % perfs = find(arrayfun(@(x) ~isPerformant(obj, x, 'Object'), 1:obj.RIR.nb_objects));
        perfs = find(arrayfun(@(x) ~isPerformant(obj, x, 'Object'), obj.RIR.environments{end}.present_objects));
        if ~isempty(perfs)
            theta = getObject(obj, perfs(1), 'theta');
            theta = theta(end);
        % elseif all(perfs == 1) && ~isempty(perfs)
        else
            theta = 0;
        % else
        %     theta = getLocalisationOutput(obj);
        end
    else
        theta = getLocalisationOutput(obj);
    end

    obj.motor_order(end+1) = theta;

    if numel(obj.head_position) > 1
        obj.head_position(end+1) = mod(obj.head_position(end)+theta, 360);
    else
        obj.head_position(end+1) = theta;
    end
    
    obj.RIR.head_position = obj.head_position;

    obj.computeSHM();

    obj.robot.rotateHead(theta, 'absolute');

    % disp(['motorOrder: ', num2str(theta)]);
    % disp(['headOrientation: ', num2str(currentHeadOrientation)]);
    % disp(num2str(getLocalisationOutput(obj.bbs)));
    
    keySet = {'currentHeadOrientation', 'theta'};
    valueSet = {currentHeadOrientation, theta};
    
    motorOrder = containers.Map(keySet, valueSet);
    
    obj.blackboard.addData('motorOrder', motorOrder,...
                           false, obj.trigger.tmIdx);
    notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
end

function bool = isFocusedObjectPresent (obj, focus)
    if obj.RIR.nb_objects == 0 && focus ~= 0
        bool = false;
    elseif getObject(obj, focus, 'presence')
        bool = true;
    else
        bool = false;
    end
end

function computeSHM (obj)
    if numel(obj.motor_order) > 1
        if obj.motor_order(end-1) ~= obj.motor_order(end) && obj.motor_order(end) > 0
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