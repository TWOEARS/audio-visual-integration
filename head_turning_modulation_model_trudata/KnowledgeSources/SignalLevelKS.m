

% 'SignalLevelKS' class
% This knowledge source measures the signal level, and puts it on the
% blackboard.
% Author: Thomas Walther
% Date: 21.10.15
% Rev. 1.0

classdef SignalLevelKS < AuditoryFrontEndDepKS

    properties (SetAccess = private)
    end

    methods
        % the constructor
        function obj = SignalLevelKS()
            % prepare AFE, standard parameters
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
            % call KS each frame
            obj.invocationMaxFrequency_Hz = inf;
        end

        
        function [bExecute, bWait] = canExecute(obj)
            % self-explanatory, source is triggered each frame
            bExecute = true;
            bWait = false;
        end

        function execute(obj)
            % get AFE data (time signal)
            afeData = obj.getAFEdata();
            signal = afeData(3);
            
            % extract the current signal block
            sig=signal{1,1}.getSignalBlock(0.25,obj.timeSinceTrigger);
            % return the signal variance, which can be seen as the
            % mean-free signal power
            % cf. http://www.dsprelated.com/freebooks/mdft/
            % Signal_Metrics.html
            energy = var(sig);
            % push the energy value to the blackboard
            obj.blackboard.addData( 'signalEnergy', energy,...
                false, obj.trigger.tmIdx );
            notify(obj, 'KsFiredEvent');
        end

   
    end
end


