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

    robot;
    RIR;

    data = [];
    
    classif_max = {};

    classif_mfi = {};

    gtruth = cell(0);

    current_time = 0;

end


properties (SetAccess = public, GetAccess = public)
    energy_thr = 0.01;
    smoothing_theta = 5;
    cpt = 0;
    last_movement = 0;
    theta_hist = [];

    statistics = [];

    simulation_status = [];
end

methods

function obj = HeadTurningModulationKS (robot)
    obj = obj@AbstractKS();
    obj.robot = robot;
    obj.invocationMaxFrequency_Hz = inf;
    initializeParameters(obj);


    obj.MSOM = MultimodalSelfOrganizingMap();
    obj.MFI = MultimodalFusionAndInference(obj.MSOM);
    obj.MotorOrderKS = MotorOrderKS(obj);
    obj.RIR = RobotInternalRepresentation(obj);

end


%% execute functionality
function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)
    % if isappdata(0, 'RIR')
    %     obj.RIR = getappdata(0, 'RIR') ;
    %     obj.audio_labels = getappdata(0, 'audio_labels') ;
    %     obj.visual_labels = getappdata(0, 'visual_labels') ;
    %     obj.nb_audio_labels = numel(obj.audio_labels) ;
    %     obj.nb_visual_labels = numel(obj.visual_labels) ;
    %     obj.nb_labels = obj.nb_audio_labels + obj.nb_visual_labels ;
    %     obj.INIT = false ;
    % end
    % if obj.INIT
    %     obj.htmINIT() ;
    %     notify(obj, 'KsFiredEvent') ;
    %     return ;
    % end
    
    fprintf('\nHead Turning Modulation KS evaluation\n');

    % obj.cpt = obj.cpt + 1 ;
    incrementVariable(obj, 'cpt') ;

    [create_new, do_nothing] = obj.createNewObject() ;

    % --- Retrieve vector of probabilities
    classifiers_output = getClassifiersOutput(obj) ;
    % --- Retrieve estimated localisation of sound source
    % perceived_angle = obj.getLocalisationOutput() ;
    perceived_angle = getLocalisationOutput(obj);
    % --- Retrieve estimated distance of sound source (TODO)
    perceived_distance = 3;

    % --- Create a new object
    if create_new
        obj.RIR.addObject(classifiers_output, perceived_angle, perceived_distance);
        obj.last_movement = obj.cpt;
    
    % --- Update object
    elseif ~create_new && ~do_nothing
        obj.RIR.updateLabel(classifiers_output) ;
        obj.RIR.updateAngle(perceived_angle) ;
    
    % --- The object is no longer present in the scene
    elseif ~create_new && do_nothing
        if obj.RIR.nb_objects > 0
            obj.RIR.getLastObj().presence = false ;
        end
    end
    % --- Update all objects
    obj.updateTime();
    % obj.RIR.updateObjects(t) ;
    obj.RIR.updateObjects(obj.cpt);

    % obj.moveHead();

    %obj.simulationStatus() ;

    % obj.retrieveMfiCategorization(classifiers_output) ;

    if ~isempty(classifiers_output)
        obj.data(:, obj.cpt) = classifiers_output;
    else
        obj.data(:, obj.cpt) = generateEmptyVector();
    end

    % --- Add the motor order to the Blackboard
    % obj.blackboard.addData('moveHead', obj.RIR.focus, false, obj.trigger.tmIdx) ;
    notify(obj, 'KsFiredEvent') ;
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

% function moveHead (obj)
%     currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data ;
%     % --- If no sound -> make the head turn to 0° (resting state)
%     focus = obj.RIR.focus ;
    
%     if ~isSoundPresent(obj)
%         theta = -currentHeadOrientation ;
%         % fprintf('\nMotor order: 0deg (resting state)\n') ;
%     % --- Turn to the sound source
%     elseif focus ~= 0 && isFocusedObjectPresent(obj)
%         % --- Smoothing the head movements
%         if obj.cpt - obj.last_movement >= 5
%             obj.last_movement = obj.cpt ;
%             theta = obj.RIR.motorOrder() ;
%         else
%             theta = 0 ;
%         end
%     elseif isempty(obj.RIR.getMFI().categories)
%         if obj.cpt - obj.last_movement >= 5
%             theta = obj.RIR.getLastObj('theta') ;
%             obj.last_movement = obj.cpt ;
%         else
%             theta = 0 ;
%         end
%     else
%         theta = 0 ;
%     end

%     obj.robot.moveRobot(0.2, 0.2, 0);
    
% %     maxAzimuth = theta + currentHeadOrientation ;
% %     maxAzimuth = mod(maxAzimuth, 360) ;
% %     obj.robot.robotController.omegaMax = 1000000.0 ;
% %     obj.robot.robotController.goalAzimuth = maxAzimuth ;
% %     obj.robot.robotController.finishedPlatformRotation = false ;
% end

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

end
    
end
