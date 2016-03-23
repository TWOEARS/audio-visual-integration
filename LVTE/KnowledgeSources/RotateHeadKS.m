classdef RotateHeadKS < AbstractKS
    % RotationKS decides how much to rotate the robot head

    properties (SetAccess = private)
        rotationScheduled = false;    % To avoid repetitive head rotations
        robot;                        % Reference to a robot object
    end

    methods
        function obj = RotateHeadKS(robot)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            obj.robot = robot;
        end

        function [b, wait] = canExecute(obj)
            b = false;
            wait = false;
            if ~obj.rotationScheduled
                b = true;
                obj.rotationScheduled = true;
            end
        end

        
        function setInvocationFrequency(obj,fI)
            obj.invocationMaxFrequency_Hz=fI;
        end
        
        function execute(obj)

            
            obj.robot.sketchRoom();
%             % Rotate head with a relative angle
%             obj.robot.rotateHead(headRotateAngle, 'relative');
% 
%             if obj.blackboard.verbosity > 0
%                 fprintf(['--%05.2fs [Rotation KS:] Commanded head to rotate about ', ...
%                          '%d degrees. New head orientation: %.0f degrees\n'], ...
%                         obj.trigger.tmIdx, headRotateAngle, ...
%                         obj.robot.getCurrentHeadOrientation);
%             end

            fprintf('Executing RotateheadKS\n');
            obj.rotationScheduled = false;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
