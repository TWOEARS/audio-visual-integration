
% 'TurnHeadKS' class
% This knowledge source starts a continuous head movement towards a
% perceived, putative auditoy object.
% Author: Thomas Walther & Benjamin Cohen-Lhyver
% Date: 21.10.15
% Rev. 1.0

classdef HeadRotationKS < AbstractKS
    

    properties (SetAccess = private)
        robot;                        % Reference to the robot environment
        goalAzimuth;                  % The azimuth that the robot should
                                      % turn to.
        omegaMax;                     % The maximum angular velocity[deg/s]        
    end

    
    
    methods
        % the constructor
        function obj = HeadRotationKS(robot)
            obj = obj@AbstractKS();
            % run in each frame IFF the robot is ready to accept the motor
            % command, i.e. is not currently rotating
            obj.invocationMaxFrequency_Hz = inf;
            % set member variables
            obj.robot = robot;
            obj.goalAzimuth=0;
            % this is quite fast, but necessary to focus the hypothetical
            % auditory stimulus in acceptable time
            obj.omegaMax=10000.0;
        
        end

        function [b, wait] = canExecute(obj)
            % self-explanatory, see above
            b = obj.robot.robotController.finishedPlatformRotation;
            wait = false;                
        end

        
        
        function execute(obj)
            
            % init new rotation
            auditoryObjectHypothesis=obj.blackboard.getLastData(...
                            'auditoryObjectHypothesis').data;
            obj.goalAzimuth=auditoryObjectHypothesis.azimuth;
            fprintf('initiating rotation towards %f degrees\n',...
                        obj.goalAzimuth);

            
                    
            % enable the robot's actuation            
            obj.robot.robotController.goalAzimuth=obj.goalAzimuth;
            obj.robot.robotController.finishedPlatformRotation=false;

            
        end
    end
end

