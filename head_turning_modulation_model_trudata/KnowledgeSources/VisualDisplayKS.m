
% 'VisualDisplayKS' class
% This knowledge source allows to display the results of visual
% classification in human-readable form.
% Author: Thomas Walther
% Date: 21.10.15
% Rev. 1.0

classdef VisualDisplayKS < AbstractKS
    
    properties (SetAccess = private)
        robot;              % the interface to the robot environement     
        fromScratch;   % is the plot to be created from scratch?
        signalStart;      % the sample of the overall signal to start
                            % plotting from
        signalStop;         % the sample of the overall signal where
                            % plotting is halted
        
        categoryColors;     % a constant for color coding the plotting
                            % results
        categoryMap;        % this map allow to plot a connected line
                            % instead of single pixels
        categoryIndices;    % a map that defines the index of each category
                            % by looking up from the category's name
    end

    methods
        function obj = VisualDisplayKS(robot)
            obj = obj@AbstractKS(); 
            % prepare member variables
            obj.robot=robot;
            obj.fromScratch=true;
            obj.signalStart=1;
            % this KS has to run each frame
            obj.invocationMaxFrequency_Hz=inf;
            % set up the category color coding scheme (currently, this can
            % sketch up to 8 color, should be sufficient for now)
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
            % self-explanatory, source keeps running
            b = true;
            wait = false;
        end
        
        function execute(obj)
            
            
            % get the scenario duration
            scenarioDuration=obj.robot.duration;
            % get the visual category list
            visualCategoryList=obj.robot.visualCategoryList;

             % select figure 3 for plotting auditory information
            figure(3);
            % name the figure window
            set(gcf,'name','Visual Classifier Output');
            
            % define a linear timescale for the complete scenario
            % duration
            t=linspace(0,scenarioDuration,scenarioDuration*obj.robot.SampleRate);
            
             % iff the plot has to be generated from scratch
            if (obj.fromScratch)
                
                % clear the figure
                clf;
                % switch to overlay plotting
                hold on;
                % prepare an empty vector to draw the y=0 line
                fill=zeros(scenarioDuration*obj.robot.SampleRate,1);
                plot(t,fill);
                
                % set the y limits
                ylim([-0.3 1]);

                % to gain better performance
                setappdata(gca,'LegendColorbarManualSpace',1);
                setappdata(gca,'LegendColorbarReclaimSpace',1);

                 % prepare the legend
                sVector=[];
                lVector=[];
                lMapVector={};
                indexVector=[];


                % populate the legend with all auditory categories
                % prepare category vectors for map construction
                for i=1:size(visualCategoryList,1)
                    p=plot(0,0,':','Color',obj.categoryColors{i});
                    sVector=[sVector p];
                    lVector=[lVector visualCategoryList(i)];
                    lMapVector{1,i}=visualCategoryList{i};
                    indexVector=[indexVector,i];
                end

                % construct the maps for coninuous plotting and fast
                % category index access
                obj.categoryMap=containers.Map(lMapVector,zeros(1,size(lMapVector,2)));
                obj.categoryIndices=containers.Map(lMapVector,indexVector);

                % draw the legend
                legend(sVector,lVector);
                % dont repeat this loop
                obj.fromScratch=false;
            end
            
             % and update the stop index
             obj.signalStop=obj.signalStart+obj.robot.BlockSize-1;
             % dont run over the simulation data limit
             if (obj.signalStop>size(t,2))
                 obj.signalStop=size(t,2);
             end
             
             
             % overlay the visual classifier results. It can happen
             % that there is no result available, especially in the
             % beginning of the simulation. The try/catch block takes
             % that into account.
             try
                 visualIdentityHypotheses=obj.blackboard.getLastData('visualIdentityHypotheses').data;
             
                 for i=1:size(visualCategoryList,1)
                     category=visualCategoryList{i};
                     probability=visualIdentityHypotheses(category);
                     plot([t(1,obj.signalStart) t(1,obj.signalStop)],[obj.categoryMap(category) probability],':','Color',obj.categoryColors{obj.categoryIndices(category)});                
                     obj.categoryMap(category)=probability;
                 end
                 
             catch
                 
             end
            % update the start variable
            obj.signalStart=obj.signalStop+1;
        end

    end
    
end
