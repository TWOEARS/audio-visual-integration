% 'HeadTurningModulationKS' class
% This knowledge source triggers head movements based on two modules:
% 1. MultimodalFusionAndInference module
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
    data = [];

    gtruth_data = [];
    gtruth;

    classif_max = {};
    classif_mfi = {};

    statistics = [];

    sources = [];

    RIR;  % Robot Internal Representation
    MSOM; % Multimodal SelfOrganizing Map
    MFI;  % Multimodal Fusion & Inference
    DW;   % Dynamic Weighting
    
    MOKS; % Motor Order 
    FCKS; % Focus Computation Focus
    EMKS; % Environmental Map
    ODKS; % Object Detection
    ALKS; % Audio Location
    VLKS; % Visual Location
    ACKS; % Audio Classifiers
    VCKS; % Visual Classifiers
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

    obj.save = p.Save;
    obj.load = p.Load;

    initializeParameters();
    if p.Load
        disp('HTM: loading simulation');
        [filename, pathname] = uigetfile('~/SciWork/Dat/HTM');
        data = load([pathname, filename]);
        data = data.data;
        q = getInfo('q');
        data.info.q = q;
        setInfo('load', true);
        setappdata(0, 'information', data.info);
        obj.nb_steps_final = getInfo('nb_steps');

        obj.gtruth = data.htm.gtruth;
        obj.gtruth_data = data.htm.gtruth_data;
        obj.data = obj.gtruth_data;
        obj.sources = data.htm.sources;
        obj.statistics = data.htm.statistics;
        obj.classif_mfi = repmat({'none_none'}, getInfo('nb_steps'), 1);
    else
        disp('HTM: creating simulation');
        % initializeParameters();

        obj.nb_steps_final = getInfo('nb_steps');

        obj.statistics = getInfo('statistics');
        obj.classif_mfi = repmat({'none_none'}, getInfo('nb_steps'), 1);

        initializeScenario(obj);
    end

    obj.MSOM = MultimodalSelfOrganizingMap();
    obj.MFI = MultimodalFusionAndInference(obj);
    obj.DW = DynamicWeighting(obj);
    obj.RIR = RobotInternalRepresentation(obj);
    
    obj.FCKS = FocusComputationKS(obj);
    obj.MOKS = MotorOrderKS(obj, obj.FCKS);
    
    % if EMKS
        obj.EMKS = EnvironmentalMapKS(obj);
    % end

    obj.ALKS = AudioLocalizationKS(obj);
    obj.VLKS = VisualLocalizationKS(obj);

    obj.ACKS = AudioClassificationExpertsKS(obj);
    obj.VCKS = VisualClassificationExpertsKS(obj);

    obj.ODKS = ObjectDetectionKS(obj);

    obj.run();
end
% === CONSTRUCTOR [END] === %

% === Alternative to the constructor === %
% function continueSimulation (obj, varargin)
%     p = inputParser();
%       p.addOptional('Scene', [],...
%                     @(x) validateattributes(x, {'numeric'},{'vector', 'integer', 'positive'}));
%       p.addOptional('Steps', 1000,...
%                     @(x) validateattributes(x, {'numeric'}, {'integer', 'positive'}));
%       p.addOptional('Run', true,...
%                     @islogical);
%     p.parse(varargin{:});
%     p = p.Results;

%     obj.nb_steps_init = obj.nb_steps_init + getInfo('nb_steps');

%     s = getInfo('scenario');

%     s.idx = [s.idx, obj.nb_steps_init];
    
%     if (~isempty(p.Scene))
%         s.scene = [s.scene, {p.Scene}];
%         s.unique_idx = unique([s.scene{:}]);
%     else
%         s.scene = [s.scene, {s.scene{end}}];
%     end

%     adjustLength(p.Steps, true);
    
%     setInfo('scenario', s);

%     obj.nb_steps_final = obj.nb_steps_final + getInfo('nb_steps');
%     obj.classif_mfi = [obj.classif_mfi ; repmat({'none_none'}, getInfo('nb_steps'), 1)];

%     initializeScenario(obj, 'Initialize', false);

%     if p.Run
%         obj.run();
%     end

% end


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

        % --- Audio Localization
        obj.ALKS.execute();
        % --- Visual Localization
        obj.VLKS.execute();
        % --- Object detection
        obj.ODKS.execute();

        % --- Processing the ObjectDetectionKS output for time step iStep
        if ~obj.createNew() && ~obj.updateObject()
            obj.setPresence(false);
            obj.RIR.updateData();
        else
            obj.degradeData(); % --- Remove visual components if object is NOT in field of view
            obj.RIR.updateData(); % --- Updating the RIR observed data
            if obj.createNew()
                obj.MSOM.idx_data = 1; % --- Update status of MSOM learning
                obj.RIR.addObject(); % --- Add the object
            elseif obj.updateObject()
                obj.MSOM.idx_data = obj.MSOM.idx_data+1;
                obj.RIR.updateObject(); % --- Update the current object
            end
            obj.setPresence(true);
        end

        obj.RIR.updateObjects();

        obj.FCKS.execute();

        obj.MOKS.execute();

        obj.updateAngles();

        if sum(obj.data(getInfo('nb_audio_labels')+1:end, iStep)) == 0
            obj.statistics.max_shm(iStep) = 0;
        end

        obj.retrieveMfiCategorization();

        % obj.storeMsomWeights(iStep);

        obj.EMKS.updateMap();

    end

    obj.EMKS.endSimulation();

    % --- DISPLAY --- %
    obj.displayProgressBar('end');
    % --- DISPLAY --- %
    
    obj.MSOM.assignNodesToCategories();

    % computeStatistics(obj);

    obj.saveData();

    % playNotification();

end
% === 'RUN' FUNCTION [END] === %

function setPresence (obj, bool)
    if ~bool 
        if obj.RIR.nb_objects > 0 
            % idx = obj.ODKS.id_object(end-1);
            idx = getHypothesis(obj, 'ODKS', 'id_object');
            idx = idx(end-1);
            if idx ~= 0 && getObject(obj, idx, 'presence')
                setObject(obj, idx, 'presence', false);
                setObject(obj, idx, 'requests', 'init');
            end
        end
    else
        idx = getLastHypothesis(obj, 'ODKS', 'id_object');
        setObject(obj, idx, 'presence', true); % --- The object is present but not necessarily facing the robot
    end
end

function bool = createNew (obj)
    bool = getLastHypothesis(obj, 'ODKS', 'create_new');
end

function bool = updateObject (obj)
    bool = getLastHypothesis(obj, 'ODKS', 'update_object');
end

% === Given the position of the head, updates the position of all the sources observed so far
function updateAngles (obj)
    if obj.RIR.nb_objects == 0
        return;
    end
    for iObject = 1:obj.RIR.nb_objects
        theta_object = getObject(obj, iObject, 'theta');
        theta = mod(360 - obj.MOKS.motor_order(end) + theta_object(end), 360);
        obj.RIR.getEnv().objects{iObject}.updateAngle(theta);
    end
end

% === If the robot is not facing the audio source, visual data perceived should not be taken into account
function degradeData (obj)
    theta = getLastHypothesis(obj, 'ALKS');
    if ~isInFieldOfView(theta)
        obj.data(getInfo('nb_audio_labels')+1:end, obj.iStep) = 0;
    end
end

function storeMsomWeights (obj)
    iStep = obj.iStep;
    if mod(iStep, getInfo('nb_steps')/10) == 0 && iStep ~= 1
        msom_weights = getappdata(0, 'msom_weights');
        msom_weights = [msom_weights ; obj.MSOM.weights_vectors];
        setappdata(0, 'msom_weights', msom_weights);
    end
end

function retrieveMfiCategorization (obj)
    % if sum(obj.data(:, obj.iStep)) ~= 0
    iStep = obj.iStep;
    if obj.sources(iStep) ~= 0
        id_object = getLastHypothesis(obj, 'ODKS', 'id_object');
        data = retrieveObservedData(obj, id_object, 'best');
        obj.classif_mfi{iStep} = obj.MFI.inferCategory(data);
    end
    obj.statistics.mfi(iStep) = strcmp(obj.classif_mfi{iStep}, obj.gtruth(iStep, 1));
    obj.statistics.mfi_mean(1:iStep) = cumsum(obj.statistics.mfi(1:iStep)) ./ (1:iStep)';
    obj.statistics.max_mean_shm(1:iStep) = cumsum(obj.statistics.max_shm(1:iStep)) ./ (1:iStep)';
end

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
        fname = '~/SciWork/Dat/HTM/';
        data = struct();
        data.info = getInfo('all');
        data.htm = obj;
        data.weights_vectors = obj.MSOM.weights_vectors;
        save([fname, datestr(datetime('now'))], 'data');
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