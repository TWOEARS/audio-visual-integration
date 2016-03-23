classdef VisualDisplayKS < AbstractKS
    
    properties (SetAccess = private)
        robot;
        fromScratch=true;
        signalStart=1;
        signalStop;
        
        categoryColors;
        categoryMap;
        categoryIndices;
    end

    methods
        function obj = VisualDisplayKS(robot)
            obj = obj@AbstractKS(); 
            obj.robot=robot;
            obj.invocationMaxFrequency_Hz=inf;
            
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
        
        
        %% execute functionality
        function [b, wait] = canExecute( obj )
            b = true;
            wait = false;
        end
        
        function execute(obj)
            
            scenarioDuration=obj.robot.duration;
            
            

            visualCategoryList=obj.blackboard.getData('visualCategoryList');


            figure(5);
            set(gcf,'name','Visual Classifier Output');
            t=linspace(0,scenarioDuration,scenarioDuration*obj.robot.SampleRate);
            if (obj.fromScratch)
                clf;
                hold on;
                fill=zeros(scenarioDuration*obj.robot.SampleRate,1);

                ylim([-0.3 1]);
                plot(t,fill);


                setappdata(gca,'LegendColorbarManualSpace',1);
                setappdata(gca,'LegendColorbarReclaimSpace',1);

                sVector=[];
                lVector=[];
                lMapVector={};
                indexVector=[];


                for i=1:size(visualCategoryList.data,1)
                    p=plot(0,0,':','Color',obj.categoryColors{i});
                    sVector=[sVector p];
                    lVector=[lVector visualCategoryList.data(i)];
                    lMapVector{1,i}=visualCategoryList.data{i};
                    indexVector=[indexVector,i];
                end

                obj.categoryMap=containers.Map(lMapVector,zeros(1,size(lMapVector,2)));
                obj.categoryIndices=containers.Map(lMapVector,indexVector);

                legend(sVector,lVector);
                obj.fromScratch=false;
            end

             obj.signalStop=obj.signalStart+obj.robot.BlockSize-1;
             if (obj.signalStop>size(t,2))
                 obj.signalStop=size(t,2);
             end
             
             try
                 visualIdentityHypotheses=obj.blackboard.getLastData('visualIdentityHypotheses').data;
             
                 for i=1:size(visualCategoryList.data,1)
                     category=visualCategoryList.data{i};
                     probability=visualIdentityHypotheses(category);
                     plot([t(1,obj.signalStart) t(1,obj.signalStop)],[obj.categoryMap(category) probability],':','Color',obj.categoryColors{obj.categoryIndices(category)});                
                     obj.categoryMap(category)=probability;
                 end
                 
             catch
                 fprintf('no visual identity hypotheses so far!\n');
             end
             
            obj.signalStart=obj.signalStop+1;
        end

    end
    
end
