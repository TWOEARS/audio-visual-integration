classdef RobotController < handle
    % This class defines routines necessary to control the virtual robotic
    % platform. The platform is equipped with a standard KEMAR head (as
    % found in the CIPIC database. Motion control allows head turning,
    % platform turning, platform translation, and head tilt.
    
    properties (Access = public)
        parent;
        wallContactFlag=0;
        position=[0 0];
        phi=0.0;
        head;
        headLevelZ=1.8; %[m]
        linearVelocity=1; %[m/s]
        angularVelocity=360.0; %[deg/s]
        collisionHullRadius=0.5; %[m]
        % the robot chassis
        length=0.5; %[m]
        width=0.4; %[m]
        height=0.1; %[m]
        
        task='';
        goalPos=[0 0];
        goalPhi=[];
        taskActive=0;
        stopTime=0;
        
        
        
    end
    
    
    properties (Access = public)
        
    end
    
    methods (Access = public)
        
        function h = RobotController(parent)
            disp('RobotController instantiated...'); 
            h.parent=parent;
            h.head=KemarHead(h);
        end   
        
        
        
        function actuate(h)
        
            
            if ~isempty(h.goalPhi)
                
                actualPhi=h.head.phi+h.phi;
                steeringAngle=h.goalPhi-actualPhi;
                if (steeringAngle>180)
                    steeringAngle=steeringAngle-360;
                end
                fprintf('actual: %f, goal: %f, difference: %f\n',h.head.phi+h.phi,h.goalPhi,steeringAngle);

                maxPhiDiff=5;
                if (steeringAngle>maxPhiDiff)
                    steeringAngle=maxPhiDiff;
                end

                if (steeringAngle<-maxPhiDiff)
                    steeringAngle=-maxPhiDiff;
                end
                
                
                h.rotateRelative(steeringAngle);
                
            end
            
            h.rotateRelative(5.0);
        end
        
        function ret=issueTask(h,taskString)
            h.task=taskString;
            r=step(h,h.parent.dT);
            ret='noTaskActive';
            while(strcmp(r,'taskActive'))
                r=h.parent.step();
                str=sprintf('task (%s) active',taskString);
                disp(str);
                h.parent.sketchRoom();
                %h.parent.auralizeRoom();
                %pause(0.001);
            end
            if(strcmp(r,'taskAccomplished'))
                str=sprintf('task (%s) accomplished',taskString);
                disp(str);
                ret=r;
            end
            if (strcmp(r,'hitWall'))
                str=sprintf('task (%s) failed',taskString);
                disp(str);
                ret=r;
            end
            
        end   
        
        
        function ret=step(h,dT)
            ret='noTaskActive';
            if (strcmp(h.task,'')==0)
                S=strsplit(h.task);
                tName=S{1};
                param1=S{2};
                param2=0;
                if size(S,2)>2
                    param2=S{3};
                end
                
                
                
                
                if (strcmp(tName,'getAudioChunk'))                    
                    if (h.taskActive==0)
                        h.parent.leftEarSignal=[];
                        h.parent.rightEarSignal=[];
                        chunkLength=str2double(param1);
                        h.stopTime=h.parent.time+chunkLength;
                        h.taskActive=1;
                        h.parent.afeReinitialize();
                        h.parent.getRoomImpulseResponses();
                        h.parent.likelihoodMaps={};
                        ret='taskActive';
                        
                        set(h.parent.sim.Sinks, ...
                          'Position' , [h.position(1);h.position(1); 2], ...
                          'UnitX', [1; 0; 0], ...
                          'UnitZ', [0; 0; 1], ...
                          'Name', 'Head' ...
                          );
                        
                        
                        
                        figure(3);
                        clf;
                    else
                        
                        str=sprintf('dtime: %f',h.stopTime-h.parent.time);
                        disp(str);
                        if (h.stopTime-h.parent.time<=0) 
                            h.taskActive=0;
                            h.task='';
                            ret='taskAccomplished';
                        else
                            h.parent.auralizeRoom();
                            ret='taskActive';
                        end    
                    end
                end
                
                
                
                
                if (strcmp(tName,'rotatePlatformAbsolute'))                    
                    if (h.taskActive==0)
                        h.goalPhi=str2double(param1);
                        h.taskActive=1;
                        ret='taskActive';
                    else
                        
                        if (abs(h.goalPhi-h.phi)+0.1<dT*h.angularVelocity)
                            h.phi=h.goalPhi;
                            
                            h.taskActive=0;
                            h.task='';
                            ret='taskAccomplished';
                        else                            
                            if (h.goalPhi>h.phi)
                                h.rotateLeft(dT);
                            else
                                h.rotateRight(dT);
                            end
                            ret='taskActive';
                        end    
                    end
                end
                
                
                
                if (strcmp(tName,'rotatePlatformRelative'))                    
                    if (h.taskActive==0)
                        h.goalPhi=h.goalPhi+str2double(param1);
                        h.taskActive=1;
                        ret='taskActive';
                    else
                        
                        if (abs(h.goalPhi-h.phi)+0.1<dT*h.angularVelocity)
                            h.phi=h.goalPhi;
                            
                            h.taskActive=0;
                            h.task='';
                            ret='taskAccomplished';
                        else                            
                            if (h.goalPhi>h.phi)
                                h.rotateLeft(dT);
                            else
                                h.rotateRight(dT);
                            end
                            ret='taskActive';
                        end    
                    end
                end
                
                
                
                
                if (strcmp(tName,'rotateHeadAbsolute'))                    
                    if (h.taskActive==0)
                        h.head.goalPhi=str2double(param1);
                        h.taskActive=1;
                        ret='taskActive';
                    else
                        
                        if (abs(h.head.goalPhi-h.head.phi)+0.1<dT*h.head.angularVelocity)
                            h.head.phi=h.head.goalPhi;

                            h.taskActive=0;
                            h.task='';
                            ret='taskAccomplished';
                        else                            
                            if (h.head.goalPhi>h.head.phi)
                                h.head.rotateLeft(dT);
                            else
                                h.head.rotateRight(dT);
                            end
                            ret='taskActive';
                        end    
                    end
                end
                
                
                
                
                
                
                if (strcmp(tName,'rotateHeadRelative'))                    
                    if (h.taskActive==0)
                        h.head.goalPhi=h.head.phi+str2double(param1);
                        h.taskActive=1;
                        ret='taskActive';
                    else
                        
                        if (abs(h.head.goalPhi-h.head.phi)+0.1<dT*h.head.angularVelocity)
                            h.head.phi=h.head.goalPhi;
                            
                            h.taskActive=0;
                            h.task='';
                            ret='taskAccomplished';
                        else                            
                            if (h.head.goalPhi>h.head.phi)
                                h.head.rotateLeft(dT);
                            else
                                h.head.rotateRight(dT);
                            end
                            ret='taskActive';
                        end    
                    end
                end
                
                
                
                if (strcmp(tName,'moveTo'))              
                    h.goalPos=[str2double(param1) str2double(param2) 0];
                    diffVec=h.goalPos-h.position;
                    diffVecNorm=diffVec/norm(diffVec);
                    gPhi=atan2(diffVecNorm(2),diffVecNorm(1))/pi*180.0;
                    str=sprintf('rotatePlatformAbsolute %f',gPhi);
                    h.issueTask(str);
                    str=sprintf('moveForward %f',norm(diffVec));
                    h.issueTask(str);
                end
                
                
                
                
                
                if (strcmp(tName,'moveForward'))
                    dX=cos(h.phi/180*pi)*str2double(param1);
                    dY=sin(h.phi/180*pi)*str2double(param1);
                    if (h.taskActive==0)
                        h.goalPos=h.position+[dX dY 0];
                        h.taskActive=1;
                        ret='taskActive';
                    else
                        r=moveForward(h,dT);
                        if (r==0)
                            disp('Ran into wall, moveForward task halted!');
                            h.taskActive=0;
                            h.task='';
                            ret='hitWall';
                        else
                            str=sprintf('Norm: %f\n',norm(h.goalPos-h.position));
                            disp(str)
                            if (norm(h.goalPos-h.position)+0.001<abs(dT*h.linearVelocity))
                                disp('moveForward task accomplished, awaiting new task');
                                h.position=h.goalPos;
                                h.taskActive=0;
                                h.task='';
                                ret='taskAccomplished';
                            else
                                ret='taskActive';
                            end
                            
                        end
                    end
                    
                end
            
            end    
        end                
        
        function ret=moveForward(h,dT)
            
            rx=h.position(1,1);
            ry=h.position(1,2);
            
            Dx=h.parent.roomDims(1);
            Dy=h.parent.roomDims(2);
            
            dS=dT*h.linearVelocity;
            dX=cos(h.phi/180*pi)*dS;
            dY=sin(h.phi/180*pi)*dS;
            
            collisionRadius=sqrt((h.length/2)^2+(h.width/2)^2);
            
            rxN=rx+dX;
            ryN=ry+dY;
            
            a=Dx-rxN;
            b=ryN;
            c=rxN;
            d=Dy-ryN;
            
            collisionFlag=0;
         
            
            
            if (a<collisionRadius) && (dX>0)
                dX=dX-(collisionRadius-a)-0.001;
                collisionFlag=1;
            end
            
            
            if (c<collisionRadius) && (dX<0)
                dX=dX+(collisionRadius-c)+0.001;
                collisionFlag=1;
            end
            
            if (d<collisionRadius) && (dY>0)
                dY=dY-(collisionRadius-d)-0.001;
                collisionFlag=1;
            end
            
            if (b<collisionRadius) && (dY<0)
                dY=dY+(collisionRadius-b)+0.001;
                collisionFlag=1;
            end
            
            
            
            
            if (collisionFlag==1) && (h.wallContactFlag==0)
                disp('wall contact');
                h.position=[rx+dX ry+dY 0];
                h.wallContactFlag=1;
                ret=0;
            else
                if (h.wallContactFlag==0)
                    h.position=[rxN ryN 0];
                    ret=1;
                else
                    if (collisionFlag==0)
                        h.wallContactFlag=0;
                        h.position=[rxN ryN 0];
                        ret=1;
                    else
                        ret=0;
                    end
                    
                end
            end
            
            
        end
        
        function rotateLeft(h,dT)
            dA=dT*h.angularVelocity;
            h.phi=h.phi+dA;
        end
        
        
        function rotateRelative(h,dPhi)
            h.phi=h.phi+dPhi;
        end
        
        
        function rotateLeftRelative(h,dPhi)
            h.phi=h.phi+dPhi;
            
        end
        
        
        function rotateRightRelative(h,dPhi)
            h.phi=h.phi-dPhi;
            
        end
        
        
        function rotateRight(h,dT)
            dA=dT*h.angularVelocity;
            h.phi=h.phi-dA;
        end
        
        
        function setPosition(h,x,y)
            h.position=[x y 0];            
        end
        
        function setPhi(h,phi)
           h.phi=phi;            
        end
        
        
        
    end
    
end

