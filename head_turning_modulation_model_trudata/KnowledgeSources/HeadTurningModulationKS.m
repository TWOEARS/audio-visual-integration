% 'HeadTurningModulationKS' class
% This knowledge source triggers head movements based on two modules:
% 1. MultimodalFusionAndInference module;
% (reference to come)
% 2. Dynamic Weighing module 
% (reference: Benjamin Cohen-Lhyver, Modulating the Auditory Turn-to Reflex on the Basis of Multimodal Feedback Loops:
% the Dynamic Weighting Model, in IEEE-ROBIO 2015)
% Author: Benjamin Cohen-Lhyver
% Date: 21.04.16
% Rev. 1.0

classdef HeadTurningModulationKS < AbstractKS
    
properties (SetAccess = public)
    robot ;

    HTM_robot ;

    % audio_labels = cell(0) ;

    % visual_labels = cell(0) ;

    % AVPairs = cell(0) ;

    data = [] ;
    
    % compared_labels = cell(0) ;

    classif_max = {} ;

    classif_mfi = {} ;

    % cpt_goodClassif = 0 ;

    gtruth = cell(0) ;

    current_time = 0 ;

end


properties (SetAccess = public, GetAccess = public)
    % nb_labels = 0 ;
    energy_thr = 0.01 ;
    INIT = true ;
    % fov = 30 ;
    smoothing_theta = 5 ;
    cpt = 0 ;
    last_movement = 0 ;
    theta_hist = [] ;
    % nb_audio_labels = 0 ;
    % nb_visual_labels = 0 ;
    % nb_AVPairs = 0 ;

    statistics = struct('max', 0,...
                        'max_mean', 0,...
                        'mfi', 0,...
                        'mfi_mean', 0,...
                        'alpha_a', 0,...
                        'alpha_v', 0,...
                        'beta_a', 0,...
                        'beta_v', 0) ;
    % cpt11 = [] ;
    % cpt12 = [] ;
    % cpt21 = [] ;
    % cpt22 = [] ;

    % goodClassifHist = [] ;

    simulation_status = [] ;
end

methods

function obj = HeadTurningModulationKS (robot)
    obj = obj@AbstractKS();
    obj.robot = robot ;
    obj.invocationMaxFrequency_Hz = inf ;
    obj.htmINIT() ;
end


%% execute functionality
function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)
    % if isappdata(0, 'HTM_robot')
    %     obj.HTM_robot = getappdata(0, 'HTM_robot') ;
    %     obj.audio_labels = getappdata(0, 'audio_labels') ;
    %     obj.visual_labels = getappdata(0, 'visual_labels') ;
    %     obj.nb_audio_labels = numel(obj.audio_labels) ;
    %     obj.nb_visual_labels = numel(obj.visual_labels) ;
    %     obj.nb_labels = obj.nb_audio_labels + obj.nb_visual_labels ;
    %     obj.INIT = false ;
    % end
    if obj.INIT
        obj.htmINIT() ;
        notify(obj, 'KsFiredEvent') ;
        return ;
    end
    
    fprintf('\nHead Turning Modulation KS evaluation\n');

    % obj.cpt = obj.cpt + 1 ;
    incrementVariable(obj, 'cpt') ;

    [create_new, do_nothing] = obj.createNewObject() ;

    % --- Retrieve vector of probabilities
    classifiers_output = getClassifiersOutput(obj) ;
    % --- Retrieve estimated localisation of sound source
    % perceived_angle = obj.getLocalisationOutput() ;
    perceived_angle = getLocalisationOutput(obj) ;
    % --- Retrieve estimated distance of sound source (TODO)
    perceived_distance = 3 ;

    % --- Create a new object
    if create_new
        obj.HTM_robot.addObject(classifiers_output, perceived_angle, perceived_distance) ;
        obj.last_movement = obj.cpt ;
    
    % --- Update object
    elseif ~create_new && ~do_nothing
        obj.HTM_robot.updateLabel(classifiers_output) ;
        obj.HTM_robot.updateAngle(perceived_angle) ;
    
    % --- The object is no longer present in the scene
    elseif ~create_new && do_nothing
        if obj.HTM_robot.nb_objects > 0
            obj.HTM_robot.getLastObj().presence = false ;
        end
    end
    % --- Update all objects
    obj.updateTime() ;
    % obj.HTM_robot.updateObjects(t) ;
    obj.HTM_robot.updateObjects(obj.cpt) ;

    obj.moveHead() ;

    %obj.simulationStatus() ;

    % obj.retrieveMfiCategorization(classifiers_output) ;

    if ~isempty(classifiers_output)
        obj.data(:, obj.cpt) = classifiers_output ;
    else
        obj.data(:, obj.cpt) = generateEmptyVector() ;
    end

    % --- Add the motor order to the Blackboard
    % obj.blackboard.addData('moveHead', obj.HTM_robot.focus, false, obj.trigger.tmIdx) ;
    notify(obj, 'KsFiredEvent') ;
