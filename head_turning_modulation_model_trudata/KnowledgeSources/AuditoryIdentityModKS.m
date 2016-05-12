classdef AuditoryIdentityModKS < AuditoryFrontEndDepKS
    
    properties (SetAccess = private)
        modelname;
        model;                 % classifier model
        featureCreator;
    end

    methods
        function obj = AuditoryIdentityModKS( modelName, modelDir )
            modelFileName = [modelDir filesep modelName];
            v = load( [modelFileName '.model.mat'] );
            if ~isa( v.featureCreator, 'featureCreators.Base' )
                error( 'Loaded model''s featureCreator must implement featureCreators.Base.' );
            end
            obj = obj@AuditoryFrontEndDepKS( v.featureCreator.getAFErequests() );
            obj.featureCreator = v.featureCreator;
            obj.model = v.model;
            obj.modelname = modelName;
            obj.invocationMaxFrequency_Hz = inf;
        end
        
        function setInvocationFrequency( obj, newInvocationFrequency_Hz )
            obj.invocationMaxFrequency_Hz = newInvocationFrequency_Hz;
        end
        
        %% utility function for printing the obj
        function s = char( obj )
            s = [char@AuditoryFrontEndDepKS( obj ), '[', obj.modelname, ']'];
        end
        
        %% execute functionality
        function [b, wait] = canExecute( obj )
            b = true;
            wait = false;
        end
        
        function execute( obj )
            afeData = obj.getAFEdata();
            afeData = obj.featureCreator.cutDataBlock( afeData, obj.timeSinceTrigger );
  
  
            x = obj.featureCreator.makeDataPoint( afeData );
            [d, score] = obj.model.applyModel( x );
            
            if obj.blackboard.verbosity > 0
                fprintf( 'Identity Hypothesis: %s with %i%% probability.\n', ...
                    obj.modelname, int16(score(1)*100) );
            end
            
            signalEnergy=obj.blackboard.getLastData('signalEnergy').data;
            if (signalEnergy<0.01)
                score(1)=0.0;
            end
            
            fprintf('Identity found: %s, with reliability: %i\n',obj.modelname,int16(score(1)*100));
            
            identHyp = IdentityHypothesis( ...
                obj.modelname, score(1), obj.featureCreator.labelBlockSize_s );
            obj.blackboard.addData( 'auditoryIdentityHypotheses', identHyp, true, obj.trigger.tmIdx );
            notify( obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ) );
        end
    end
end