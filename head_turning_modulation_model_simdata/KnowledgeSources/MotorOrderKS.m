% 'MotorOrderKS' class
% Author: Benjamin Cohen-Lhyver
% Date: 01.06.16
% Rev. 1.0
classdef MotorOrderKS < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    head_position = [];
    motor_order = [];
    htm;
    RIR;
    FCKS;

    shm = 0;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = MotorOrderKS (htm, FCKS)
	obj.htm = htm;
    obj.RIR = htm.RIR;
    obj.FCKS = FCKS;
    obj.head_position = 0;
end
% === CONSTRUCTOR [END] === %

function execute (obj)
    % --- If no sound -> make the head turn to 0° (resting state)
    % --- Change to getLastHypothesis
    focus = obj.FCKS.focus(end);

    if focus ~= 0
        theta = getObject(obj, focus, 'theta');
        theta = theta(end);
    elseif focus == 0
        theta = -obj.head_position(end);
    end

    % if ~obj.isFocusedObjectPresent(focus)
        % theta = -obj.head_position(end);
    % end

    obj.motor_order(end+1) = theta;
    

    if numel(obj.head_position) > 1
        obj.head_position(end+1) = mod(obj.head_position(end)+theta, 360);
    else
        obj.head_position(end+1) = theta;
    end
    
    obj.RIR.head_position = obj.head_position;

    obj.computeSHM();
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


% ===================== %
% === METHODS [END] === %
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %
end