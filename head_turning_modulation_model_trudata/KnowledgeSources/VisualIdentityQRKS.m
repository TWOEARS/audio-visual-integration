% VisualIdentityQRKS class
% Author: Benjamin Cohen-Lhyver
% Date: 01.06.16
% Rev. 2.0

classdef VisualIdentityQRKS < AbstractKS

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== % 
properties (SetAccess = private)
    robot;      % the robot environment interface
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods
function obj = VisualIdentityQRKS(robot)
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

function execute (obj)
    visual_vec = zeros(getInfo('nb_visual_labels'), 1);

    visual_labels = getInfo('visual_labels');
    perceived_data = obj.robot.getVisualData();

    tmp = find(strcmp(perceived_data, visual_labels));
    if ~isempty(tmp)
        visual_vec(tmp) = 1;
    end

    keySet = {'visual_labels', 'visual_vec'};
    valueSet = {visual_labels, visual_vec};
    % push the visual identity hypothesis to the blackboard
    visualIdentityHypotheses = containers.Map(keySet, valueSet);
    obj.blackboard.addData('visualIdentityHypotheses', visualIdentityHypotheses,...
                           false, obj.trigger.tmIdx);
    notify(obj, 'KsFiredEvent');
end
% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end