% end
end

function finished = isFinished(obj)
    finished = obj.finished ;
end

function updateTime (obj)
    obj.current_time = obj.blackboard.currentSoundTimeIdx ;
end

% function retrieveMfiCategorization (obj, classifiers_output)
%     if ~isempty(classifiers_output)
%         obj.classif_mfi{obj.cpt} = obj.HTM_robot.getMFI().inferCategory(classifiers_output) ;
%     else
%         obj.classif_mfi{obj.cpt} = 'none_none' ;
%     end
% end

% === TO BE MODIFIED === %
% The current version uses the groundtruth knowledge that is actually available
% before the experiment starts.
% Need to find out how to retrieve the groundtruth.
% function simulationStatus (obj)
%     AVData = obj.getAVData() ;
%     t = obj.current_time ;
%     if ~isempty(AVData)
%         m1 = find(AVData.t_idx(:, 1) <= t, 1, 'last') ;
%         m2 = find(AVData.t_idx(:, 2) >= t, 1, 'first') ;
%         if m1 == m2
%             a = find(arrayfun(@(x) strcmp(obj.AVPairs{x}(2), AVData.labels{m1}), 1:numel(obj.AVPairs))) ;
%             v = a ;
%             obj.gtruth{end+1} = [obj.visual_labels{v}, '_', obj.audio_labels{a}] ;
%             % end
%             % if strcmp(AVData.labels{m1}, 'acceptable')
%             %     % a = find(strcmp(obj.AVPairs) ;
%             %     v = 1 ;
%             % else
%             %     a = 1 ;
%             %     v = 0 ;
%             % end
%         else
%             a = 0 ;
%             v = 0 ;
%             obj.gtruth{end+1} = 'none_none' ;
%         end
%     else
%         a = 0 ;
%         v = 0 ;
%         obj.gtruth{end+1} = 'none_none' ;
%     end
    
%     obj.simulation_status(1, obj.cpt) = a ;
%     obj.simulation_status(2, obj.cpt) = v ;
%     % obj.simulation_status(3, obj.cpt) = v ;

% end
% === TO BE MODIFIED === %

function moveHead (obj)
    currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data ;
    % --- If no sound -> make the head turn to 0° (resting state)
    focus = obj.HTM_robot.focus ;
    
    if ~isSoundPresent(obj)
        theta = -currentHeadOrientation ;
        % fprintf('\nMotor order: 0deg (resting state)\n') ;
    % --- Turn to the sound source
    elseif focus ~= 0 && isFocusedObjectPresent(obj)
        % --- Smoothing the head movements
        if obj.cpt - obj.last_movement >= 5
            obj.last_movement = obj.cpt ;
            theta = obj.HTM_robot.motorOrder() ;
        else
            theta = 0 ;
        end
    elseif isempty(obj.HTM_robot.getMFI().categories)
        if obj.cpt - obj.last_movement >= 5
            theta = obj.HTM_robot.getLastObj('theta') ;
            obj.last_movement = obj.cpt ;
        else
            theta = 0 ;
        end
    else
        theta = 0 ;
    end

    obj.robot.moveRobot(0.2, 0.2, 0);
    
%     maxAzimuth = theta + currentHeadOrientation ;
%     maxAzimuth = mod(maxAzimuth, 360) ;
%     obj.robot.robotController.omegaMax = 1000000.0 ;
%     obj.robot.robotController.goalAzimuth = maxAzimuth ;
%     obj.robot.robotController.finishedPlatformRotation = false ;
end

% === TO BE MODIFIED === %
function [create_new, do_nothing] = createNewObject (obj)

    a = getInfo('nb_audio_labels');
    % crit = 0 ;
    audio_data = obj.retrieveLastAudioData() ;
    %if max(audio_data(:, end)) == a+1
    if max(audio_data(:, end)) <= 0.2
        %if max(audio_data(:, end-1)) == a+1
        if max(audio_data(:, end-1)) <= 0.2
            create_new = false ;
            do_nothing = true ;
        else
            create_new = false ;
            do_nothing = false ;
        end
    else
        %if max(audio_data(:, end-1)) == a+1
         if max(audio_data(:, end-1)) <= 0.2
            create_new = true ;
            do_nothing = false ;
        else
            create_new = false ;
            do_nothing = true ;
        end
    end
    % % === Silence
    % if all(audio_data(:, end) == 0)
    %     create_new = false ;
    %     do_nothing = true ;
    %     % crit = 0 ;
    % % === Produce object
    % elseif any(audio_data(:, end-1) ~= 0) && any(audio_data(:, end) ~= 0)
    %     create_new = false ;
    %     do_nothing = false ;
    %     % crit = 1 ;
    % % === Create new object
    % elseif all(audio_data(:, end-1) == 0) && any(audio_data(:, end) ~= 0)
    %     create_new = true ;
    %     do_nothing = false ;
    %     % crit = 2 ;
    % end
    % obj.simulation_status(3, obj.cpt) = crit ;
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
                                )' ;
        audio_data_2 = cell2mat(...
                                arrayfun(@(x) audio_data_all(end).data(x).p,...
                                         1:getInfo('nb_audio_labels'),...
                                         'UniformOutput', false)...
                                )' ;
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
%     % obj.gtruth = cell(obj.robot.nb_objects, 1) ;
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


