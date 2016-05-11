

% 'AuditoryDisplay' class
% This knowledge source allows to display the results of auditory
% classification in human-readable form.
% Author: Thomas Walther
% Date: 21.10.15
% Rev. 1.0

classdef AuditoryDisplayKS < AuditoryFrontEndDepKS
    
    properties (SetAccess = private)
        
        fromScratch;        % is the plot to be created from scratch?
        outputSignal;       % the signal to be plotted
        signalStart;        % the sample of the overall signal to start
                            % plotting from
        signalStop;         % the sample of the overall signal where
                            % plotting is halted
        robot;              % the interface to the robot environement
        categoryColors;     % a constant for color coding the plotting
                            % results
        categoryMap;        % this map allow to plot a connected line
                            % instead of single pixels
        categoryIndices;    % a map that defines the index of each category
                            % by looking up from the category's name
        
    end

    methods
        function obj = AuditoryDisplayKS(robot)
            
            % invoke the AFE, necessary if the audio signal has to be
            % overlaid, standard parameters are used for AFE access
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
            
            % prepare member variables
            obj.fromScratch=true;
            obj.signalStart=1;
                        
            % this KS has to run each frame
            obj.invocationMaxFrequency_Hz = inf;
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

        
        function [bExecute, bWait] = canExecute(obj)
            	
            bExecute = true;
            bWait = false;
        end

        function execute(obj)
            % get the time signal from the AFE
            afeData = obj.getAFEdata();
            signal = afeData(3);
            
            % get the scenario duration
            scenarioDuration=obj.robot.duration;
            
            % if there is signal data from the AFE
            if (length(signal{1,1}.Data)>0)
            
                % get the current signal block (time domain)
                sig=signal{1,1}.getSignalBlock(obj.robot.BlockSize/...
                    obj.robot.SampleRate);
                % append the signal chunk to the output signal
                obj.outputSignal=[obj.outputSignal;sig];

                % get auditory category list and auditory category
                % instances
                auditoryGTVector=obj.robot.auditoryGTVector;
                auditoryCategoryList=obj.robot.auditoryCategoryList;

                % select figure 2 for plotting auditory information
                figure(2);
                % name the figure window
                set(gcf,'name','Auditory Classifier Output');


                % define a linear timescale for the complete scenario
                % duration
                t=linspace(0,scenarioDuration,scenarioDuration*...
                    obj.robot.SampleRate);
                
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
                    outSignal=plot(0,0,'b');
                    sVector=outSignal;
                    lVector='signal(LE)';
                    lMapVector={};
                    indexVector=[];


                    % populate the legend with all auditory categories
                    % prepare category vectors for map construction
                    for i=1:size(auditoryCategoryList,1)
                        p=plot(0,0,'Color',obj.categoryColors{i});
                        sVector=[sVector p];
                        lVector=[lVector auditoryCategoryList(i)];
                        lMapVector{1,i}=auditoryCategoryList{i};
                        indexVector=[indexVector,i];
                    end

                    % construct the maps for coninuous plotting and fast
                    % category index access
                    obj.categoryMap=containers.Map(lMapVector,...
                        zeros(1,size(lMapVector,2)));
                    obj.categoryIndices=containers.Map(...
                        lMapVector,indexVector);

                    % draw the legend
                    legend(sVector,lVector);
                    % dont repeat this loop
                    obj.fromScratch=false;
                    
                    

                    % loop over all sources, ignoring the silent source
                    for i=2:size(auditoryGTVector,1)
                        for j=2:5:size(auditoryGTVector{i},2)
                            % step the auditoryGT vector with appropriate
                            % stepsize, plotting the onsets/offset for each
                            % stimulus, stimulus category is displayed as
                            % the box color
                            x=auditoryGTVector{i}{j}/scenarioDuration;
                            y=0.05;
                            w=(auditoryGTVector{i}{j+3}-...
                                auditoryGTVector{i}{j})/...
                                scenarioDuration;
                            h=0.05;

                            a=annotation( 'textbox',...
                                        [x y w h],...
                                        'String','',...
                                        'FontSize',8,...
                                        'FontName','Arial',...
                                        'HorizontalAlignment','center',...
                                        'VerticalAlignment','middle',...
                                        'EdgeColor',[0 0 0],...
                                        'LineWidth',1,...
                                        'BackgroundColor',...
                                           obj.categoryColors{...
                                           obj.categoryIndices(...
                                           auditoryGTVector{i}...
                                                           {j+1})},...
                                        'Color',[0 0 0]);

                            % resize the box to actually fit into the time
                            % domain
                            set(a,'parent',gca);
                            set(a,'position',[...
                                auditoryGTVector{i}{j}...
                                -0.05 auditoryGTVector{i}{j+3}-...
                                auditoryGTVector{i}{j} 0.05]);

                            % plot the acceptable/wrong information.
                            % acceptable AV pairs yield green boxes, wrong
                            % receive red boxes
                            b=annotation( 'textbox',...
                                        [x y w h],...
                                        'String','',...
                                        'FontSize',8,...
                                        'FontName','Arial',...
                                        'HorizontalAlignment','center',...
                                        'VerticalAlignment','middle',...
                                        'EdgeColor',[0 0 0],...
                                        'LineWidth',1,...
                                        'BackgroundColor',...
                                            obj.categoryColors{...
                                                obj.categoryIndices(...
                                                 auditoryGTVector...
                                                     {i}{j+1})},...
                                        'Color',[0 0 0]);

                            % adapt to the given timescale
                            set(b,'parent',gca);
                            set(b,'position',[...
                                auditoryGTVector{i}{j}...
                                -0.1 auditoryGTVector{i}{j+3}-...
                                auditoryGTVector{i}{j} 0.05]);
                            
                            % assign the box color
                            if (strcmp(auditoryGTVector{i}{j+2},...
                                    'acceptable'))
                                set(b,'BackgroundColor',[0 1 0]);
                            else
                                set(b,'BackgroundColor',[1 0 0]);
                            end
                        end
                    end
                    
                    
                    
                end

                % overlay the time signal, and update the stop
                % index
                obj.signalStop=obj.signalStart+size(sig,1)-1;
                % dont run over the simulation data limit
                if (obj.signalStop>size(t,2))
                    obj.signalStop=size(t,2);
                end
                % plot(t(1,obj.signalStart:obj.signalStop),...
                %     sig(1:obj.signalStop-obj.signalStart+1),'b');

                % overlay the auditory classifier results. It can happen
                % that there is no result available, especially in the
                % beginning of the simulation. The try/catch block takes
                % that into account.
                try
                    identityHypotheses=obj.blackboard.getLastData(...
                        'auditoryIdentityHypotheses').data;
                    for i=1:size(identityHypotheses,2)
                        plot([t(1,obj.signalStart)...
                              t(1,obj.signalStop)],...
                              [obj.categoryMap(...
                                identityHypotheses(i).label)...
                                identityHypotheses(i).p],...
                                'Color',...
                                obj.categoryColors{...
                                   obj.categoryIndices(...
                                      identityHypotheses(i).label)});                
                        
                        obj.categoryMap(identityHypotheses(i).label)=...
                            identityHypotheses(i).p;
                    end
                catch
                    
                end
                % update the start variable
                obj.signalStart=obj.signalStop+1;
            end
            
        end

   
    end
end
