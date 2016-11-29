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
    htm; % Head Turning Modulation
    RIR; % Robot Internal Representation

    bbs % --- Black Board System
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
    obj.thr_theta = getInfo('thr_theta');
end
% === CONSTRUCTOR [END] === %


function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)

    theta_a = getLocalisationOutput(obj.blackboard);

    if theta_a == -1
        hyp = [0, 0, 0];
    else
        theta_v = obj.htm.blackboard.getLastData('visualLocationHypotheses').data;
        theta_v = theta_v('theta');
        if numel(theta_v) > 1
            theta_v = theta_v(1);
        end
        putative_audio_object = [];
        nb_objects = obj.RIR.nb_objects;
        % --- Look for an object that has already been observed
        for iObject = 1:nb_objects
            theta_o = getObject(obj.htm, iObject, 'theta');
            theta_o = theta_o(end);
            theta_diff_a = abs(theta_o - theta_a);
            if theta_diff_a <= obj.thr_theta
                putative_audio_object(end+1) = iObject;
            end
        end

        if isempty(putative_audio_object)
            if abs(theta_a - theta_v) <= obj.thr_theta
                hyp = [1, 0, nb_objects+1];
            else
                hyp = [0, 0, 0];
            end
        else
            hyp = [0, 1, putative_audio_object(1)];
        end
    end
    hyp = obj.setHypotheses(hyp);

    obj.blackboard.addData('objectDetectionHypotheses', hyp,...
                           false, obj.trigger.tmIdx);
    
    notify(obj, 'KsFiredEvent');
end

function hypotheses = setHypotheses (obj, hyp)
    hypotheses.create_new = hyp(1);
    hypotheses.update_object = hyp(2);
    hypotheses.id_object = hyp(3);
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end