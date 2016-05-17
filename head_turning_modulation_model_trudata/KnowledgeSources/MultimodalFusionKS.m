% 'MultimodalFusionKS' class
% TO BE DONE!
% Author: Thomas Walther and Benjamin Cohen-l'hyver
% Date: 21.10.15
% Rev. 1.0

classdef MultimodalFusionKS < AbstractKS
    
    properties (SetAccess = private)
        robot;        
    end

    methods
        function obj = MultimodalFusionKS(robot)
            obj = obj@AbstractKS(); 
            obj.robot=robot;
            obj.invocationMaxFrequency_Hz=inf;
            
        end
        
        
        %% execute functionality
        function [b, wait] = canExecute( obj )
            b = true;
            wait = false;
        end
        
        function execute(obj)
            notify(obj, 'KsFiredEvent');
        end
    end
    
end
