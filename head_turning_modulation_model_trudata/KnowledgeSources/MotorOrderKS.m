classdef MotorOrderKS < AbstractKS

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    head_position = 0;
    head_position_hist = [];
    htm;
    robot;
    cpt = 0;
    last_movement = 0;

end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% ========================= %
% === CONSTRUCTOR [BEG] === %
% ========================= %
function obj = MotorOrderKS (robot)
    obj = obj@AbstractKS();
    obj.invocationMaxFrequency_Hz = inf;
	% obj.robot = htm.robot;
	% obj.htm = htm;
end

function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)
    currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;
    % --- If no sound -> make the head turn to 0° (resting state)
    htm = obj.blackboard.KSs{end-2};
    RIR = htm.RIR;
    focus = RIR.focus;

    obj.cpt = obj.cpt+1;
    
    if ~isSoundPresent(obj)
        theta = -currentHeadOrientation;
        % fprintf('\nMotor order: 0deg (resting state)\n') ;
    % --- Turn to the sound source
    elseif focus ~= 0 && isFocusedObjectPresent(obj)
        % --- Smoothing the head movements
        if obj.cpt - obj.last_movement >= getInfo('smoothing_head_movements')
            obj.last_movement = obj.cpt;
            theta = RIR.motorOrder();
        else
            theta = 0 ;
        end
    elseif isempty(RIR.getMFI().categories)
        if obj.cpt - obj.last_movement >= 5
            theta = obj.RIR.getLastObj('theta') ;
            obj.last_movement = obj.cpt ;
        else
            theta = 0 ;
        end
    else
        theta = 0 ;
    end

    obj.robot.moveRobot(0.2, 0.2, 0);
    
%     maxAzimuth = theta + currentHeadOrientation ;
%     maxAzimuth = mod(maxAzimuth, 360) ;
%     obj.robot.robotController.omegaMax = 1000000.0 ;
%     obj.robot.robotController.goalAzimuth = maxAzimuth ;
%     obj.robot.robotController.finishedPlatformRotation = false ;
end


function moveHead (obj)
	robot = obj.htm.robot;
    % --- If no sound -> make the head turn to 0° (resting state)
    focus = robot.focus;

    if obj.isFocusedObjectPresent() && focus ~= 0
        % theta = obj.motorOrder();
        theta = getObject(robot, robot.focus, 'theta');
        % obj.robot.updateAngle(0);
        setObject(robot, 0, 'theta', 0);
        %robot.getLastObj().theta = 0;
    else
        theta = -obj.head_position;
    end
    obj.head_position = mod(theta+obj.head_position, 360) ;
    obj.head_position_hist(end+1) = obj.head_position;
end

function bool = isFocusedObjectPresent (obj)
	robot = obj.htm.robot;
    if isempty(robot.getEnv().present_objects)
        bool = false ;
    elseif find(robot.focus == robot.getEnv().present_objects)
        bool = true ;
    else
        bool = false ;
    end
end

end

end