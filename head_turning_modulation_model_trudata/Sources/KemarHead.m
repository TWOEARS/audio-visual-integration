% 'KemarHead' class
% This class represents the artificial Kemar head that is attached to the
% robotic platform.
% 
% Author: Thomas Walther
% Date: 21.10.15
% Rev. 1.0

classdef KemarHead < handle
   
   properties (Access = public)
        
       % As this is an experimental system, all of the class members are
        % currently public, in order to have easy access.
        % This will be changed in later system versions.
        
        HRTFs;          % the HRTFs used for SSR processing
        parent;         % the Environment
        phi=0;          % the current rotation angle (azimuth)      
        zPosition;      % the z position of the head
        
    end
    
    
    
    methods (Access = public)
        
        
        %   the constructor
        %   inputs:
        %       owner:      the parent environment
        function obj = KemarHead(parent)
            
            % hardcoded HRTFs, will be made accessible in later system
            % versions
            obj.HRTFs=['impulse_responses/qu_kemar_anechoic/' ...
                'QU_KEMAR_anechoic_3m.sofa'];
            % set parent
            obj.parent=parent;            
            % fix head z position at 1.8 meters,more flexibility will be
            % introduced in later system versions
            obj.zPosition=1.8;
        end   
        
        
        % Set the current head roation in absolute system coordinates
        % inputs:
        %       phi:        the azimuth to be set
        function setPhi(obj,phi)
            obj.phi=phi;
        end
        
        
        % Rotates the Kemar head relative to the robot platform
        % inputs:
        %       phi:        the relative azimuth angle
        function rotateRelative(obj,phi)
            obj.phi=obj.phi+phi;
        end
        
    end
    
end

