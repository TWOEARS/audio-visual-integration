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

classdef HeadTurningModulationKS < AbstractKS
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

function obj = HeadTurningModulationKS (bbs)
    obj = obj@AbstractKS();
    obj.bbs = bbs;
    obj.invocationMaxFrequency_Hz = inf;
    
    initializeParameters(obj);

    obj.MSOM = MultimodalSelfOrganizingMapKS();
    obj.MFI = MultimodalFusionAndInferenceKS(obj.MSOM);
    % obj.MotorOrderKS = MotorOrderKS(obj);
    obj.RIR = RobotInternalRepresentation(obj);

end


%% execute functionality
function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)
    
    fprintf('\nHead Turning Modulation KS evaluation\n');

    obj.cpt = obj.cpt + 1;

    [create_new, do_nothing] = obj.createNewObject();

    % --- Retrieve vector of probabilities
    classifiers_output = getClassifiersOutput(obj);
    % --- Retrieve estimated localisation of sound source
    perceived_angle = getLocalisationOutput(obj);
    % --- Retrieve estimated distance of sound source (TODO)
    perceived_distance = 3;

    if create_new % --- create a new object
        obj.last_movement = obj.cpt;
        obj.MSOM.idx_data = 1;
        obj.RIR.updateData(classifiers_output, perceived_angle, perceived_distance);
        
        obj.RIR.addObject();

    elseif ~create_new && ~do_nothing % --- update object
        obj.RIR.updateData(classifiers_output, perceived_angle, perceived_distance);
        obj.RIR.updateObject();
        obj.MSOM.idx_data = obj.MSOM.idx_data + 1;
    
    elseif ~create_new && do_nothing % --- silence phase
        if obj.RIR.nb_objects > 0
            setObject(obj, 0, 'presence', false);
        end
        obj.RIR.updateData(classifiers_output, 0, 0);
    end
    % --- Update all objects
    obj.updateTime();
    obj.RIR.updateObjects(obj.cpt);

    if ~isempty(classifiers_output)
        obj.data(:, obj.cpt) = classifiers_output;
    else
        obj.data(:, obj.cpt) = generateEmptyVector();
    end

    if obj.blackboard.currentSoundTimeIdx > getInfo('duration')
        obj.blackboardSystem.robotConnect.finished = true;
        playNotification();
    end

    notify(obj, 'KsFiredEvent');
% end
end

function finished = isFinished(obj)
    finished = obj.finished;
end

function updateTime (obj)
    obj.current_time = obj.blackboard.currentSoundTimeIdx;
end

% function retrieveMfiCategorization (obj, classifiers_output)
%     if ~isempty(classifiers_output)
%         obj.classif_mfi{obj.cpt} = obj.RIR.getMFI().inferCategory(classifiers_output) ;
%     else
%         obj.classif_mfi{obj.cpt} = 'none_none' ;
%     end
% end

% === TO BE MODIFIED === %
function [create_new, do_nothing] = createNewObject (obj)

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
end
% === TO BE MODIFIED === %

% === TO BE MODIFIED === %
% Related to the "createNewObject" function
% that does not work with the setup of the current experiment.
% Need to find a way to know when to create a new object.
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
% === TO BE MODIFIED === %

% === TO BE MODIFIED === %
% Need to find a way to retrieve the groundtruth knowledge
% for statistical purposes.

% function retrieveGroundtruth (obj)
%     % obj.gtruth = cell(obj.RIR.nb_objects, 1) ;
%     al = 0 ;
%     vl = 0 ;

%     al = obj.simulation_status(1, obj.cpt) ;
%     vl = obj.simulation_status(2, obj.cpt) ;

%     if al == 0
%         obj.gtruth{end+1} = 'none_none' ;
%     else
%         obj.gtruth{end+1} = [obj.visual_labels{vl}, '_', obj.audio_labels{al}] ;
%     end

% end
% === TO BE MODIFIED === %

end
    
end
