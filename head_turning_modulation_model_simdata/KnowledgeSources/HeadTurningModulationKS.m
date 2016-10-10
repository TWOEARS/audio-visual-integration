% 'HeadTurningModulationKS' class
% This knowledge source triggers head movements based on two modules:
% 1. MultimodalFusionAndInference module;
% (reference to come)
% 2. Dynamic Weighing module 
% (reference: Benjamin Cohen-Lhyver, Modulating the Auditory Turn-to Reflex on the Basis of Multimodal Feedback Loops:
% the Dynamic Weighting Model, in IEEE-ROBIO 2015)
% Author: Benjamin Cohen-Lhyver
% Date: 21.05.16
% Rev. 2.0

classdef HeadTurningModulationKS < handle
% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    head_position = 0;

    data = [];

    gtruth_data = [];
    gtruth;

    classif_max = {};
    classif_mfi = {};

    statistics = [];

    sources = [];

    current_object = 0;
    current_object_hist = [];


    RIR; % Robot_Internal_Representation class
    MSOM; % Multimodal_Self_Organizing_Map class
    MFI; % Multimodal_Fusion_&_Inference class
    MotorOrderKS;
    HTMFocusKS; % Head_Turning_Modulation_Focus class
    EMKS; % Environmental_Map class
    ObjectDetectionKS;
    ALKS;
    VLKS;
    ACKS;
    VCKS;
end

properties (SetAccess = private, GetAccess = public)
    info;
end

properties (SetAccess = private, GetAccess = public)
    nb_steps_init = 1;
    nb_steps_final = 0;

    iStep = 0;

    save = false;
    load = false;
    continue_simulation = false;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = HeadTurningModulationKS (varargin)

    p = inputParser();
      % p.addOptional('Scene', 0,...
      %               @(x) validateattributes(x, {'numeric'},{'vector', 'integer'}));
      % p.addOptional('Steps', 1000,...
      %               @(x) validateattributes(x, {'numeric'}, {'integer', 'positive'}));
      p.addOptional('Save', false,...
                    @islogical);
      p.addOptional('Load', false,...
                    @islogical);
      % p.addOptional('Run', true,...
      %               @islogical);
      % p.addOptional('GUI', false,...
      %               @islogical);
    p.parse(varargin{:});
    p = p.Results;

    % addpath(genpath('~/Dev/TwoEars-1.2/audio-visual-integration/head_turning_modulation_model_simulated_data'));

    obj.save = p.Save;
    obj.load = p.Load;

    if p.Load
       if retrieveData(getInfo('nb_AVPairs'), getInfo('nb_steps'))

           obj.AVPairs = getappdata(0, 'AVPairs');
           obj.gtruth = getappdata(0, 'gtruth');
           obj.audio_labels = getappdata(0, 'audioLabels');
           obj.visual_labels = getappdata(0, 'visualLabels');
           obj.data = getappdata(0, 'data');
           obj.theta_obj = getappdata(0, 'thetaObj');
           obj.dist_hist = getappdata(0, 'distHist');
       end
    else
        disp('HTM: creating simulation');

        initializeParameters();

        obj.nb_steps_final = getInfo('nb_steps');

        obj.statistics = getInfo('statistics');
        obj.classif_mfi = repmat({'none_none'}, getInfo('nb_steps'), 1);

        initializeScenario(obj);

    end

    obj.MSOM                 = MultimodalSelfOrganizingMap();
    obj.MFI                  = MultimodalFusionAndInference(obj.MSOM);
    obj.RIR                  = RobotInternalRepresentation(obj);
    
    obj.HTMFocusKS           = HTMFocusKS(obj);
    obj.MotorOrderKS         = MotorOrderKS(obj, obj.HTMFocusKS);
    
    obj.EMKS                 = EnvironmentalMapKS(obj);

    obj.ALKS  = AudioLocalizationKS(obj);
    obj.VLKS = VisualLocalizationKS(obj);

    obj.ACKS = AudioClassificationExpertsKS(obj);
    obj.VCKS = VisualClassificationExpertsKS(obj);

    obj.ObjectDetectionKS    = ObjectDetectionKS(obj);
    % if p.Run
        obj.run();
    % end

end
% === CONSTRUCTOR [END] === %

