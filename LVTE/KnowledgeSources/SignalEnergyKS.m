
classdef SignalEnergyKS < AuditoryFrontEndDepKS
    % LocationKS calculates posterior probabilities for each azimuth angle
    % and generates LocationHypothesis when provided with spatial 
    % observation

    properties (SetAccess = private)
        blocksize_s;
    end

    methods
        function obj = SignalEnergyKS()
            param = genParStruct(...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 8000, ...
                'fb_nChannels', 32, ...
                'rm_decaySec', 0, ...
                'ild_wSizeSec', 20E-3, ...
                'ild_hSizeSec', 10E-3, ...
                'rm_wSizeSec', 20E-3, ...
                'rm_hSizeSec', 10E-3, ...
                'cc_wSizeSec', 20E-3, ...
                'cc_hSizeSec', 10E-3);
            requests{1}.name = 'ild';
            requests{1}.params = param;
            requests{2}.name = 'itd';
            requests{2}.params = param;
            requests{3}.name = 'time';
            requests{3}.params = param;
            requests{4}.name = 'ic';
            requests{4}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.blocksize_s = 0.5;
            obj.invocationMaxFrequency_Hz = inf;
        end

        
        function [bExecute, bWait] = canExecute(obj)
            
            bExecute = true;
            bWait = false;
        end

        function execute(obj)
            afeData = obj.getAFEdata();
            signal = afeData(3);
            
            sig=signal{1,1}.getSignalBlock(0.25,obj.timeSinceTrigger);
            energy = 0;
            for ii=1:numel(signal)
                energy = energy + std(signal{ii}.getSignalBlock(0.25,obj.timeSinceTrigger));
            end
            fprintf('Signal length: %i, energy is: %f\n',size(sig,1),energy);
            obj.blackboard.addData( 'signalEnergy', energy, false, obj.trigger.tmIdx );
            notify(obj, 'KsFiredEvent');
        end

   
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
