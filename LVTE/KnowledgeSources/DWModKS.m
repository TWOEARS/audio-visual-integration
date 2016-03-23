classdef DWModKS < AbstractKS
    
    properties (SetAccess = private)
        robot;        
    end

    methods
        function obj = DWModKS(robot)
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
            fprintf('now in DWMod evaluation\n');
            notify(obj, 'KsFiredEvent');
        end
    end
    
end
