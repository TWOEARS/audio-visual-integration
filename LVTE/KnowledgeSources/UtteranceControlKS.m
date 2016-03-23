
classdef UtteranceControlKS < AbstractKS
    % LocationKS calculates posterior probabilities for each azimuth angle
    % and generates LocationHypothesis when provided with spatial 
    % observation

    properties (SetAccess = private)
        blocksize_s;
        outputSignal;
        robot;
    end

    methods
        function obj = UtteranceControlKS(robot)
            
            
            obj = obj@AbstractKS();
            obj.robot=robot;
            obj.invocationMaxFrequency_Hz = inf;
        end

        
        function [bExecute, bWait] = canExecute(obj)
            
            bExecute = true;
            bWait = false;
        end

        function execute(obj)
            fprintf('preparing utterances\n');
            
            
            sourceID=floor(rand()*(size(obj.robot.sources,1)-1))+2;

            % find source visual category
            visCat=obj.robot.sources{sourceID,1}.getVisualCategoryAtTime(obj.trigger.tmIdx);

            for j=1:size(obj.robot.acceptableAVPairs,1)
                if (strcmp(obj.robot.acceptableAVPairs{j}{1},visCat))
                    fprintf('pair: (%s,%s)\n',visCat,h.acceptableAVPairs{j}{2});
                    stimulus=obj.robot.getStimulusForAuditoryLabel(obj.robot.acceptableAVPairs{j}{2},1);
                    stimulus=strcat(obj.robot.pathToAudioFiles,stimulus);
                    [sig, fs] = audioread(stimulus);
                    s = resample(sig, obj.robot.SampleRate, fs);
                    length=size(s,1)/obj.robot.SampleRate;                            

                    obj.robot.sources{sourceID}.auditorySchedule{size(obj.robot.sources{sourceID,1}.auditorySchedule,2)+1}={t,'on',obj.robot.acceptableAVPairs{j}{2},1,'acceptable'};
                    obj.robot.sources{sourceID}.auditorySchedule{size(obj.robot.sources{sourceID,1}.auditorySchedule,2)+1}={t+length,'off'};
                    break;
                end
            end
            

            
            
            
        end

   
    end
end