% ==================================== %
% ========== INITIALIZATION ========== %
% ==================================== %

function htmINIT (obj)
    fprintf('\nInitialization of HeadTurningModulationKS\n');

    % obj.audio_labels = getappdata(0, 'audio_labels') ;
    % obj.visual_labels = getappdata(0, 'visual_labels') ;

    % obj.AVPairs = {'door_knock', 'person_speech', 'siren_alert'} ;
    % obj.nb_AVPairs = numel(obj.AVPairs) ;
    information.audio_labels = getappdata(0, 'audio_labels');
    information.nb_audio_labels = numel(information.audio_labels);
    
    information.visual_labels = getappdata(0, 'visual_labels');
    information.nb_visual_labels = numel(information.visual_labels);

    information.nb_labels = information.nb_audio_labels + information.nb_visual_labels;

    information.AVPairs = {'siren_alarm', 'baby_baby', 'female_femaleSpeech', 'fire_fire'};
    information.nb_AVPairs = numel(information.AVPairs) ;

    information.fov = 30;

    information.obs_struct = struct('label'     , 'none_none',...
                                    'perf'      , 0,...
                                    'nb_goodInf', 0,...
                                    'nb_inf'    , 0,...
                                    'cpt'       , 0,...
                                    'proba'     , 0) ;

    setappdata(0, 'information', information);
    obj.HTM_robot = Robot() ;

    % obj.nb_audio_labels = numel(obj.audio_labels) ;
    % obj.nb_visual_labels = numel(obj.visual_labels) ;
    % obj.nb_labels = obj.nb_audio_labels + obj.nb_visual_labels ;
    obj.INIT = false ;
    
end

% ==================================== %
% ========== INITIALIZATION ========== %
% ==================================== %


end
    
end
