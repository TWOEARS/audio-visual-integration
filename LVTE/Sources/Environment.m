classdef Environment < handle
    
    
    properties (Access = public)
        
        pathToAudioFiles;
        sim;
        BlockSize=2048;
        roomDims; % the room dimensions in meters
        reflectionCoefficients; % the reflection coefficients array
        robotController; % the robot
        sources; % array of sources
        fsHz = 44100;
        SampleRate=0;
        outSignalSSR=[];        
        AzimuthMin=-180;
        AzimuthMax=180;
        finished=0;
        duration=0;
        
        auditoryCategoryList;
        auditoryInstancesList;
        
        visualCategoryList;
        
        acceptableAVPairs;
        wrongAVPairs;
        
        
        auditoryGTVector;
    end
    
    
    properties (Access = public)
        
    end
    
    methods (Access = public)
        
        function h = Environment()
            h.SampleRate=h.fsHz; % compatibility with Blackboard
       
            disp('Environment instantiated...');            
            h.robotController=RobotController(h);
            h.sources={};            
            startTwoEars;
        end
        
        function setPathToAudioFiles(h,path)
            h.pathToAudioFiles=path;
        end
        
        function planAuditoryScheduleForAllSources(h,duration)
            % random nr of active source
            t=1.0;
            while (t<duration)
                
                


                sourceID=floor(rand()*(size(h.sources,1)-1))+2;

                % find source visual category
                visCat=h.sources{sourceID,1}.getVisualCategoryAtTime(t);

                % employ rand nr gen in order to decide if an acceptable
                % pair (80% probability) or a wrong pair (20% probability)
                % will be used to instantiate
                useAcceptable=rand();
                if useAcceptable>0.75
                    % use wrong AV pair
                    for j=1:size(h.wrongAVPairs,1)
                        if (strcmp(h.wrongAVPairs{j}{1},visCat))
                            fprintf('pair: (%s,%s)\n',visCat,h.wrongAVPairs{j}{2});
                            stimulus=getStimulusForAuditoryLabel(h,h.wrongAVPairs{j}{2},1);
                            stimulus=strcat(h.pathToAudioFiles,stimulus);
                            [sig, fs] = audioread(stimulus);
                            s = resample(sig, h.SampleRate, fs);
                            length=size(s,1)/h.SampleRate;
                            
                            
                            h.sources{sourceID}.auditorySchedule{size(h.sources{sourceID,1}.auditorySchedule,2)+1}={t,'on',h.wrongAVPairs{j}{2},1,'wrong'};
                            h.sources{sourceID}.auditorySchedule{size(h.sources{sourceID,1}.auditorySchedule,2)+1}={t+length,'off'};

                            
                            t=t+length;
                            break;
                        end
                    end

                else
                    % use acceptable AV pair
                    for j=1:size(h.acceptableAVPairs,1)
                        if (strcmp(h.acceptableAVPairs{j}{1},visCat))
                            fprintf('pair: (%s,%s)\n',visCat,h.acceptableAVPairs{j}{2});
                            stimulus=getStimulusForAuditoryLabel(h,h.acceptableAVPairs{j}{2},1);
                            stimulus=strcat(h.pathToAudioFiles,stimulus);
                            [sig, fs] = audioread(stimulus);
                            s = resample(sig, h.SampleRate, fs);
                            length=size(s,1)/h.SampleRate;                            
                            
                           h.sources{sourceID}.auditorySchedule{size(h.sources{sourceID,1}.auditorySchedule,2)+1}={t,'on',h.acceptableAVPairs{j}{2},1,'acceptable'};
                            h.sources{sourceID}.auditorySchedule{size(h.sources{sourceID,1}.auditorySchedule,2)+1}={t+length,'off'};


                            
                            t=t+length;
                            break;
                        end
                    end
                end
            t=t+1.0;    
            end
        end
        
        
        
        function generateAuditoryGroundTruthVector(h)
            h.auditoryGTVector=cell(size(h.sources,1),1);
            for i=2:size(h.sources,1)                
                h.auditoryGTVector{i}={h.sources{i,1}.name};
                for j=1:size(h.sources{i,1}.auditorySchedule,2)                    
                    if ~isempty(strfind(h.sources{i,1}.auditorySchedule{j}{2},'on'))
                        h.auditoryGTVector{i}=[h.auditoryGTVector{i},{h.sources{i,1}.auditorySchedule{j}{1},h.sources{i,1}.auditorySchedule{j}{3},h.sources{i,1}.auditorySchedule{j}{5}}];                        
                    end
                    if ~isempty(strfind(h.sources{i,1}.auditorySchedule{j}{2},'off'))
                        h.auditoryGTVector{i}=[h.auditoryGTVector{i},{h.sources{i,1}.auditorySchedule{j}{1},''}];                        
                    end
                end                
            end
        end
        
        function readAuditoryCategories(h)
        
            fprintf('reading auditory category file...\n');
            
            h.auditoryInstancesList=[];
            h.auditoryCategoryList=[];
            
            categoryFile = xmlread('auditoryCategoryFile.xml');
            categories = categoryFile.getElementsByTagName('category');
            for i = 0:categories.getLength-1
                category=categories.item(i);
                categoryName=char(category.getAttribute('name'));
                h.auditoryCategoryList=[h.auditoryCategoryList;{categoryName}];
                
                instances=categories.item(i).getElementsByTagName('instance');
                for j=0:instances.getLength()-1
                    instance = instances.item(j);                    
                    id=str2num(instance.getAttribute('id'));
                    stimulus=char(instance.getAttribute('stimulus'));
                    fprintf('category: %s, instance: %.3i, using stimulus: %s\n',categoryName,id,stimulus);
                    h.auditoryInstancesList=[h.auditoryInstancesList;{categoryName,id,stimulus}];
                end
                
                
                
            end
            
        end
        
        
        function readVisualCategories(h)
        
            fprintf('reading visual category file...\n');
            
            h.visualCategoryList=[];
            
            categoryFile = xmlread('visualCategoryFile.xml');
            categories = categoryFile.getElementsByTagName('category');
            for i = 0:categories.getLength-1
                category=categories.item(i);
                categoryName=char(category.getAttribute('name'));
                h.visualCategoryList=[h.visualCategoryList;{categoryName}];
                
                instances=categories.item(i).getElementsByTagName('instance');
                for j=0:instances.getLength()-1
                    instance = instances.item(j);                    
                    id=str2num(instance.getAttribute('id'));
                    stimulus=char(instance.getAttribute('stimulus'));
                    fprintf('category: %s, instance: %.3i, using stimulus: %s\n',categoryName,id,stimulus);                    
                end
                
                
                
            end
            
        end
        
        

        function createAVPairs(h)
            fprintf('reading av category pairs file...\n');
            
            acceptablePairsFile = xmlread('acceptableAVPairs.xml');
            acceptablePairs = acceptablePairsFile.getElementsByTagName('pair');
            for i = 0:acceptablePairs.getLength-1
                pair=acceptablePairs.item(i);
                A=char(pair.getAttribute('A'));
                B=char(pair.getAttribute('B'));
                h.acceptableAVPairs{i+1,1}={A,B};
                fprintf('Found acceptable AV pair: (%s, %s)\n',A,B);
            end
            

            wrongPairsFile = xmlread('wrongAVPairs.xml');
            wrongPairs = wrongPairsFile.getElementsByTagName('pair');
            for i = 0:wrongPairs.getLength-1
                pair=wrongPairs.item(i);
                A=char(pair.getAttribute('A'));
                B=char(pair.getAttribute('B'));
                h.wrongAVPairs{i+1,1}={A,B};
                fprintf('Found wrong AV pair: (%s, %s)\n',A,B);
            end



        end
        
        
        function stimulus=getStimulusForAuditoryLabel(h,category,instance)
            for i=1:size(h.auditoryInstancesList,1)
                if(strcmp(h.auditoryInstancesList(i,1),category))
                    if(h.auditoryInstancesList{i,2}==instance)
                        stimulus=h.auditoryInstancesList{i,3}; 
                        break;
                    end
                end
            end
            
        end
        
        function instantiateSSR(h)
            startTwoEars();
            h.sim = simulator.SimulatorConvexRoom();
              
        
        
        
            s=cell(size(h.sources,1),1);
            for i=1:size(s,1)
               s{i}=simulator.source.Point();
            end
            set(h.sim, ...
            'BlockSize',h.BlockSize, ...
            'SampleRate',h.SampleRate, ...
            'HRIRDataset', simulator.DirectionalIR( ...
                'impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa'), ...
            'Sources', s, ...
            'Sinks',   simulator.AudioSink(2), ...
            'Room', simulator.room.Shoebox ...
            );
            
        
        
            set(h.sim.Room, ...            
              'Name', 'Room', ...
              'Position', [0;0;0], ...
              'UnitX', [1; 0; 0], ...
              'UnitZ', [0; 0; 1], ...
              'LengthX', h.roomDims(1), ...
              'LengthY', h.roomDims(1), ...
              'LengthZ', h.roomDims(1), ...
              'ReverberationMaxOrder', 8, ...
              'RT60', 1.0 ...
              );
             
        
        
            set(h.sim.Sinks, ...
              'Position' , [h.robotController.position(1);h.robotController.position(2); 2], ...
              'UnitX', [1; 0; 0], ...
              'UnitZ', [0; 0; 1], ...
              'Name', 'Head' ...
              );
        
            for i=1:size(s,1)
                set(h.sim.Sources{i}, ...
                'Name',h.sources{i,1}.name, ...
                'Position', h.sources{i}.position', ...
                'AudioBuffer', simulator.buffer.FIFO(1), ...
                'Volume',h.sources{i,1}.volume ...
                );
                
            end
            h.sim.set('Init',true);
            for i=1:size(s,1)
                if (h.sources{i,1}.isControllable==0)
                    h.sources{i,1}.startPlaying();
                end
            end
        
        end
        
        function finished=isFinished(h)
            finished=h.finished;%h.sim.isFinished();
        end
        
        function rotateHead(h,angle,mode)
            if strcmp(mode,'relative')
                h.robotController.rotateRelative(angle);
            end
        end
        
        function sketchRoom(h)
            % switch to room display (the figure 1 is the room display)
            figure(1);
            clf;
            % set axes
            xlim([0 h.roomDims(1)]);
            ylim([0 h.roomDims(2)]);
            zlim([0 h.roomDims(3)]);
            %view([17 10]);
            view([0 90]);
            axis equal;
            
            % plot the room geometry
            vertices = [0 0 0;
                        h.roomDims(1) 0 0;
                        h.roomDims(1) h.roomDims(2) 0; 
                        0 h.roomDims(2) 0;
                        0 0 h.roomDims(3);
                        h.roomDims(1) 0 h.roomDims(3);
                        h.roomDims(1) h.roomDims(2) h.roomDims(3); 
                        0 h.roomDims(2) h.roomDims(3)];
            faces = [1 2 3 4;
                     1 5 8 4;
                     1 2 6 5;
                     2 6 7 3;
                     7 8 4 3;
                     5 6 7 8];
            patch('Faces',faces(1,:),'Vertices',vertices,'FaceColor',[0.5 0.5 0.5],'FaceAlpha',1.0)
            patch('Faces',faces(2:6,:),'Vertices',vertices,'FaceColor',[209/255 238/255 238/255],'FaceAlpha',0.5)
            hold on;
            % plot the sources
            [x,y,z]=sphere;
            [u,v,w]=cylinder;
            
            for i=1:size(h.sources,1)
                p=surf(   x*0.1+h.sources{i}.position(1), ...
                          y*0.1+h.sources{i}.position(2), ...
                          z*0.1+h.sources{i}.position(3));
                if (h.sources{i}.isActive==1)
                    set(p,'FaceColor','g','EdgeColor','none');
                else
                    set(p,'FaceColor','r','EdgeColor','none');
                end
                q=surf(   u*0.025+h.sources{i}.position(1), ...
                          v*0.025+h.sources{i}.position(2), ...
                          -w*(h.sources{i}.position(3))+h.sources{i}.position(3));
                set(q,'FaceColor','b','EdgeColor','none');
            end
            
            % plot robot
            
            if ~isempty(h.robotController.position)
                [u,v,w]=cylinder([0 0.25]);
                w=w-2/3;
                alpha=0;
                beta=-90/180*pi;
                gamma=(h.robotController.head.phi+h.robotController.phi)/180*pi;
                
                
                
                
                Rz=[ cos(gamma) -sin(gamma) 0;
                    sin(gamma) cos(gamma) 0;
                    0           0          1];
                
                Rx=[ cos(beta)    0          sin(beta);
                     0            1          0;
                     -sin(beta)   0          cos(beta)];
                
                Rz2=[cos(alpha) -sin(alpha) 0;
                    sin(alpha) cos(alpha) 0;
                    0           0          1];
                
                R=Rz*Rx*Rz2;
                
                
                m=R*[u(1,:);v(1,:);w(1,:)];
                u(1,:)=m(1,:);
                v(1,:)=m(2,:);
                w(1,:)=m(3,:);
                
                m=R*[u(2,:);v(2,:);w(2,:)];
                u(2,:)=m(1,:);
                v(2,:)=m(2,:);
                w(2,:)=m(3,:);
                
                q=surf(   u*0.25+h.robotController.position(1,1), ...
                          v*0.25+h.robotController.position(1,2), ...
                          w*0.25+h.robotController.position(1,3)+h.robotController.head.zPosition);
                set(q,'FaceColor','g','EdgeColor','black');
                
                
                
                sx=h.robotController.length;
                sy=h.robotController.width;
                sz=h.robotController.height;
                               
                
                vertices = [0 0 0;
                            sx 0 0;
                            sx sy 0; 
                            0 sy 0;
                            0 0 sz;
                            sx 0 sz;
                            sx sy sz; 
                            0 sy sz];

                vertices=vertices-repmat([sx/2 sy/2 0],8,1);
                        
                        
                alpha=h.robotController.phi/180*pi;
                beta= 0/180*pi;
                gamma=0/180*pi;
                
                Rz=[ cos(gamma) -sin(gamma) 0;
                    sin(gamma) cos(gamma) 0;
                    0           0          1];
                
                Rx=[ cos(beta)    0          sin(beta);
                     0            1          0;
                     -sin(beta)   0          cos(beta)];
                
                Rz2=[cos(alpha) -sin(alpha) 0;
                    sin(alpha) cos(alpha) 0;
                    0           0          1];
                
                R=Rz*Rx*Rz2;
                        
                
                for i=1:size(vertices,1)
                    vertices(i,:)=reshape(R*vertices(i,:)',1,3);
                end    
                      
                vertices(:,1)=vertices(:,1)+h.robotController.position(1,1);
                vertices(:,2)=vertices(:,2)+h.robotController.position(1,2);
                        
                patch('Faces',faces,'Vertices',vertices,'FaceColor','green','FaceAlpha',1.0);
                
                
                [u,v,w]=cylinder;
            
                q=surf(   u*0.015+h.robotController.position(1,1), ...
                          v*0.015+h.robotController.position(1,2), ...
                          -w*(h.robotController.position(1,3)+h.robotController.head.zPosition)+h.robotController.position(1,3)+h.robotController.head.zPosition);
                set(q,'FaceColor','b','EdgeColor','none');
                
                
                % plot collision hull
                
                [u,v,w]=cylinder;
            
                q=surf(   u*sqrt((h.robotController.length/2)^2+(h.robotController.width/2)^2)+h.robotController.position(1), ...
                          v*sqrt((h.robotController.length/2)^2+(h.robotController.width/2)^2)+h.robotController.position(2), ...
                          w*0.05);
                set(q,'FaceColor','r','EdgeColor','red','LineWidth',1);
                
            end
                
            hold off;
            
            
            
        end
        
        function orientation=getCurrentHeadOrientation(h)
            orientation=h.robotController.head.phi+h.robotController.phi;
        end
        
        function setScenarioDuration(h,time)
            h.duration=time;
        end
        
        function updateTime(h,time)
            h.robotController.actuate();
            for i=2:size(h.sources,1) % ignore silent source!
                if ~isempty(h.sources{i,1}.auditorySchedule)
                    if (time>=h.sources{i,1}.auditorySchedule{1}{1})
                        if ~isempty(strfind(h.sources{i,1}.auditorySchedule{1}{2},'on'))
                            if ~isempty(strfind(h.sources{i,1}.auditorySchedule{1}{2},'cont'))
                                h.sources{i,1}.isContinuous=1;                               
                            else
                                h.sources{i,1}.isContinuous=0;                               
                            end
                            
                            h.sources{i,1}.auditoryCategory=h.sources{i,1}.auditorySchedule{1}{3};
                            h.sources{i,1}.auditoryCategoryInstance=h.sources{i,1}.auditorySchedule{1}{4};
                            h.sources{i,1}.startPlaying();
                            
                        else
                            h.sources{i,1}.stopPlaying();
                            h.sources{i,1}.isContinuous=0;       
                        end
                        h.sources{i,1}.auditorySchedule(1)=[];
                    end
                end
            end            
            
            
            
            for i=2:size(h.sources,1) % ignore silent source!
                if ~isempty(h.sources{i,1}.visualSchedule)
                    if (time>=h.sources{i,1}.visualSchedule{1}{1})
                            h.sources{i,1}.visualCategory=h.sources{i,1}.visualSchedule{1}{2};
                            h.sources{i,1}.visualCategoryInstance=h.sources{i,1}.visualSchedule{1}{3};
                        
                            h.sources{i,1}.visualSchedule(1)=[];
                    end
                end
            end            
            
            for i=2:size(h.sources,1) % ignore silent source!
                if (h.sources{i,1}.isContinuous==1)
                    if h.sim.Sources{i,1}.AudioBuffer.isEmpty()
                        h.sources{i,1}.startPlaying();
                    end
                end
            end
            if (time>h.duration)
                h.finished=1;
            end
            pause(0.001);
        end
        
        function [signal,trueIncrement]=getSignal(h,dT)
            if ~h.sim.isFinished()
                set(h.sim.Sinks, ...
                  'Position' , [h.robotController.position(1);h.robotController.position(2); 2], ...
                  'UnitX', [cos((h.robotController.phi+h.robotController.head.phi)/180*pi); sin((h.robotController.phi+h.robotController.head.phi)/180*pi); 0], ...
                  'UnitZ', [0; 0; 1], ...
                  'Name', 'Head' ...
                  );
                [signal,trueIncrement] = h.sim.getSignal(dT);
                h.outSignalSSR=[h.outSignalSSR;signal];
            end
        end
        
       
        
        
        function createRoom(h,dimX,dimY,dimZ)
            % set room dimensions
            h.roomDims(1)=dimX;
            h.roomDims(2)=dimY;
            h.roomDims(3)=dimZ;
            % plot the room geometry
            h.sketchRoom();     
            
        end
        
        
        
        function setRoomDimensions(h,dx,dy,dz)
            h.roomDims=[dx,dy,dz];
        end
        
        
        
        
        function s=getSource(h,n)
            s=[];
            for i=1:size(h.sources,1)
                if strcmp(h.sources{i}.name,n)
                    s=h.sources{i};
                    break;
                end
            end            
        end
        
        
        function addSource(h,name,position)
            h.sources{size(h.sources,1)+1,1}=Source(h,name,position,'');
            h.sources{size(h.sources,1),1}.setIndex(size(h.sources,1));
        end    
        
        
        function addSilentSource(h)
            h.sources{size(h.sources,1)+1,1}=Source(h,'Silence',[0 0 -100],'silence.wav');
            h.sources{size(h.sources,1),1}.setIndex(size(h.sources,1));
            h.sources{size(h.sources,1),1}.volume=0.0;
            h.sources{size(h.sources,1),1}.isControllable=0;
        end 
        
        
        function addDistractor(h,name,position,stimulus,level)
            h.sources{size(h.sources,1)+1,1}=Source(h,name,position,stimulus);
            h.sources{size(h.sources,1),1}.setIndex(size(h.sources,1));
            h.sources{size(h.sources,1),1}.volume=level;
            h.sources{size(h.sources,1),1}.isControllable=0;
            h.sources{size(h.sources,1),1}.isContinuous=1;
        end 
        
        
        function setReflectionCoefficients(h,coeffs)
            h.reflectionCoefficients=coeffs;
        end
        
        function initializeRobot(h,x,y,headZ)
            h.robotController.setPosition(x,y);
            h.robotController.head.setZPosition(headZ);
        end
       
        
    end
    
end

