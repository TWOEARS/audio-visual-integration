% 'HeadTurningModulationKS' class
% This knowledge source triggers head movements based on two modules:
% 1. MultimodalFusionAndInference module;
% (reference to come)
% 2. Dynamic Weighing module 
% (reference: Benjamin Cohen-Lhyver, Modulating the Auditory Turn-to Reflex on the Basis of Multimodal Feedback Loops:
% the Dynamic Weighting Model, in IEEE-ROBIO 2015)
% Author: Benjamin Cohen-Lhyver
% Date: 01.06.16
% Rev. 2.0

classdef ObjectDetectionKS < AbstractKS
% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public)
    head_position = 0;
    nb_steps_init = 1;
    nb_steps_final = 0;
 
    RIR;

    bbs = [];

    data = [];
 
    current_time = 0;
    MSOM;
    MFI;

end


properties (SetAccess = public, GetAccess = public)
    %energy_thr = 0.01;
    %smoothing_theta = 5;
    cpt = 0;
    last_movement = 0;
    theta_hist = [];

    statistics = [];

    simulation_status = [];
end

methods

function obj = ObjectDetectionKS (bbs)
    obj = obj@AbstractKS();
    obj.bbs = bbs;
    obj.invocationMaxFrequency_Hz = inf;
end


%% execute functionality
function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)
    
    %fprintf('\nObject Detection KS evaluation\n');

    a = getInfo('nb_audio_labels');
    audio_data = obj.retrieveLastAudioData();
    if max(audio_data(:, end)) <= 0.2        % --- (t)   -> silence phase
        if max(audio_data(:, end-1)) <= 0.2  % --- (t-1) -> silence phase
            create_new = false ;             % --- don't create a new object
            do_nothing = true ;              % --- don't update the current object
        else                                 % --- (t-1) -> object phase
            create_new = false ;             % --- don't create a new object
            do_nothing = false ;             % --- update the current object
        end
    else                                     % --- (t)   -> object phase
         if max(audio_data(:, end-1)) <= 0.2 % --- (t-1) -> silence phase
            create_new = true ;              % --- create a new object
            do_nothing = false ;             % --- update the current object
        else                                 % --- (t-1) -> object phase
            create_new = false ;             % --- don't create a new object
            do_nothing = false ;             % --- update the current object
        end
    end
    

    obj.blackboard.addData('objectDetectionHypothese',...
                           [create_new, do_nothing],...
                           false,...
                           obj.trigger.tmIdx);
    
    notify(obj, 'KsFiredEvent');

end

function audio_data = retrieveLastAudioData (obj)
    audio_data_all = obj.blackboard.getData('identityHypotheses');

    if numel(audio_data_all) > 1
        audio_data_1 = cell2mat(...
                                arrayfun(@(x) audio_data_all(end-1).data(x).p,...
                                         1:getInfo('nb_audio_labels'),...
                                         'UniformOutput', false)...
                                )';
        audio_data_2 = cell2mat(...
                                arrayfun(@(x) audio_data_all(end).data(x).p,...
                                         1:getInfo('nb_audio_labels'),...
                                         'UniformOutput', false)...
                                )';
        audio_data = [audio_data_1, audio_data_2] ;
    else
        audio_data = cell2mat(...
                                arrayfun(@(x) audio_data_all(end).data(x).p,...
                                         1:getInfo('nb_audio_labels'),...
                                         'UniformOutput', false)...
                                )' ;
        audio_data = [zeros(getInfo('nb_audio_labels'), 1), audio_data];
    end
end

end

end