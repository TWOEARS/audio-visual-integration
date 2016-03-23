classdef RotationModKS < AbstractKS
    % RotationKS decides how much to rotate the robot head

    properties (SetAccess = private)
        rotationScheduled = false;    % To avoid repetitive head rotations
        robot;                        % Reference to a robot object
        targetPhi=[];
    end

    methods
        function obj = RotationModKS(robot)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            obj.robot = robot;
        end

        function [b, wait] = canExecute(obj)
            b = true;
            wait = false;
%             if ~obj.rotationScheduled
%                 b = true;
%                 obj.rotationScheduled = true;
%             end

        end

        function execute(obj)
            
            % Workout the head rotation angle so that the head will face
            % the most likely source location.
            % For some impulse responses like BRIR the possible head rotations might be
            % limited. Those maximum values of possible head rotation are accessable from
            % the robot.
            %
            % Set head rotation to the point of most likely perceived source direction
            locHyp = obj.blackboard.getData('locationHypotheses', ...
                obj.trigger.tmIdx).data;
            [~,idx] = max(locHyp.posteriors);
            perceivedAngle = locHyp.locations(idx);
%             if perceivedAngle <= 180
%                 headRotateAngle = perceivedAngle;
%             else
%                 headRotateAngle = perceivedAngle - 360;
%             end
%             % Ensure minimal head rotation
%             minAngle = 0;
%             if abs(headRotateAngle)<minAngle
%                 headRotateAngle = sign(randn(1)) * minAngle;
%             end
%             % Ensure head rotation is possible and add some jitter if maximum is
%             % approached
%             headOrientation = obj.blackboard.getData( ...
%                'headOrientation', obj.trigger.tmIdx).data;
%             maxLimitHeadRotation = obj.robot.AzimuthMax - headOrientation;
%             minLimitHeadRotation = obj.robot.AzimuthMin - headOrientation;
%             if headRotateAngle > maxLimitHeadRotation
%                 headRotateAngle = round(maxLimitHeadRotation - 5*rand);
%             elseif headRotateAngle < minLimitHeadRotation
%                 headRotateAngle = round(minLimitHeadRotation + 5*rand);
%             end
% 
%             % Rotate head with a relative angle
%             if (headRotateAngle>10)
%                 headRotateAngle=10;
%             end
%             
%             
%             if (headRotateAngle<-10)
%                 headRotateAngle=-10;
%             end
            currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;            
            
           % fprintf('now at azimuth: %f -> trying to rotate to azimuth: %f\n',currentHeadOrientation,perceivedAngle);
%            obj.robot.rotateHead(headRotateAngle, 'relative');

            % Rotate head with a relative angle
            
            steeringAngle=perceivedAngle+currentHeadOrientation;
            
            steeringAngle=mod(steeringAngle,360);
            obj.robot.robotController.goalPhi=steeringAngle;

            
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1: