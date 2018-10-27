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
    naive_focus = 0;

    information = [];
end

properties (SetAccess = public, GetAccess = public)
    nb_steps_init = 1;
    nb_steps_final = 0;

    % detected_objects;

    iStep = 0;

    save = false;
    load = false;
    GUI = true;
    tictoc = false;
    elapsed_time = 0.0;
    continue_simulation = false;

    t_first_emission = [];
    t_classif = [];
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
      p.addOptional('GUI', true,...
                    @islogical);
      p.addOptional('TicToc', false,...
                    @islogical);
      p.addOptional('NewEnv', false,...
                    @islogical);
      p.addOptional('Run', true,...
                    @islogical);
      p.addOptional('LoadTimeLine', false,...
                    @islogical);
    p.parse(varargin{:});
    p = p.Results;

    obj.save = p.Save;
    obj.load = p.Load;
    obj.GUI = p.GUI;
    obj.tictoc = p.TicToc;

    if p.Load
        initializeParameters(obj);
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
        obj.classif_mfi = cell(1, 5);
        for iSource = 1:getInfo('nb_sources')
            obj.classif_mfi{iSource} = repmat({'none_none'}, getInfo('nb_steps'), 1);
        end
        setInfo('timeline', data.info.timeline);
        setInfo('repartition', data.info.repartition);
        % obj.classif_mfi = repmat({'none_none'}, getInfo('nb_steps'), 1);
    % elseif p.NewEnv
        % === DO NOT CREATE NEW MFI, DW OR RIR
        % === CREATE A NEW ENVIRONMENT ONLY
        % obj.RIR.addEnvironment();
        % initializeParameters(obj);
        % obj.nb_steps_final = getInfo('nb_steps');
        % obj.RIR.environments{end}.MSOM = MultimodalSelfOrganizingMap();
        % obj.RIR.environments{end}.DW = DynamicWeighting(obj);
    else
        disp('HTM: creating simulation');
        initializeParameters(obj);
        % initializeParameters();

        obj.nb_steps_final = getInfo('nb_steps');

        %obj.statistics = getInfo('statistics');

        % initializeScenario(obj);
    end

    % if ~p.NewEnv
        obj.MSOM = MultimodalSelfOrganizingMap();
        obj.MFI = MultimodalFusionAndInference(obj);
        obj.RIR = RobotInternalRepresentation(obj);
        obj.DW = obj.RIR.environments{end}.DW;
        
        obj.FCKS = FocusComputationKS(obj);
        obj.MOKS = MotorOrderKS(obj, obj.FCKS);

        obj.SSKS = StreamSegregationKS(obj);
        
        obj.ALKS = AudioLocalizationKS(obj);
        obj.VLKS = VisualLocalizationKS(obj);

        obj.ACKS = AudioClassificationExpertsKS(obj);
        obj.VCKS = VisualClassificationExpertsKS(obj);

        obj.ODKS = ObjectDetectionKS(obj);
    % end
    
    if obj.GUI
        obj.EMKS = EnvironmentalMapKS(obj);
    end
    disp(getInfo('repartition'));
    % k = waitforbuttonpress();

    if p.Run
        obj.run();
    end
end
% === CONSTRUCTOR [END] === %

function newEnvironment (obj)
    initializeParameters(obj, 'new');
    obj.RIR.addEnvironment();
    obj.RIR.nb_objects = 0;
    obj.DW = getEnvironment(obj, 0, 'DW');
    % obj.nb_steps_init = obj.nb_steps_final + 1;
    % obj.nb_steps_final = obj.nb_steps_final+getInfo('nb_steps');
    obj.nb_steps_final = getInfo('nb_steps');
    obj.FCKS = FocusComputationKS(obj);
    obj.MOKS = MotorOrderKS(obj, obj.FCKS);

    obj.SSKS = StreamSegregationKS(obj);
    
    obj.ALKS = AudioLocalizationKS(obj);
    obj.VLKS = VisualLocalizationKS(obj);

    obj.ACKS = AudioClassificationExpertsKS(obj);
    obj.VCKS = VisualClassificationExpertsKS(obj);

    obj.ODKS = ObjectDetectionKS(obj);
    
    obj.naive_shm = {};
    obj.naive_focus = 0;
    obj.run();
end

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

    % wvectors = cell(1, numel(vec));

    nb_steps = getInfo('nb_steps');

    % --- DISPLAY --- %
    obj.displayProgressBar('init');
    % --- DISPLAY --- %
    
    if obj.tictoc
        tic;
    end
    timeline = getInfo('timeline');
    obj.t_first_emission = arrayfun(@(x) timeline{x}(2), 1:numel(timeline));
    obj.t_classif = zeros(1, numel(timeline));


    % vec = [1, 10, 20, 30, 40, 50, 100, 125, 150, 175, 200:50:500];
    for iStep = obj.nb_steps_init:obj.nb_steps_final
        % tt = find(iStep == vec);
        % if ~isempty(tt)
        %     wvectors{tt} = obj.MSOM.weights_vectors;
        % end

        obj.iStep = iStep;
        % disp(iStep);

        % --- DISPLAY --- %
        obj.displayProgressBar('update');
        % --- DISPLAY --- %

        obj.computeNaiveSHM();
        
        if obj.GUI
            obj.EMKS.updateMap();
        end
        
        % --- Stream Segregation
        obj.SSKS.execute();
        % --- Audio Localization
        obj.ALKS.execute();
        % --- Visual Localization
        obj.VLKS.execute();
        % --- Object detection
        obj.ODKS.execute();

        streams = getLastHypothesis(obj, 'SSKS');
        id_objects = getLastHypothesis(obj, 'ODKS', 'id_object');
        for iSource = 1:numel(streams)
            % if streams(iSource) ~= 0
                % --- Processing the ObjectDetectionKS output for time step iStep
                if id_objects(iSource) == 0
                    if obj.RIR.nb_objects ~= 0
                        s = getObject(obj, 'all', 'source');
                        s = find(s == iSource);
                        % obj.setPresence(id_objects(iSource), false);
                        if ~isempty(s)
                            setObject(obj, s, 'presence', false);
                            setObject(obj, s, 'stop_emission', iStep);
                        end
                    end
                else
                    obj.degradeData(iSource); % --- Remove visual components if object is NOT in field of view
                    if obj.createNew(iSource)
                        % obj.MSOM.idx_data = 1; % --- Update status of MSOM learning
                        obj.RIR.addObject(iSource); % --- Add the object
                    elseif obj.updateObject(iSource)
                        % === TO CHANGE!!!!!
                        % obj.MSOM.idx_data = obj.MSOM.idx_data+1;
                        idx_data = getObject(obj, id_objects(iSource), 'idx_data');
                        setObject(obj, id_objects(iSource), 'idx_data', idx_data+1);
                        % === TO CHANGE!!!!!
                        obj.RIR.updateObject(iSource); % --- Update the current object
                        if getObject(obj, id_objects(iSource), 'presence') == false
                            setObject(obj, id_objects(iSource), 'start_emission', iStep);
                        end
                    end
                    setObject(obj, id_objects(iSource), 'presence', true);
                end
            % end
        end
        if obj.tictoc
            obj.elapsed_time = toc;
        end

        obj.RIR.updateObjects();

        obj.FCKS.execute();

        obj.MOKS.execute();

        obj.updateAngles();

        % obj.retrieveMfiCategorization();
        obj.computeNaiveFusion;
        obj.computeStatistics();

        % obj.storeMsomWeights(iStep);

    end

    obj.RIR.environments{end}.terminate();

    if obj.GUI
        obj.EMKS.endSimulation();
    end

    % --- DISPLAY --- %
    obj.displayProgressBar('end');
    % --- DISPLAY --- %
    
    obj.MSOM.assignNodesToCategories();

    % computeStatistics(obj);

    obj.saveData();

    obj.information = getInfo('all');
    % setappdata(0, 'wvectors', wvectors);

    % playNotification();

end
% === 'RUN' FUNCTION [END] === %

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

function computeNaiveFusion (obj)
    na = getInfo('nb_audio_labels');
    nb_sources = getInfo('nb_sources');
    iStep = obj.iStep;
    for iSource = 1:nb_sources;
        data = obj.gtruth_data{iSource}(:, iStep);
        if sum(data) > 0
            if sum(data(1:na) > 0) && sum(data(na+1:end) > 0)
                [~, ma] = max(data(1:na));
                [~, mv] = max(data(na+1:end));
                label = mergeLabels(mv, ma);
                if strcmp(label, obj.gtruth{iSource}(iStep, 1)) == 1
                    obj.statistics.max(iStep, iSource) = 1;
                    if getObject(obj, obj.naive_focus, 'source') == iSource
                        obj.statistics.max2(iStep, iSource) = 1;
                    end
                end
            end
        end
    end

