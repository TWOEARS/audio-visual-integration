classdef Source < handle
    
    properties (Access = public)
        parent;
        name; % the source's name
        volume;
        weight; % the influence of this source
        position; % the source position in meters
        stimulus; % the wav file for this source
        signal; % the signal extracted from the stimulus file
        index; % the index of the source in the SSR
        
        visualSchedule;
        auditorySchedule;
        isActive;
        isContinuous;
        
        visualCategory;
        visualCategoryInstance;
        auditoryCategory;
        auditoryCategoryInstance;
        isControllable=1;
    end
    
    
    
    methods (Access = public)
        
        function h = Source(owner,n,p,s)
            h.parent=owner;
            h.name=n;
            h.position=p;
            h.stimulus=s;
            str=sprintf('Source %s initiated...',h.name);
            disp(str);
            
            h.isActive=0;
            h.isContinuous=0;
            h.volume=1.0;
        end   
        
        
        function retCat=getVisualCategoryAtTime(h,t)
            currentCategory=[];
            for i=1:size(h.visualSchedule,1)
                if h.visualSchedule{i}{1} < t
                    currentCategory=h.visualSchedule{i}{2};
                end
            end        
            retCat=currentCategory;
        end
        
        
        function setAuditorySchedule(h,s)
            h.auditorySchedule=s;
        end
        
        function setVisualSchedule(h,s)
            h.visualSchedule=s;
        end
        
        
        function setIndex(h,ind)
            h.index=ind;
        end
        
        function startPlaying(h)
            
            if (h.isControllable)
                h.stimulus=h.parent.getStimulusForAuditoryLabel(h.auditoryCategory,h.auditoryCategoryInstance);                
                h.stimulus=strcat(h.parent.pathToAudioFiles,h.stimulus);
            else
                h.stimulus=strcat(h.stimulus);
            end
            
            
            [sig, fs] = audioread(h.stimulus);
            s = resample(sig, h.parent.fsHz, fs);
            m=max(abs(s));
            % use only the first channel here. this is somewhat awkward,
            % has to be handled by using only mono sources            
            h.signal = s(:,1) ./ m(1);
            h.parent.sim.Sources{h.index,1}.AudioBuffer.removeData();
            h.parent.sim.Sources{h.index,1}.AudioBuffer.appendData(h.signal);
            h.isActive=1;
        end
        
        function stopPlaying(h)
            h.parent.sim.Sources{h.index,1}.AudioBuffer.removeData();
            h.isActive=0;
        end
        
        
    end
end

