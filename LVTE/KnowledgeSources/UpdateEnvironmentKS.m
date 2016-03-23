classdef UpdateEnvironmentKS < AbstractKS
    % RotationKS decides how much to rotate the robot head

    properties (SetAccess = private)
        rotationScheduled = false;    % To avoid repetitive head rotations
        robot;                        % Reference to a robot object
        firstRun=true;
    end

    methods
        function obj = UpdateEnvironmentKS(robot)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            obj.robot = robot;            
        end

        function [b, wait] = canExecute(obj)
            b = true;
            wait = false;            
        end

        
        function setInvocationFrequency(obj,fI)
            obj.invocationMaxFrequency_Hz=fI;
        end
        
        function execute(obj)
            if (obj.firstRun)
                obj.blackboard.addData('auditoryCategoryList',obj.robot.auditoryCategoryList,true,obj.trigger.tmIdx);
                obj.blackboard.addData('visualCategoryList',obj.robot.visualCategoryList,true,obj.trigger.tmIdx);                
                obj.blackboard.addData('auditoryGroundTruthVector',obj.robot.auditoryGTVector,true,obj.trigger.tmIdx);
                obj.firstRun=false;
            end
            obj.robot.updateTime(obj.trigger.tmIdx);
            obj.robot.sketchRoom();
            fprintf('time is: %f\n',obj.trigger.tmIdx);
            notify(obj, 'KsFiredEvent');
            
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