end

function computeStatistics (obj)

    s = obj.statistics;
    
    nb_objects = obj.RIR.nb_objects;
    
    if nb_objects == 0
        return;
    end

    iStep = obj.iStep;
    sources = getObject(obj, 'all', 'source');
    timeline = getInfo('timeline');

    nb_classif_sources = find(obj.t_classif ~= 0);

    for iObject = 1:nb_objects
        iSource = sources(iObject);

        emitting = find(iStep <= timeline{iSource}, 1, 'first');
        if mod(emitting, 2) == 0
            emitting = true;
        else
            emitting = false;
        end
        
        obj.classif_mfi{iSource}(iStep) = {getObject(obj, iObject, 'label')};
        obj.statistics.mfi(iStep, iSource) = strcmp(obj.classif_mfi{iSource}(iStep), obj.gtruth{iSource}(iStep, 1));

        if obj.t_classif(iSource) == 0
            t_classif = strcmp(obj.classif_mfi{iSource}(iStep), 'none_none');
            if t_classif == 0
                obj.t_classif(iSource) = iStep;
            end
        end
        
        if iStep >= obj.t_first_emission(iSource)
            if iStep == obj.t_first_emission(iSource)
                next_val = obj.statistics.mfi(iStep, iSource);
                next_val_max = obj.statistics.max(iStep, iSource);
                next_val_max2 = obj.statistics.max2(iStep, iSource);
            else
                idx = (iStep - obj.t_first_emission(iSource)) + 1;
                idx = idx-1:idx;
                vec = [obj.statistics.mfi_mean(iStep-1, iSource)*(idx(1)), obj.statistics.mfi(iStep, iSource)];
                next_val = cumsum(vec) ./ idx;

                vec_max = [obj.statistics.max_mean(iStep-1, iSource)*(idx(1)), obj.statistics.max(iStep, iSource)];
                next_val_max = cumsum(vec_max) ./ idx;

                vec_max2 = [obj.statistics.max_mean2(iStep-1, iSource)*(idx(1)), obj.statistics.max2(iStep, iSource)];
                next_val_max2 = cumsum(vec_max2) ./ idx;
            end
        end
        obj.statistics.mfi_mean(iStep, iSource) = next_val(end);
        if emitting
            obj.statistics.max_mean(iStep, iSource) = obj.statistics.max_mean(iStep-1, iSource);
            obj.statistics.max_mean2(iStep, iSource) = obj.statistics.max_mean2(iStep-1, iSource);
        else
            obj.statistics.max_mean(iStep, iSource) = next_val_max(end);
            obj.statistics.max_mean2(iStep, iSource) = next_val_max2(end);
        end
        

        if obj.t_classif(iSource) ~= 0
            if iStep == obj.t_classif(iSource)
                next_val2 = obj.statistics.mfi(iStep, iSource);
                % next_val_max2 = obj.statistics.max(iStep, iSource);
            else
                % idx2 = iStep-1:iStep;
                idx2 = (iStep - obj.t_classif(iSource))+1;
                idx2 = idx2-1:idx2;
                vec = [obj.statistics.mfi_mean2(iStep-1, iSource)*(idx2(1)), obj.statistics.mfi(iStep, iSource)];
                next_val2 = cumsum(vec) ./ idx2;

                % vec_max = [obj.statistics.max_mean2(iStep-1, iSource)*(iStep-1), obj.statistics.max(iStep, iSource)];
                % next_val_max2 = cumsum(vec) ./ idx2;
            end
            obj.statistics.mfi_mean2(iStep, iSource) = next_val2(end);
            % obj.statistics.max_mean2(iStep, iSource) = next_val_max2(end);
        end
    end
    
    obj.statistics.max_mean(iStep, end) = mean(obj.statistics.max_mean(iStep, sources));
    obj.statistics.max_mean2(iStep, end) = mean(obj.statistics.max_mean2(iStep, sources));

    obj.statistics.mfi_mean(iStep, end) = mean(obj.statistics.mfi_mean(iStep, sources));
    if ~isempty(nb_classif_sources)
        obj.statistics.mfi_mean2(iStep, end) = mean(obj.statistics.mfi_mean2(iStep, nb_classif_sources));
    end
