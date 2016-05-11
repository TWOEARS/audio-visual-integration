

% 'VisualIdentityKS' class
% This knowledge source allows to generate a visual identity hypothesis.
% Contrary to the auditory hypotheses, this KS computes all visual
% category probabilities at once.
% Author: Thomas Walther
% Date: 21.10.15
% Rev. 1.0

classdef VisualIdentityKS < AbstractKS
    
    properties (SetAccess = private)
        robot;      % the robot environment interface
    end

    methods
        function obj = VisualIdentityKS(robot)
            obj = obj@AbstractKS(); 
            % initialize class members
            obj.robot=robot;
            % run continuously
            obj.invocationMaxFrequency_Hz=inf;
        end
        
        
        %% execute functionality
        function [b, wait] = canExecute( obj )
            % self-explanatory
            b = true;
            wait = false;
        end
        
        function execute( obj )
            % find ground truth directions to all sources
            sources=obj.robot.sources;
            % get current head position
            headPosition=obj.robot.robotController.position;
            % get current head orientation
            headOrientation=obj.robot.getCurrentHeadOrientation();
            
            % define interim variables
            distances=[];
            azimuthDifferences=[];
            categories=[];
            
            % loop over all sources, neglecting the silent source
            for i=2:size(sources,1)
                % calculate distance to the currently processed source
                distance=norm(sources{i}.position(1,1:2)-...
                    headPosition(1,1:2));
                % calculate the robot's looking direction
                lookingDir=[cos(headOrientation/180*pi),...
                    sin(headOrientation/180*pi)];
                cosPhi=dot(lookingDir,sources{i}.position(1,1:2)-...
                    headPosition(1,1:2))/(norm(lookingDir)*...
                    norm(sources{i}.position(1,1:2)-headPosition(1,1:2)));
                % find the difference between the nose-tip vector and the
                % source azimuth
                azimuthDifference=acos(cosPhi)*180/pi;                
                
                % append the source's distances
                distances=[distances,distance];
                % append the source's azimuth differences
                azimuthDifferences=[azimuthDifferences,azimuthDifference];
                
                % append the source's category
                if ~isempty((sources{i}.visualCategory))
                    categories=[categories,{sources{i}.visualCategory}];
                else
                    categories=[categories,{'none'}];
                end
            end
            
            % get the available visual categories
            visualCategoryList=obj.robot.visualCategoryList;
            
            % now, by looping through all visual categories, find the
            % contribution of each source to the currently processed
            % category and...
            categoryProbabilities=[];
            for i=1:size(visualCategoryList,1)
                category=visualCategoryList{i};
                probs=[];
                for j=1:size(distances,2)
                    vDD=visualDegradation_Distance(distances(j));
                    vDA=visualDegradation_Azimuth(azimuthDifferences(j));
                    visDeg=visualDegradation(vDD*vDA,category,...
                        categories{j});
                    probs=[probs;visDeg];
                end
                % ... choose the maximum of these contributions
                maxProb=max(probs);
                % append this maximum to the storage
                categoryProbabilities=[categoryProbabilities maxProb];
                
            end       
            % push the visual identity hypothesis to the blackboard
            visualIdentityHypotheses=containers.Map(visualCategoryList,...
                categoryProbabilities);
            obj.blackboard.addData( 'visualIdentityHypotheses',...
                visualIdentityHypotheses, false, obj.trigger.tmIdx );
            notify(obj, 'KsFiredEvent');
        end
    end
end
