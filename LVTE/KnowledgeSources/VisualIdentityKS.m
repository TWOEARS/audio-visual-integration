classdef VisualIdentityKS < AbstractKS
    
    properties (SetAccess = private)
        robot;
    end

    methods
        function obj = VisualIdentityKS(robot)
            obj = obj@AbstractKS(); 
            obj.robot=robot;
            obj.invocationMaxFrequency_Hz=10;
        end
        
        
        %% execute functionality
        function [b, wait] = canExecute( obj )
            b = true;
            wait = false;
        end
        
        function execute( obj )
            % find directions to all sources
            sources=obj.robot.sources;
            headPosition=obj.robot.robotController.position;
            headOrientation=obj.robot.getCurrentHeadOrientation();
            
            distances=[];
            azimuthDifferences=[];
            categories=[];
            
            for i=2:size(sources,1) % dont take silent source into account!
                distance=norm(sources{i}.position(1,1:2)-headPosition(1,1:2));
                lookingDir=[cos(headOrientation/180*pi),sin(headOrientation/180*pi)];
                cosPhi=dot(lookingDir,sources{i}.position(1,1:2)-headPosition(1,1:2))/(norm(lookingDir)*norm(sources{i}.position(1,1:2)-headPosition(1,1:2)));
                azimuthDifference=acos(cosPhi)*180/pi;                
                
                distances=[distances,distance];
                azimuthDifferences=[azimuthDifferences,azimuthDifference];
                if ~isempty((sources{i}.visualCategory))
                    categories=[categories,{sources{i}.visualCategory}];
                else
                    categories=[categories,{'none'}];
                end
            end
            
            visualCategoryList=obj.blackboard.getData('visualCategoryList');
            
            categoryProbabilities=[];
            for i=1:size(visualCategoryList.data,1)
                category=visualCategoryList.data{i};
                probs=[];
                for j=1:size(distances,2)
                    vDD=visualDegradation_Distance(distances(j));
                    vDA=visualDegradation_Azimuth(azimuthDifferences(j));
                    visDeg=visualDegradation(vDD*vDA,category,categories{j});
                    probs=[probs;visDeg];
                end
                maxProb=max(probs);
                categoryProbabilities=[categoryProbabilities maxProb];
                
            end       
            visualIdentityHypotheses=containers.Map(visualCategoryList.data,categoryProbabilities);
            obj.blackboard.addData( 'visualIdentityHypotheses', visualIdentityHypotheses, false, obj.trigger.tmIdx );
            notify(obj, 'KsFiredEvent');
        end
    end
end
