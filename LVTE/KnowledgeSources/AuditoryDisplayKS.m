
classdef AuditoryDisplayKS < AuditoryFrontEndDepKS
    % LocationKS calculates posterior probabilities for each azimuth angle
    % and generates LocationHypothesis when provided with spatial 
    % observation

    properties (SetAccess = private)
        fromScratch=true;
        signalStart=1;
        signalStop;
        
        outputSignal;
        robot;
        categoryColors;
        categoryMap;
        categoryIndices;
        
    end

    methods
        function obj = AuditoryDisplayKS(robot)
            
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
            obj.robot=robot;
            
            obj.invocationMaxFrequency_Hz = inf;
            obj.categoryColors={...
                                [0,0,0];...
                                [1,0,0];...
                                [0,1,0];...
                                [1,1,0];...
                                [0,0,1];...
                                [1,0,1];...
                                [0,1,1];...
                                [1,1,1];...
            };
            
            
        end

        
        function [bExecute, bWait] = canExecute(obj)
            
            bExecute = true;
            bWait = false;
        end

        function execute(obj)
            afeData = obj.getAFEdata();
            signal = afeData(3);
            
            scenarioDuration=obj.robot.duration;
            
            if (length(signal{1,1}.Data)>0)
            
                sig=signal{1,1}.getSignalBlock(obj.robot.BlockSize/obj.robot.SampleRate);
                obj.outputSignal=[obj.outputSignal;sig];

                % we get that from all available time instances, i.e. in this
                % case from only t=0!
                auditoryGTVector=obj.blackboard.getData('auditoryGroundTruthVector');
                auditoryCategoryList=obj.blackboard.getData('auditoryCategoryList');


                figure(4);
                set(gcf,'name','Auditory Classifier Output');



                t=linspace(0,scenarioDuration,scenarioDuration*obj.robot.SampleRate);
                if (obj.fromScratch)
                    clf;
                    hold on;
                    fill=zeros(scenarioDuration*obj.robot.SampleRate,1);

                    %axis([0 scenarioDuration*obj.robot.SampleRate -0.3 0.3]);

                    ylim([-0.3 1]);
                    plot(t,fill);




                    
                    setappdata(gca,'LegendColorbarManualSpace',1);
                    setappdata(gca,'LegendColorbarReclaimSpace',1);

                    outSignal=plot(0,0,'b');
                    sVector=[outSignal];
                    lVector=['signal(LE)'];
                    lMapVector={};
                    indexVector=[];


                    for i=1:size(auditoryCategoryList.data,1)
                        p=plot(0,0,'Color',obj.categoryColors{i});
                        sVector=[sVector p];
                        lVector=[lVector auditoryCategoryList.data(i)];
                        lMapVector{1,i}=auditoryCategoryList.data{i};
                        indexVector=[indexVector,i];
                    end

                    obj.categoryMap=containers.Map(lMapVector,zeros(1,size(lMapVector,2)));
                    obj.categoryIndices=containers.Map(lMapVector,indexVector);

                    legend(sVector,lVector);
                    obj.fromScratch=false;
                    
                    
                    
                    for i=2:size(auditoryGTVector.data,1) % no silence source!
                        for j=2:5:size(auditoryGTVector.data{i},2)

                            x=auditoryGTVector.data{i}{j}/scenarioDuration;
                            y=0.05;
                            w=(auditoryGTVector.data{i}{j+3}-auditoryGTVector.data{i}{j})/scenarioDuration;
                            h=0.05;
%                             a=annotation( 'textbox',...
%                                         [x y w h],...
%                                         'String',{auditoryGTVector.data{i}{j+1}},...
%                                         'FontSize',8,...
%                                         'FontName','Arial',...
%                                         'HorizontalAlignment','center',...
%                                         'VerticalAlignment','middle',...
%                                         'EdgeColor',[0 0 0],...
%                                         'LineWidth',1,...
%                                         'BackgroundColor',[0.5  0.5 0.5],...
%                                         'Color',[0 0 0]);

                            a=annotation( 'textbox',...
                                        [x y w h],...
                                        'String','',...
                                        'FontSize',8,...
                                        'FontName','Arial',...
                                        'HorizontalAlignment','center',...
                                        'VerticalAlignment','middle',...
                                        'EdgeColor',[0 0 0],...
                                        'LineWidth',1,...
                                        'BackgroundColor',obj.categoryColors{obj.categoryIndices(auditoryGTVector.data{i}{j+1})},...
                                        'Color',[0 0 0]);

                            set(a,'parent',gca);
                            set(a,'position',[auditoryGTVector.data{i}{j} -0.05 auditoryGTVector.data{i}{j+3}-auditoryGTVector.data{i}{j} 0.05]);

                            
                            b=annotation( 'textbox',...
                                        [x y w h],...
                                        'String','',...
                                        'FontSize',8,...
                                        'FontName','Arial',...
                                        'HorizontalAlignment','center',...
                                        'VerticalAlignment','middle',...
                                        'EdgeColor',[0 0 0],...
                                        'LineWidth',1,...
                                        'BackgroundColor',obj.categoryColors{obj.categoryIndices(auditoryGTVector.data{i}{j+1})},...
                                        'Color',[0 0 0]);

                            set(b,'parent',gca);
                            set(b,'position',[auditoryGTVector.data{i}{j} -0.1 auditoryGTVector.data{i}{j+3}-auditoryGTVector.data{i}{j} 0.05]);
                            if (strcmp(auditoryGTVector.data{i}{j+2},'acceptable'))
                                set(b,'BackgroundColor',[0 1 0]);
                            else
                                set(b,'BackgroundColor',[1 0 0]);
                            end
                            
                            
                            
                        end
                    end
                    
                    
                    
                end

                obj.signalStop=obj.signalStart+size(sig,1)-1;
                if (obj.signalStop>size(t,2))
                    obj.signalStop=size(t,2);
                end
                plot(t(1,obj.signalStart:obj.signalStop),sig(1:obj.signalStop-obj.signalStart+1),'b');

                try
                    identityHypotheses=obj.blackboard.getLastData('auditoryIdentityHypotheses').data;
                    for i=1:size(identityHypotheses,2)
                        plot([t(1,obj.signalStart) t(1,obj.signalStop)],[obj.categoryMap(identityHypotheses(i).label) identityHypotheses(i).p],'Color',obj.categoryColors{obj.categoryIndices(identityHypotheses(i).label)});                
                        obj.categoryMap(identityHypotheses(i).label)=identityHypotheses(i).p;
                    end
                catch
                    fprintf('no identity hypotheses so far!\n');
                end

                obj.signalStart=obj.signalStop+1;
            end
            
        end

   
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
