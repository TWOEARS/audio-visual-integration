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

    % theta_obj = [];
    
    RIR;

    data = [];

    gtruth_data = [];
    gtruth;

    classif_max = {};
    classif_mfi = {};

    statistics = [];
    MSOM;
    MFI;
    MotorOrderKS;


end

properties (SetAccess = private, GetAccess = public)
    info;
end

properties (SetAccess = private, GetAccess = public)
    nb_steps_init = 1;
    nb_steps_final = 0;
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

% ========================= %
% === CONSTRUCTOR [BEG] === %
% ========================= %
function obj = HeadTurningModulationKS (varargin)

    p = inputParser();
      p.addOptional('Scene', 0,...
                    @(x) validateattributes(x, {'numeric'},{'vector', 'integer', 'positive'}));
      p.addOptional('Steps', 1000,...
                    @(x) validateattributes(x, {'numeric'}, {'integer', 'positive'}));
      p.addOptional('Save', false,...
                    @islogical);
      p.addOptional('Load', false,...
                    @islogical);
      p.addOptional('Run', true,...
                    @islogical);
      p.addOptional('GUI', false,...
                    @islogical);
    p.parse(varargin{:});
    p = p.Results;

    addpath(genpath('../../HTM_v2'));

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
        % disp('HTM: No appropriate simulation data found');
        disp('HTM: creating simulation');

        initializeParameters(p.Steps, p.Scene);

        obj.nb_steps_final = getInfo('nb_steps');

        [obj.data, obj.gtruth, gs] = initializeScenario();
        
        obj.statistics = getInfo('statistics');
        obj.statistics.max = gs(:, 1);
        obj.statistics.max_mean = gs(:, 2);
        obj.gtruth_data = obj.data;

        obj.classif_mfi = repmat({'none_none'}, getInfo('nb_steps'), 1);

    end

    obj.MSOM = MultimodalSelfOrganizingMap();
    obj.MFI = MultimodalFusionAndInference(obj.MSOM);
    obj.MotorOrderKS = MotorOrderKS(obj);
    obj.RIR = RobotInternalRepresentation(obj);

    if p.Run
        obj.run();
    end

end
% ========================= %
% === CONSTRUCTOR [END] === %
% ========================= %

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

    [data, gtruth, gs] = initializeScenario();

    obj.data = [obj.data, data];
    obj.gtruth = [obj.gtruth ; gtruth];
    obj.gtruth_data = [obj.gtruth_data, data];
    obj.statistics.max = [obj.statistics.max ; gs(:, 1)];
    obj.statistics.max_mean = [obj.statistics.max_mean ; gs(:, 2)];

    obj.classif_mfi = [obj.classif_mfi ; repmat({'none_none'}, getInfo('nb_steps'), 1)];

    if p.Run
        obj.run();
    end

end

% -------------------------- %
% --- Run function [BEG] --- %
% -------------------------- %
function run (obj)

    nb_steps = getInfo('nb_steps');

    % --- DISPLAY --- %
    textprogressbar('HTM: running simulation -- ');
    % --- DISPLAY --- %
        
    for iStep = obj.nb_steps_init:obj.nb_steps_final

        % --- DISPLAY --- %
        t = 100*(iStep/obj.nb_steps_final);
        textprogressbar(t);
        % --- DISPLAY --- %

        % --- Object detection
        [create_new, do_nothing] = obj.simulationStatus(iStep);

        if create_new % --- create new object
            theta = generateAngle();
            d = generateDistance();
            % --- Degrade data if object is NOT in field of view
            obj.degradeData(theta, iStep);
            obj.MSOM.idx_data = 1;
            % if obj.RIR.nb_objects > 0
            %     obj.RIR.getLastObj().presence = false ;
            % end

            obj.RIR.updateData(obj.data(:, iStep), theta, d);
            obj.RIR.addObject();
        elseif ~create_new && ~do_nothing % --- update object
            theta = getObject(obj, 0, 'theta');
            % --- Degrade data if object is NOT in field of view
            obj.degradeData(theta, iStep);
            obj.RIR.updateData(obj.data(:, iStep), theta, d);
            obj.RIR.updateObject();
            obj.MSOM.idx_data = obj.MSOM.idx_data+1;
        elseif ~create_new && do_nothing % --- silence phase
            if obj.RIR.nb_objects > 0
                setObject(obj, 0, 'presence', false);
                % obj.RIR.getLastObj().presence = false;
            end
            obj.RIR.updateData(obj.data(:, iStep), 0, 0);
        end
        obj.RIR.updateObjects(iStep) ;

        % !!!!!!!!!!!!!!!!!!!!!!!!!!!! %
        % --- MOVE TO MOTORORDERKS --- %
        % !!!!!!!!!!!!!!!!!!!!!!!!!!!! %
        obj.MotorOrderKS().moveHead();

        % obj.moveHead();

        obj.retrieveMfiCategorization(iStep) ; %% Data is fed into MFImod

        obj.storeMsomWeights(iStep);

        obj.info = getInfo('all');

    end

    obj.saveData();

    % --- DISPLAY --- %
    textprogressbar(' -- DONE');
    % --- DISPLAY --- %

    computeStatistics(obj);

    [y, fs] = audioread('notification.wav');
    soundsc(y, fs);

end
% --- Run function (END) --- %

function degradeData (obj, theta, iStep)
    if ~isInFieldOfView(theta)
        obj.data(getInfo('nb_audio_labels')+1:end, iStep) = 0 ;
    end
end

function storeMsomWeights (obj, iStep)
    if mod(iStep, getInfo('nb_steps')/10) == 0 && iStep ~= 1
        msom_weights = getappdata(0, 'msom_weights');
        msom_weights = [msom_weights ; obj.MFI.MSOM.som_weights];
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

function [create_new, do_nothing] = simulationStatus (obj, iStep)
    if sum(obj.data(:, iStep)) == 0             % --- silence phase
        create_new = false;
        do_nothing = true;
    elseif sum(obj.data(:, iStep-1)) == 0 &&... % --- previous iStep was silence
           sum(obj.data(:, iStep)) ~= 0         % --- current iStep is not anymore
        create_new = true;
        do_nothing = false;
    else                                        % --- within an object
        create_new = false;
        do_nothing = false;
    end
end


function plot (obj, string)

    plot_fcn = getInfo('plot_fcn');
    
    idx = find(strcmp(string, plot_fcn));

    switch idx
    case 1
        plotFocus(obj);
    case 2
        plotGoodClassif(obj);
    case 3
        plotGoodClassifObj(obj);
    case 4
        plotSHM(obj);
    case 5
        plotHits(obj);
    case 6
        plotHeadMovements(obj);
    case 7
        plotStatistics(obj);
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


% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end