% 'ObjectDetectionKS' class
% This knowledge source aims at determining if a new object has appeared in the scene or not
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

classdef ObjectDetectionKS < AbstractKS

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    htm; % Head_Turning_Modulation KS
    RIR; % Robot_Internal_Representation KS
    
    % MOKS; % Motor_Order KS
    
    % ALKS; % Audio_Localization KS
    % VLKS; % Visual_Localization KS
    % ACKS; % Audio_Classification_Experts KS
    % VCKS; % Visual_Classification_Experts KS
end

properties (SetAccess = private, GetAccess = private)
    thr_theta;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = ObjectDetectionKS (bbs, htm)
    obj = obj@AbstractKS();
    obj.bbs = bbs;
    obj.invocationMaxFrequency_Hz = inf;

    obj.htm = htm;
    obj.RIR = htm.RIR;
    % obj.ALKS = htm.ALKS;
    % obj.VLKS = htm.VLKS;
    % obj.ACKS = htm.ACKS;
    % obj.VCKS = htm.VCKS;
    obj.thr_theta = getInfo('thr_theta');
end
% === CONSTRUCTOR [END] === %


function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

% function [create_new, do_nothing] = simulationStatus (obj, iStep)
function execute (obj)

    % theta_a = obj.ALKS.getAudioLocalization();
    theta_a = obj.blackboard.getLastData('sourcesAzimuthsDistributionHypotheses').data;
    theta_a = data.prob_AFN_F;
    if theta_a == -1
        hyp = [0, 0, 0];
    else
        putative_audio_object = [];
        nb_objects = obj.RIR.nb_objects;
        % --- Look for an object that has already been observed
        for iObject = 1:nb_objects
            theta_o = getObject(obj.htm, iObject, 'theta');
            theta_o = theta_o(end);
            theta_diff_a = theta_o - theta_a;
            if theta_diff_a <= obj.thr_theta  && theta_diff_a >= -obj.thr_theta %&& obj.htm.sources(obj.htm.iStep) ~= 0
                putative_audio_object(end+1) = iObject;
            end
        end

        if isempty(putative_audio_object)
            hyp = [1, 0, nb_objects+1];
        else
            hyp = [0, 1, putative_audio_object(1)];
        end
    end
    hyp = setHypotheses(hyp);
    
    obj.blackboard.addData('objectDetectionHypothese',...
                           hyp,...
                           false,...
                           obj.trigger.tmIdx);
    
    notify(obj, 'KsFiredEvent');
end

function hyp = setHypotheses (obj, hyp)
    hyp.create_new = hyp(1);
    hyp.update_object = hyp(2);
    hyp.id_object = hyp(3);
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end