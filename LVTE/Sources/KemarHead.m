classdef KemarHead < handle
   
   properties (Access = public)
        
        parent;
        sofaObj;
        angularVelocity=60.0;
        zPosition=0;        
        phi=0;
        theta=0;
        goalPhi=0;
    end
    
    
    
    methods (Access = public)
        
        function h = KemarHead(parent)
            disp('Kemar head instantiated...');
            h.parent=parent;            
        end   
        
        function setPhi(h,phi)
            h.phi=phi;
        end
        
        
        function setTheta(h,theta)
            h.theta=theta;
        end
        
        function setZPosition(h,z)
            h.zPosition=z;
        end
        
        function rotateLeft(h,dT)
            dA=dT*h.angularVelocity;
            h.phi=h.phi+dA;
        end
        
        function rotateRelative(h,angle)
            h.phi=h.phi+angle;
        end
        
        
        function rotateRight(h,dT)
            dA=dT*h.angularVelocity;
            h.phi=h.phi-dA;
        end
        
        
    end
    
end