% === Alternative to the constructor === %
function continueSimulation (obj, varargin)
    p = inputParser();
      p.addOptional('Scene', [],...
                    @(x) validateattributes(x, {'numeric'},{'vector', 'integer', 'positive'}));
      p.addOptional('Steps', 1000,...
                    @(x) validateattributes(x, {'numeric'}, {'integer', 'positive'}));
      p.addOptional('Run', true,...
                    @islogical);
    p.parse(varargin{:});
    p = p.Results;

    obj.nb_steps_init = obj.nb_steps_init + getInfo('nb_steps');

    s = getInfo('scenario');

    s.idx = [s.idx, obj.nb_steps_init];
    
    if (~isempty(p.Scene))
        s.scene = [s.scene, {p.Scene}];
        s.unique_idx = unique([s.scene{:}]);
    else
        s.scene = [s.scene, {s.scene{end}}];
    end

    adjustLength(p.Steps, true);
    
    setInfo('scenario', s);

    obj.nb_steps_final = obj.nb_steps_final + getInfo('nb_steps');
    obj.classif_mfi = [obj.classif_mfi ; repmat({'none_none'}, getInfo('nb_steps'), 1)];

    initializeScenario(obj, 'Initialize', false);

    if p.Run
        obj.run();
    end

end


% === 'RUN' FUNCTION [BEG] === %
function run (obj)

    nb_steps = getInfo('nb_steps');

    % --- DISPLAY --- %
    obj.displayProgressBar('init');
    % --- DISPLAY --- %
        
    for iStep = obj.nb_steps_init:obj.nb_steps_final
        obj.iStep = iStep;

        % --- DISPLAY --- %
        obj.displayProgressBar('update');
        % --- DISPLAY --- %

        % --- Compute Audio & Visual Localization
        obj.ALKS.execute();
        audio_theta = obj.ALKS.hyp_hist(end); % --- Grab the audio localization output
        
        obj.VLKS.execute();

        % --- Object detection
        % [create_new, do_nothing] = obj.simulationStatus(iStep);
        % --- ODKS aims at providing an information about objects in the scene
        % --- In particular, it will process the incoming data to make an hypothesis about the novelty of these data.
        obj.ObjectDetectionKS.execute();
        
        object_detection = obj.ObjectDetectionKS.decision(1, end); % --- 1st value: 1(create object) or 2(update object)
        obj.current_object = obj.ObjectDetectionKS.decision(2, end); % --- 2nd value: id of the object emitting. ≠ from focus!
        % if obj.current_object == obj.HTMFocusKS.focused_object
        %     object_detection == 2;
        % end
        obj.current_object_hist(end+1) = obj.current_object; % --- Update history of sources

        % if create_new 
        % --- Processing the ObjectDetectionKS output for time step iStep
        if object_detection == 1 % --- Create new object
            % theta = generateAngle(obj.gtruth{iStep, 1});
            %visual_theta = obj.VLKS.getVisualLocalization(); % --- Grab the visual localization output

            obj.degradeData(audio_theta, iStep); % --- Remove visual components if object is NOT in field of view
            obj.MSOM.idx_data = 1; % --- Update status of MSOM learning

            obj.RIR.updateData(obj.data(:, iStep), audio_theta); % --- Updating the RIR observed data
            obj.RIR.addObject(); % --- Add the object
            setObject(obj, obj.current_object, 'presence', true); % --- The object is present but not necessarily facing the robot
            % setObject(obj, 0, 'presence', true);

        % elseif ~create_new && ~do_nothing % --- update object
        elseif object_detection == 2 % --- Update object
            % theta = getObject(obj, obj.current_object, 'theta');
            % theta = obj.ALKS.hyp_hist(end); % --- Grab the audio localization output

            obj.degradeData(audio_theta, iStep); % --- Remove visual components if object is NOT in field of view
            obj.RIR.updateData(obj.data(:, iStep), audio_theta); % --- Updating the RIR observed data
            obj.RIR.updateObject(); % --- Update the current object
            obj.MSOM.idx_data = obj.MSOM.idx_data+1;
            setObject(obj, obj.current_object, 'presence', true); % --- The object is present but not necessarily facing the robot

        % elseif ~create_new && do_nothing % --- silence phase
        elseif object_detection == 0 % --- silence phase
            if obj.RIR.nb_objects > 0 && getObject(obj, obj.current_object_hist(end-1), 'presence') && obj.current_object_hist(end-1) ~= 0
                setObject(obj, obj.current_object_hist(end-1), 'presence', false);
                o = obj.RIR.getEnv().objects{obj.current_object_hist(end-1)}.theta_hist(1);
                obj.RIR.getEnv().objects{obj.current_object_hist(end-1)}.theta_hist(end+1) = o;
                obj.RIR.getEnv().objects{obj.current_object_hist(end-1)}.theta = o;
                % obj.RIR.getLastObj().presence = false;
            end
            obj.RIR.updateData(obj.data(:, iStep), -1);
        end
        obj.RIR.updateObjects();

        obj.HTMFocusKS.computeFocus();

        obj.MotorOrderKS().moveHead();

        obj.updateAngles();

        if sum(obj.data(getInfo('nb_audio_labels')+1:end, iStep)) == 0
            obj.statistics.max_shm(iStep) = 0;
        end

        obj.retrieveMfiCategorization(iStep) ; %% Data is fed into MFImod

        % obj.storeMsomWeights(iStep);

        % obj.info = getInfo('all');

        obj.EMKS.updateMap();

    end

    obj.EMKS.endSimulation();

    obj.saveData();

    obj.MSOM.assignNodesToCategories();

    % --- DISPLAY --- %
    obj.displayProgressBar('end');
    % --- DISPLAY --- %

    computeStatistics(obj);

    playNotification();

