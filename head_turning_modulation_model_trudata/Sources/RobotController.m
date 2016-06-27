

% 'RobotController' class
% This class defines an interface to control the virtual robot platform.
% It allows motion control in azimuth and translation.
% Author: Thomas Walther
% Date: 21.10.15
% Rev. 1.0

classdef RobotController < handle
   
    % As this is an experimental system, all of the class members are
    % currently public, in order to have easy access.
    % This will be changed in later system versions.
        
    properties (Access = public)
        parent;             %   the parent Environment
        position=[0 0];     %   the position of the robot platform
        phi=0.0;            %   the current rotation angle of the platform
                            %   (azimuth)
        head;               %   a link to the Kemar head installed on the
                            %   robot platform
        length=0.5;         %   length of the robot platform
        width=0.4;          %   width of the robot platform
        height=0.1;         %   height of the robot platform
        goalAzimuth;        %   the azimuth that is to be reached by the
                            %   RotationKS
        finishedPlatformRotation;   % is the platform rotation finished?
        omegaMax;           %   the maximum angular velocity of the robot
                            %   platform
    end
    
    events
      goalAzimuthReached
    end
    
    methods (Access = public)
        
        %   the constructor
        %   inputs:
        %       parent:         the parent Environment
        function obj = RobotController(parent)
            disp('RobotController instantiated...'); 
            obj.parent=parent;
            obj.head=KemarHead(obj);
            obj.omegaMax=180.0;
            obj.finishedPlatformRotation=true;
        end   
        
        
        function rotateRelative(h,dPhi)
            h.phi=h.phi+dPhi;
        end

        
        
        % Actuate the robot controller and exert all necessary motion. All
        % actuator commands from knowledge sources should cause an action
        % here.
        % inputs:
        %       none
        function actuate(obj)        
            
            
            % IFF there is a goal phi, try to reach it
            if ~isempty(obj.goalAzimuth)
               
               % IFF the platform has to rotate
               if (~obj.finishedPlatformRotation)
                
                   if obj.goalAzimuth>180
                       obj.goalAzimuth=obj.goalAzimuth-360;
                   end
                   
                   currentAzimuth=obj.phi;

                   % calculate the maximum azimuth update
                   dPhi=(obj.parent.BlockSize/obj.parent.SampleRate)*...
                                obj.omegaMax;


                   % compute azimuthal difference
                   deltaPhi=obj.goalAzimuth-currentAzimuth;

                   % check for shortest rotation
                   if deltaPhi>180
                    deltaPhi=deltaPhi-360;
                   end


                   % limit the azimuth update
                   if (deltaPhi>dPhi)
                    deltaPhi=dPhi;
                   end

                   if (deltaPhi<-dPhi)
                    deltaPhi=-dPhi;
                   end

                   % update the head's azimuth
                   obj.parent.robotController.rotateRelative(deltaPhi);

                   
                   if obj.goalAzimuth==currentAzimuth
                       % objective reached, stop rotation 
                       obj.finishedPlatformRotation=true;
                       notify(obj,'goalAzimuthReached');
                   end
               end
            end
        end
        
    end
    
end

