

% 'Visualizer' class
% This class defines a visualization facility that plots the current
% status in 3 dimensions. The function massively accesses the parent
% environment data, using some basic drawing functionality to sketch
% the robot, the sources, and the room dimensions.
% Author: Thomas Walther
% Date: 21.10.15
% Rev. 1.0


classdef Visualizer < handle
    
    % As this is an experimental system, all of the class members are
    % currently public, in order to have easy access.
    % This will be changed in later system versions.   
    
    properties (Access = public)
        parent;
    end
    
    methods (Access = public)
    
        
        %   the constructor
        %   inputs:
        %       parent:         the parent Environment
        function obj = Visualizer(parent)
            obj.parent=parent;
        end
        
        
        
        
        % Sketch the parent Environment. This function is based on basic
        % graphics functionality, and allows to generate a simplified
        % 3D view of the given scenario. If changes to the
        % robot/source/room appearance should be made, this routine has to
        % be appropriately adopted.
        %
        % inputs:   none
        function sketchParent(obj)
            p=obj.parent;
            % switch to room display (figure 1)
            figure(1);
            % clear figure;
            clf;
            % plot the room geometry
            vertices = [0 0 0;
                        p.roomDims(1) 0 0;
                        p.roomDims(1) p.roomDims(2) 0; 
                        0 p.roomDims(2) 0;
                        0 0 p.roomDims(3);
                        p.roomDims(1) 0 p.roomDims(3);
                        p.roomDims(1) p.roomDims(2) p.roomDims(3); 
                        0 p.roomDims(2) p.roomDims(3)];
            faces = [1 2 3 4;
                     1 5 8 4;
                     1 2 6 5;
                     2 6 7 3;
                     7 8 4 3;
                     5 6 7 8];
            patch('Faces',faces(1,:),'Vertices',vertices,'FaceColor',...
                [0.5 0.5 0.5],'FaceAlpha',0.5)
            patch('Faces',faces(2:6,:),'Vertices',vertices,'FaceColor',...
                [209/255 238/255 238/255],'FaceAlpha',0.5)
            hold on;
            % plot the sources
            [x,y,z]=sphere;
            [u,v,w]=cylinder;
            
            for i=2:size(p.sources,1) % ignore silent source
                s=surf(   x*0.1+p.sources{i}.position(1), ...
                          y*0.1+p.sources{i}.position(2), ...
                          z*0.1+p.sources{i}.position(3));
                if (p.sources{i}.isActive==1)
                    set(s,'FaceColor','g','EdgeColor','none');
                else
                    set(s,'FaceColor','r','EdgeColor','none');
                end
                q=surf(   u*0.025+p.sources{i}.position(1), ...
                          v*0.025+p.sources{i}.position(2), ...
                          -w*(p.sources{i}.position(3))+...
                          p.sources{i}.position(3));
                set(q,'FaceColor','b','EdgeColor','none');
                text(   p.sources{i}.position(1),...
                        p.sources{i}.position(2),...
                        p.sources{i}.position(3),...
                        p.sources{i}.name);
                    
            end
            
            % plot robot            
            if ~isempty(p.robotController.position)
                [u,v,w]=cylinder([0 0.25]);
                w=w-2/3;
                alpha=0;
                beta=-90/180*pi;
                gamma=(p.robotController.head.phi+...
                    p.robotController.phi)/180*pi;
                
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
                
                q=surf(   u*0.25+p.robotController.position(1,1), ...
                          v*0.25+p.robotController.position(1,2), ...
                          w*0.25+p.robotController.position(1,3)+...
                          p.robotController.head.zPosition);
                set(q,'FaceColor','g','EdgeColor','black');
                
                sx=p.robotController.length;
                sy=p.robotController.width;
                sz=p.robotController.height;
                   
                vertices = [0 0 0;
                            sx 0 0;
                            sx sy 0; 
                            0 sy 0;
                            0 0 sz;
                            sx 0 sz;
                            sx sy sz; 
                            0 sy sz];

                vertices=vertices-repmat([sx/2 sy/2 0],8,1);
                        
                        
                alpha=p.robotController.phi/180*pi;
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
                      
                vertices(:,1)=vertices(:,1)+p.robotController.position(1,1);
                vertices(:,2)=vertices(:,2)+p.robotController.position(1,2);
                        
                patch('Faces',faces,'Vertices',vertices,'FaceColor',...
                    'green','FaceAlpha',1.0);
                
                
                [u,v,w]=cylinder;
            
                s=surf(   u*0.015+p.robotController.position(1,1), ...
                          v*0.015+p.robotController.position(1,2), ...
                          -w*(p.robotController.position(1,3)+...
                          p.robotController.head.zPosition)+...
                          p.robotController.position(1,3)+...
                          p.robotController.head.zPosition);
                set(s,'FaceColor','b','EdgeColor','none');
                
            end
                
            hold off;
            % set axes and observation point            
            xlim([0 p.roomDims(1)]);
            ylim([0 p.roomDims(2)]);
            zlim([0 p.roomDims(3)]);
            view([0 90]);
        end
    end
    
end