end
% === 'RUN' FUNCTION [END] === %

function updateAngles (obj)
    if obj.current_object == 0
        return;
    end
    head_position = obj.RIR.head_position;
    objects_id = 1:obj.RIR.nb_objects;
    objects_id(obj.current_object) = [];
    if isempty(objects_id)
        return;
    end
    for iObject = objects_id
        previous_theta = getObject(obj, iObject, 'theta_hist');
        theta = abs(head_position - previous_theta(end));
        obj.RIR.getEnv().objects{iObject}.updateAngle(theta);
    end
end

function degradeData (obj, theta, iStep)
    if ~isInFieldOfView(theta)
        obj.data(getInfo('nb_audio_labels')+1:end, iStep) = 0;
    end
end

function storeMsomWeights (obj, iStep)
    if mod(iStep, getInfo('nb_steps')/10) == 0 && iStep ~= 1
        msom_weights = getappdata(0, 'msom_weights');
        msom_weights = [msom_weights ; obj.MSOM.weights_vectors];
        setappdata(0, 'msom_weights', msom_weights);
    end
end

function retrieveMfiCategorization (obj, iStep)
    if sum(obj.data(:, iStep)) ~= 0
        % data = obj.RIR.getLastObj().getBestData();
        data = retrieveObservedData(obj, 0, 'best');
        obj.classif_mfi{iStep} = obj.MFI.inferCategory(data);
    end
end

% function [create_new, do_nothing] = simulationStatus (obj, iStep)
%     % --- No object in the scene
%     if sum(obj.data(:, iStep)) == 0             % --- silence phase
%         create_new = false;
%         do_nothing = true;
%     % --- Create a new object
%     elseif sum(obj.data(:, iStep-1)) == 0 &&... % --- previous iStep was silence
%            sum(obj.data(:, iStep)) ~= 0         % --- current iStep is not anymore
%         create_new = true;
%         do_nothing = false;
%     % --- Update current object
%     else                                        % --- within an object
%         create_new = false;
%         do_nothing = false;
%     end
% end


% function plot (obj, string)

%     plot_fcn = getInfo('plot_fcn');
    
%     idx = find(strcmp(string, plot_fcn));

%     switch idx
%     case 1
%         plotFocus(obj);
%     case 2
%         plotGoodClassif(obj);
%     case 3
%         plotGoodClassifObj(obj);
%     case 4
%         plotSHM(obj);
%     case 5
%         plotHits(obj);
%     case 6
%         plotHeadMovements(obj);
%     case 7
%         plotStatistics(obj);
%     end
% end

function displayProgressBar (obj, sim_status)
    if strcmp(sim_status, 'init')
        textprogressbar('HTM: running simulation -- ');
    elseif strcmp(sim_status, 'end')
        textprogressbar(' -- DONE');
    else
        iStep = obj.iStep;
        relative_tstep = (iStep - obj.nb_steps_init) + 1;
        relative_final = (obj.nb_steps_final - obj.nb_steps_init) + 1;
        t = 100*(relative_tstep/relative_final);
        textprogressbar(t);
    end
end

function saveData (obj)

    if obj.save
        disp('HTM: Saving data');
        simuData = struct('gtruth',{obj.gtruth}, ...
                          'AVPairs', {obj.AVPairs}, ...
                          'audioLabels', {obj.audio_labels}, ...
                          'visualLabels', {obj.visual_labels}, ...
                          'data', {obj.data}, ... 
                          'thetaObj', {obj.theta_obj}, ...
                          'distHist', {obj.dist_hist} ) ;
        
         if (~exist(['Data/', num2str(obj.nb_AVPairs), '_', num2str(obj.nb_steps)]) )
              mkdir('Data', [num2str(obj.nb_AVPairs), '_', num2str(obj.nb_steps)]);
         end

        save(['Data/', num2str(obj.nb_AVPairs), '_', num2str(obj.nb_steps), '/', datestr(datetime('now'))], 'simuData');
        %save(['Data/simu_results/', datestr(datetime('now'))],'simuData');
    end

end


end
% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %