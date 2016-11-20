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
    SSKS; % Stream Segregation
    ALKS; % Audio Location
    VLKS; % Visual Location
    ACKS; % Audio Classifiers
    VCKS; % Visual Classifiers

    naive_shm = {};
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
      p.addOptional('Save', false,...
                    @islogical);
      p.addOptional('Load', false,...
                    @islogical);
    p.parse(varargin{:});
    p = p.Results;

    obj.save = p.Save;
    obj.load = p.Load;

    if p.Load
        initializeParameters();
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
        initializeParameters(obj);
        % initializeParameters();

        obj.nb_steps_final = getInfo('nb_steps');

        %obj.statistics = getInfo('statistics');

        % initializeScenario(obj);
    end

    obj.MSOM = MultimodalSelfOrganizingMap();
    obj.MFI = MultimodalFusionAndInference(obj);
    obj.DW = DynamicWeighting(obj);
    obj.RIR = RobotInternalRepresentation(obj);
    
    obj.FCKS = FocusComputationKS(obj);
    obj.MOKS = MotorOrderKS(obj, obj.FCKS);
    
    obj.EMKS = EnvironmentalMapKS(obj);

    obj.SSKS = StreamSegregationKS(obj);
    
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

        obj.computeNaiveSHM();
        
        obj.EMKS.updateMap();
        
        % --- Stream Segregation
        obj.SSKS.execute();
        % --- Audio Localization
        obj.ALKS.execute();
        % --- Visual Localization
        obj.VLKS.execute();
        % --- Object detection
        obj.ODKS.execute();

        streams = getLastHypothesis(obj, 'SSKS');
        for iSource = 1:numel(streams)
            if streams(iSource) ~= 0
                % --- Processing the ObjectDetectionKS output for time step iStep
                %if ~obj.createNew(iSource) && ~obj.updateObject(iSource)
                tmp = getLastHypothesis(obj, 'ODKS', 'id_object');
                if tmp(iSource) == 0
                    obj.setPresence(iSource, false);
                    % obj.RIR.updateData(iSource);
                else
                    obj.degradeData(iSource); % --- Remove visual components if object is NOT in field of view
                    % obj.RIR.updateData(iSource); % --- Updating the RIR observed data
                    if obj.createNew(iSource)
                        obj.MSOM.idx_data = 1; % --- Update status of MSOM learning
                        obj.RIR.addObject(iSource); % --- Add the object
                    elseif obj.updateObject(iSource)
                        % === TO CHANGE!!!!!
                        obj.MSOM.idx_data = obj.MSOM.idx_data+1;
                        % === TO CHANGE!!!!!
                        obj.RIR.updateObject(iSource); % --- Update the current object
                    end
                    obj.setPresence(iSource, true);
                end
            end
        end

        obj.RIR.updateObjects();

        obj.FCKS.execute();

        obj.MOKS.execute();

        obj.updateAngles();

        obj.retrieveMfiCategorization();

        % obj.storeMsomWeights(iStep);

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

function setPresence (obj, iSource, bool)
    if ~bool 
        if obj.RIR.nb_objects > 0
            idx = getHypothesis(obj, 'ODKS', 'id_object');
            idx = idx(iSource, end-1);
            if idx ~= 0 && getObject(obj, idx, 'presence')
                setObject(obj, idx, 'presence', false);
                setObject(obj, idx, 'requests', 'init');
            end
        end
    else
        idx = getLastHypothesis(obj, 'ODKS', 'id_object');
        idx = idx(iSource);
        setObject(obj, idx, 'presence', true); % --- The object is present but not necessarily facing the robot
    end
end

function bool = createNew (obj, iSource)
    hyp = getLastHypothesis(obj, 'ODKS', 'create_new');
    bool = hyp(iSource);
end

function bool = updateObject (obj, iSource)
    hyp = getLastHypothesis(obj, 'ODKS', 'update_object');
    bool = hyp(iSource);
end

% === Given the position of the head, updates the position of all the sources observed so far
function updateAngles (obj)
    if obj.RIR.nb_objects == 0
        return;
    end
    env = getEnvironment(obj, 0);
    for iObject = 1:obj.RIR.nb_objects
        theta_object = getObject(obj, iObject, 'theta');
        theta = mod(360 - obj.MOKS.motor_order(end) + theta_object(end), 360);
        env.objects{iObject}.updateAngle(theta);
    end
end

% === If the robot is not facing the audio source, visual data perceived should not be taken into account
function degradeData (obj, iSource)
    theta = getLastHypothesis(obj, 'ALKS');
    if ~isInFieldOfView(theta(iSource))
        obj.data{iSource}(getInfo('nb_audio_labels')+1:end, obj.iStep) = 0;
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
    iStep = obj.iStep;
    % pobj = obj.RIR.environments{end}.present_objects';
    pobj = obj.RIR.nb_objects;
    timeline = getInfo('timeline');
    focus = obj.FCKS.focus(end);
    focus = getObject(obj, focus, 'source');
    
    for iObject = 1:pobj
        iSource = getObject(obj, iObject, 'source');
        t = getObject(obj, iObject, 'tmIdx');
        t = t(1);

        % --- If missing data -> max_shm = 0
        if focus ~= iSource
            obj.statistics.max_shm(iStep, iSource) = 0;
        end

        obj.classif_mfi{iSource}(iStep) = {getObject(obj, iObject, 'label')};
        % === Binary value
        obj.statistics.mfi(iStep, iSource) = strcmp(obj.classif_mfi{iSource}(iStep), obj.gtruth{iSource}(iStep, 1));
        % === Mean value
        obj.statistics.mfi_mean(t:iStep, iSource) = cumsum(obj.statistics.mfi(t:iStep, iSource)) ./ (t:iStep)';
        
        tmp = find(timeline{iSource} < iStep, 1, 'last');
        if mod(tmp, 2) == 1 % --- take the last value (silence)
            obj.statistics.max_mean_shm(iStep, iSource) = obj.statistics.max_mean_shm(timeline{iSource}(tmp), iSource);
        else % --- take the last value (silence)
            n = numel(t:iStep);
            obj.statistics.max_mean_shm(t:iStep, iSource) = cumsum(obj.statistics.max_shm(t:iStep, iSource)) ./ (1:n)';
        end
    end
    % obj.RIR.environments{end}.present_objects
    % obj.statistics.mfi_mean(iStep, end) = mean(obj.statistics.mfi_mean(iStep, 1:end-1));
    % if isempty(pobj)
    if pobj == 0
        obj.statistics.mfi_mean(iStep, end) = 0;
        obj.statistics.max_mean_shm(1:iStep, end) = 0;
        obj.statistics.max_mean(1:iStep, end) = 0;
    else
        pobj = 1:pobj;
        sources = getObject(obj, pobj, 'source');
        obj.statistics.mfi_mean(iStep, end) = mean(obj.statistics.mfi_mean(iStep, sources), 2);
        obj.statistics.max_mean_shm(iStep, end) = mean(obj.statistics.max_mean_shm(iStep, sources), 2);
        obj.statistics.max_mean(iStep, end) = mean(obj.statistics.max_mean(iStep, sources), 2);
    end
end

function computeNaiveSHM (obj)
    if obj.iStep > 2
        id_object = getHypothesis(obj, 'ODKS', 'id_object');
        obj_update = id_object(:, obj.iStep-2)-id_object(:, obj.iStep-1);
        tmp = find(obj_update < 0);
        if ~isempty(tmp)
            obj.naive_shm{end+1} = id_object(tmp, end);
        else
            obj.naive_shm{end+1} = tmp;
        end
    else
        obj.naive_shm{end+1} = [];
    end
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