end

function retrieveMfiCategorization (obj)
    iStep = obj.iStep;
    % pobj = obj.RIR.environments{end}.present_objects';
    pobj = obj.RIR.nb_objects;
    timeline = getInfo('timeline');
    focus = obj.FCKS.focus(end);
    focus = getObject(obj, focus, 'source');

    labels = getObject(obj, 'all', 'label');
    tmp = find(strcmp(labels, 'none_none'));
    idx_obj = 1:pobj;
    idx_obj(tmp) = [];
    
    % for iObject = 1:pobj
    for iObject = idx_obj
        iSource = getObject(obj, iObject, 'source');
        t = getObject(obj, iObject, 'tmIdx');
        t = t(1);


        % --- If missing data -> max_shm = 0
        if focus ~= iSource
            obj.statistics.max_shm(iStep, iSource) = 0;
        end

        obj.classif_mfi{iSource}(iStep) = {getObject(obj, iObject, 'label')};

        t = find(strcmp(obj.classif_mfi{iSource}(1:iStep), 'none_none'), 1, 'last')+1;
        t2 = timeline{iSource}(2);
        % === Binary value
        obj.statistics.mfi(iStep, iSource) = strcmp(obj.classif_mfi{iSource}(iStep), obj.gtruth{iSource}(iStep, 1));
        % === Mean value
        tt = (iStep-t)+1;
        obj.statistics.mfi_mean(t:iStep, iSource) = cumsum(obj.statistics.mfi(t:iStep, iSource)) ./ (1:tt)';
        obj.statistics.mfi_mean2(t2:iStep, iSource) = cumsum(obj.statistics.mfi(t:iStep, iSource)) ./ (1:numel(t2:iStep))';
        
        tmp = find(timeline{iSource} < iStep, 1, 'last');
        if mod(tmp, 2) == 1 % --- take the last value (silence)
            obj.statistics.max_mean_shm(iStep, iSource) = obj.statistics.max_mean_shm(timeline{iSource}(tmp), iSource);
        else % --- take the last value (silence)
            n = numel(t:iStep);
            % obj.statistics.max_mean_shm(t:iStep, iSource) = cumsum(obj.statistics.max_shm(t:iStep, iSource)) ./ (1:n)';
            obj.statistics.max_mean_shm(t:iStep, iSource) = cumsum(obj.statistics.max_shm(t:iStep, iSource)) ./ (1:tt)';
        end
    end
    % obj.RIR.environments{end}.present_objects
    % obj.statistics.mfi_mean(iStep, end) = mean(obj.statistics.mfi_mean(iStep, 1:end-1));
    % if isempty(pobj)
    if pobj == 0 || isempty(idx_obj)
        obj.statistics.mfi_mean(iStep, end) = 0;
        obj.statistics.mfi_mean2(iStep, end) = 0;
        obj.statistics.max_mean_shm(1:iStep, end) = 0;
        obj.statistics.max_mean(1:iStep, end) = 0;
        obj.statistics.max_mean2(1:iStep, end) = 0;
    else
        % pobj = 1:pobj;
        pobj = idx_obj;
        sources = getObject(obj, pobj, 'source');
        obj.statistics.mfi_mean(iStep, end) = mean(obj.statistics.mfi_mean(iStep, sources), 2);
        obj.statistics.mfi_mean2(iStep, end) = mean(obj.statistics.mfi_mean2(iStep, sources), 2);

        obj.statistics.max_mean_shm(iStep, end) = mean(obj.statistics.max_mean_shm(iStep, sources), 2);
        obj.statistics.max_mean(iStep, end) = mean(obj.statistics.max_mean(iStep, sources), 2);
        obj.statistics.max_mean2(iStep, end) = mean(obj.statistics.max_mean2(iStep, sources), 2);
    end
end

function computeNaiveSHM (obj)
    if obj.iStep > 2
        id_object = getHypothesis(obj, 'ODKS', 'id_object');
        obj_update = id_object(:, obj.iStep-2)-id_object(:, obj.iStep-1);
        tmp = find(obj_update < 0);
        if ~isempty(tmp)
            obj.naive_shm{end+1} = id_object(tmp, end);
            obj.naive_focus = obj.naive_shm{end}(1);
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