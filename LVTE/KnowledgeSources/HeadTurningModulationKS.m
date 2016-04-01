% 'HeadTurningModulationKS' class
% This knowledge source triggers head movements based on two modules:
% 1. MultimodalFusionAndInference module;
% (reference to come)
% 2. Dynamic Weighing module 
% (reference: Benjamin Cohen-Lhyver, Modulating the Auditory Turn-to Reflex on the Basis of Multimodal Feedback Loops:
% the Dynamic Weighting Model, in IEEE-ROBIO 2015)
% Author: Benjamin Cohen-Lhyver
% Date: 21.10.15
% Rev. 1.0

classdef HeadTurningModulationKS < AbstractKS
    
properties (SetAccess = public)
    robot ;

    HTM_robot ;

    audio_labels = cell(0) ;

    visual_labels = cell(0) ;

    AVPairs = cell(0) ;

    data = [] ;
    
    % compared_labels = cell(0) ;

    classif_max = {} ;

    classif_mfi = {} ;

    % cpt_goodClassif = 0 ;

    gtruth = cell(0) ;

    current_time = 0 ;
end


properties (SetAccess = public, GetAccess = public)
    nb_labels = 0 ;
    energy_thr = 0.01 ;
    INIT = true ;
    fov = 30 ;
    smoothing_theta = 5 ;
    cpt = 0 ;
    last_movement = 0 ;
    theta_hist = [] ;
    nb_audio_labels = 0 ;
    nb_visual_labels = 0 ;
    nb_AVPairs = 0 ;

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
end


%% execute functionality
function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)
    if isappdata(0, 'HTM_robot')
        obj.HTM_robot = getappdata(0, 'HTM_robot') ;
        obj.audio_labels = getappdata(0, 'audio_labels') ;
        obj.visual_labels = getappdata(0, 'visual_labels') ;
        obj.nb_audio_labels = numel(obj.audio_labels) ;
        obj.nb_visual_labels = numel(obj.visual_labels) ;
        obj.nb_labels = obj.nb_audio_labels + obj.nb_visual_labels ;
        obj.INIT = false ;
    end
    if obj.INIT
        obj.htmINIT() ;
        notify(obj, 'KsFiredEvent') ;
        return ;
    end
    
    fprintf('\nHead Turning Modulation KS evaluation\n');

    obj.cpt = obj.cpt + 1 ;

    [create_new, do_nothing] = obj.createNewObject() ;

    % --- Retrieve vector of probabilities
    classifiers_output = obj.getClassifiersOutput() ;
    % --- Retrieve estimated localisation of sound source
    perceived_angle = obj.getLocalisationOutput() ;
    % --- Retrieve estimated distance of sound source (TODO)
    perceived_distance = 3 ;

    % --- Create a new object
    if create_new
        if obj.HTM_robot.nb_objects > 0
            obj.HTM_robot.getLastObj().presence = false ;
        end
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
    obj.current_time = obj.blackboard.currentSoundTimeIdx ;
    obj.current_time
    % obj.HTM_robot.updateObjects(t) ;
    obj.HTM_robot.updateObjects(obj.cpt) ;

    obj.moveHead() ;

    obj.simulationStatus() ;

    obj.retrieveMfiCategorization(classifiers_output) ;

    if ~isempty(classifiers_output)
        obj.data(:, obj.cpt) = classifiers_output ;
    else
        obj.data(:, obj.cpt) = obj.emptyVector() ;
    end

    % --- Add the motor order to the Blackboard
    % obj.blackboard.addData('moveHead', obj.HTM_robot.focus, false, obj.trigger.tmIdx) ;
    notify(obj, 'KsFiredEvent') ;
% end
end

function retrieveMfiCategorization (obj, classifiers_output)
    if ~isempty(classifiers_output)
        obj.classif_mfi{obj.cpt} = obj.HTM_robot.getMFI().inferCategory(classifiers_output) ;
    else
        obj.classif_mfi{obj.cpt} = 'none_none' ;
    end
end

function simulationStatus (obj)
    AVData = obj.getAVData() ;
    t = obj.current_time ;
    if ~isempty(AVData)
        m1 = find(AVData.t_idx(:, 1) <= t, 1, 'last') ;
        m2 = find(AVData.t_idx(:, 2) >= t, 1, 'first') ;
        if m1 == m2
            a = find(arrayfun(@(x) strcmp(obj.AVPairs{x}(2), AVData.labels{m1}), 1:numel(obj.AVPairs))) ;
            v = a ;
            obj.gtruth{end+1} = [obj.visual_labels{v}, '_', obj.audio_labels{a}] ;
            % end
            % if strcmp(AVData.labels{m1}, 'acceptable')
            %     % a = find(strcmp(obj.AVPairs) ;
            %     v = 1 ;
            % else
            %     a = 1 ;
            %     v = 0 ;
            % end
        else
            a = 0 ;
            v = 0 ;
            obj.gtruth{end+1} = 'none_none' ;
        end
    else
        a = 0 ;
        v = 0 ;
        obj.gtruth{end+1} = 'none_none' ;
    end
    
    obj.simulation_status(1, obj.cpt) = a ;
    obj.simulation_status(2, obj.cpt) = v ;
    % obj.simulation_status(3, obj.cpt) = v ;

end

function request = emptyVector (obj)
    request = zeros(obj.nb_audio_labels+obj.nb_visual_labels, 1) ;
end

function request = getClassifiersOutput (obj)
    audio_hyp = obj.blackboard.getLastData('auditoryIdentityHypotheses') ;
    
    if obj.isInFieldOfView()
        visual_hyp = obj.blackboard.getLastData('visualIdentityHypotheses').data ;
        visual_vec = cell2mat(arrayfun(@(x) visual_hyp(obj.visual_labels{x}),...
                                       1:numel(obj.visual_labels),...
                                       'UniformOutput', false))' ;
    % elseif obj.isEquiProbable()
    else
        visual_vec = zeros(obj.nb_visual_labels, 1) ;
    end

    audio_vec = cell2mat(arrayfun(@(x) audio_hyp.data(x).p,...
                                  1:numel(audio_hyp.data),...
                                  'UniformOutput', false))' ;            
    % --- Concatenate & normalize them
    request = [audio_vec/sum(audio_vec) ; visual_vec/sum(visual_vec)] ;
    request(isnan(request)) = 0 ;
end

function request = getLocalisationOutput (obj)
    hyp_loc = obj.blackboard.getLastData('locationHypotheses') ;
    if ~isempty(hyp_loc)
        hyp_loc = hyp_loc.data ;
        [~, idx] = max(hyp_loc.posteriors) ;
        request = hyp_loc.locations(idx) ;
    else
        request = 0 ;
    end
end

function bool = isInFieldOfView (obj)
    theta = obj.getLocalisationOutput() ;
    if theta <= obj.fov
        bool = true ;
    elseif theta >= 360-obj.fov
        bool = true ;
    else
        bool = false ;
    end
end

function bool = isSoundPresent (obj)
    tmp = obj.getClassifiersOutput() ;
    if sum(tmp(1:obj.nb_audio_labels)) < 0.9
        bool = false ;
    else
        bool = true ;
    end
end

function bool = isFocusedObjectPresent (obj)
    if obj.HTM_robot.getObj(obj.HTM_robot.focus, 'presence')
        bool = true ;
    else
        bool = false ;
    end
end     

function moveHead (obj)
    currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data ;
    % --- If no sound -> make the head turn to 0° (resting state)
    focus = obj.HTM_robot.focus ;
    
    if ~obj.isSoundPresent()
        theta = -currentHeadOrientation ;
        % fprintf('\nMotor order: 0deg (resting state)\n') ;
    % --- Turn to the sound source
    elseif focus ~= 0 && obj.isFocusedObjectPresent()
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

    maxAzimuth = theta + currentHeadOrientation ;
    maxAzimuth = mod(maxAzimuth, 360) ;
    obj.robot.robotController.omegaMax = 1000000.0 ;
    obj.robot.robotController.goalAzimuth = maxAzimuth ;
    obj.robot.robotController.finishedPlatformRotation = false ;
end

function [create_new, do_nothing] = createNewObject (obj)
    % crit = 0 ;
    audio_data = obj.retrieveLastAudioData() ;
    % === Silence
    if all(audio_data(:, end) == 0)
        create_new = false ;
        do_nothing = true ;
        % crit = 0 ;
    % === Produce object
    elseif any(audio_data(:, end-1) ~= 0) && any(audio_data(:, end) ~= 0)
        create_new = false ;
        do_nothing = false ;
        % crit = 1 ;
    % === Create new object
    elseif all(audio_data(:, end-1) == 0) && any(audio_data(:, end) ~= 0)
        create_new = true ;
        do_nothing = false ;
        % crit = 2 ;
    end
    % obj.simulation_status(3, obj.cpt) = crit ;
end

function audio_data = retrieveLastAudioData (obj)
    audio_data_all = obj.blackboard.getData('auditoryIdentityHypotheses') ;
    if numel(audio_data_all) > 1
        audio_data_1 = cell2mat(...
                                arrayfun(@(x) audio_data_all(end-1).data(x).p,...
                                         1:numel(obj.audio_labels),...
                                         'UniformOutput', false)...
                                )' ;
        audio_data_2 = cell2mat(...
                                arrayfun(@(x) audio_data_all(end).data(x).p,...
                                         1:numel(obj.audio_labels),...
                                         'UniformOutput', false)...
                                )' ;
        audio_data = [audio_data_1, audio_data_2] ;
    else
        audio_data = 0 ;
    end
end


function retrieveGroundtruth (obj)
    % obj.gtruth = cell(obj.robot.nb_objects, 1) ;
    al = 0 ;
    vl = 0 ;

    al = obj.simulation_status(1, obj.cpt) ;
    vl = obj.simulation_status(2, obj.cpt) ;

    if al == 0
        obj.gtruth{end+1} = 'none_none' ;
    else
        obj.gtruth{end+1} = [obj.visual_labels{vl}, '_', obj.audio_labels{al}] ;
    end

end

function computeStatisticalPerformance (obj)

    [~, ma] = max(obj.data(1:obj.nb_audio_labels, :)) ;
    [~, mv] = max(obj.data(obj.nb_audio_labels+1:end, :)) ;

    classif_max = cell(1, obj.cpt) ;
    thr_a = 1/obj.nb_audio_labels ;
    thr_v = 1/obj.nb_visual_labels ;
    eq_prob_thr_a = [thr_a-0.2, thr_a+0.2] ;
    eq_prob_thr_v = [thr_v-0.2, thr_v+0.2] ;
    
    for iCpt = 1:obj.cpt
        a = obj.data(1:obj.nb_audio_labels, iCpt) ;
        v = obj.data(obj.nb_audio_labels+1:end, iCpt) ;
        
        if sum(a) < 0.2 && sum(v) < 0.2
            classif_max{iCpt} = 'none_none' ;
        elseif all(a <= eq_prob_thr_a(2)) && all(a >= eq_prob_thr_a(1))
            classif_max{iCpt} = 'none_none' ;
        elseif all(v <= eq_prob_thr_v(2)) && all(v >= eq_prob_thr_v(1))
            classif_max{iCpt} = 'none_none' ;
        elseif sum(a) < 0.2
            classif_max{iCpt} = [obj.visual_labels{mv(iCpt)}, '_', 'none'] ;
        elseif sum(v) < 0.2
            classif_max{iCpt} = ['none', '_', obj.audio_labels{ma(iCpt)}] ;
        else
            classif_max{iCpt} = [obj.visual_labels{mv(iCpt)}, '_', obj.audio_labels{ma(iCpt)}] ;
        end
    end

    obj.classif_max = classif_max ;

    n = obj.cpt ;
    cpt1 = 0 ;
    cpt11 = zeros(1, n) ;
    cpt12 = zeros(1, n) ;
    cpt2 = 0 ;
    cpt21 = zeros(1, n) ;
    cpt22 = zeros(1, n) ;
    cpt3 = 0 ;

    for iCpt = 1:obj.cpt
        if strcmp(classif_max(iCpt), obj.gtruth(iCpt))
            cpt1 = cpt1 + 1 ;
            cpt11(iCpt) = 1 ;
        end

        if strcmp(obj.classif_mfi(iCpt), obj.gtruth(iCpt))
            cpt2 = cpt2 + 1 ;
            cpt21(iCpt) = 1 ;
        end
        cpt12(iCpt) = mean(cpt11(1:iCpt)) ;
        cpt22(iCpt) = mean(cpt21(1:iCpt)) ;
    end

    obj.statistics.max = cpt11 ;
    obj.statistics.max_mean = cpt12 ;
    obj.statistics.mfi = cpt21 ;
    obj.statistics.mfi_mean = cpt22 ;

    % =====================

    aa = zeros(1, numel(obj.AVPairs)) ;
    vv = zeros(1, numel(obj.AVPairs)) ;

    for iPair = 1:numel(obj.AVPairs)
        aa(iPair) = find(strcmp(obj.AVPairs{iPair}(2), obj.audio_labels)) ;
        vv(iPair) = find(strcmp(obj.AVPairs{iPair}(1), obj.visual_labels)) ;
    end

    alpha_a = zeros(1, obj.nb_audio_labels) ;
    alpha_v = zeros(1, obj.nb_visual_labels) ;
    beta_a = zeros(1, obj.nb_audio_labels) ;
    beta_v = zeros(1, obj.nb_visual_labels) ;

    mfi = obj.HTM_robot.getMFI() ;

    for iPair = 1:numel(obj.AVPairs)
        AVPairs{iPair} = [obj.AVPairs{iPair}{1}, '_', obj.AVPairs{iPair}{2}] ;
    end

    nb_steps = 1000 ;

    for iPair = 1:numel(obj.AVPairs)
        iStep = 1 ;
        data = obj.generateProbabilities(aa(iPair), vv(iPair)) ;
        da = data(1:obj.nb_audio_labels) ;
        dv = data(obj.nb_audio_labels+1:end) ;
        cpt5 = 0 ;
        cpt6 = 0 ;
        while iStep < nb_steps

            random_visual = rand(obj.nb_visual_labels, 1) ;
            [~, m] = max(random_visual) ;

            if m == vv(iPair)
                iStep = iStep - 1 ;
            else
                est = mfi.inferCategory([da ; random_visual]) ;
                if strcmp(est, AVPairs{iPair})
                    alpha_a(iPair) = alpha_a(iPair) + 1 ;
                elseif find(strcmp(est, AVPairs))
                    beta_a(iPair) = beta_a(iPair) + 1 ;
                    cpt5 = cpt5 + 1 ;
                else
                    cpt5 = cpt5 + 1 ;
                end
            end
            iStep = iStep + 1 ;
        end
        alpha_a(iPair) = 100*(alpha_a(iPair)/nb_steps) ;
        beta_a(iPair) = 100*(beta_a(iPair)/cpt5) ;

        iStep = 1 ;

        while iStep < nb_steps
            random_audio = rand(obj.nb_audio_labels, 1) ;
            [~, m] = max(random_audio) ;

            if m == aa(iPair)
                iStep = iStep - 1 ;
            else
                est = mfi.inferCategory([random_audio ; dv]) ;
                if strcmp(est, AVPairs{iPair})
                    alpha_v(iPair) = alpha_v(iPair) + 1 ;
                elseif find(strcmp(est, AVPairs))
                    beta_v(iPair) = beta_v(iPair) + 1 ;
                    cpt6 = cpt6 + 1 ;
                else
                    cpt6 = cpt6 + 1 ;
                end
            end
            iStep = iStep + 1 ;
        end
        alpha_v(iPair) = 100*(alpha_v(iPair)/nb_steps) ;
        beta_v(iPair) = 100*(beta_v(iPair)/cpt6) ;
        cpt5, cpt6
    end
    obj.statistics.alpha_a = alpha_a ;
    obj.statistics.alpha_v = alpha_v ;
    obj.statistics.beta_a = beta_a ;
    obj.statistics.beta_v = beta_a ;

end

function data = generateProbabilities (obj, audio_idx, visual_idx)
    % --- Audio vector
    audio_vec = zeros(obj.nb_audio_labels, 1) ;
    tmp = (1-0.6)*rand + 0.6 ;
    audio_vec(audio_idx) = tmp ;
    
    idx_vec = 1:obj.nb_audio_labels ;
    idx_vec(idx_vec == audio_idx) = [] ;
    
    audio_vec(idx_vec) = (1-0.5)*rand(obj.nb_audio_labels-1, 1) ;
    % for iComp = idx_vec
    %     audio_vec(iComp) = 1-((1-sum(audio_vec))*rand + sum(audio_vec)) ;
    % end
    % audio_vec = audio_vec/sum(audio_vec) ;

    % --- Visual vector
    visual_vec = zeros(obj.nb_visual_labels, 1) ;
    tmp = (1-0.6)*rand + 0.6 ;
    
    visual_vec(visual_idx) = tmp ;
    
    idx_vec = 1:obj.nb_visual_labels ;
    idx_vec(idx_vec == visual_idx) = [] ;
    
    visual_vec(idx_vec) = (1-0.5)*rand(obj.nb_visual_labels-1, 1) ;

    % for iComp = idx_vec
    %     visual_vec(iComp) = 1-((1-sum(visual_vec))*rand + sum(visual_vec)) ;
    % end
    % visual_vec = visual_vec/sum(visual_vec) ;
    data = [audio_vec ; visual_vec] ;
end


function AVData = getAVData (obj)

    aud = obj.robot.auditoryGTVector ;

    tmp = arrayfun(@(x) isempty(aud{x}), 1:numel(aud)) ;
    aud(tmp) = [] ;

    nb_sources = numel(aud) ;

    t_idx_all = cell(1, nb_sources) ;

    t_idx = [] ;

    labels_all = cell(1, nb_sources) ;

    cpt = 0 ;

    for iSource = 1:nb_sources
        aud{iSource}(1) = [] ;
        aud{iSource}(strcmp(aud{iSource}, '')) = [] ;

        
        idx = find(arrayfun(@(x) isnumeric(aud{iSource}{x}), 1:numel(aud{iSource}))) ;
        tmp = cell2mat(aud{iSource}(idx)) ;
        
        t_idx = [t_idx ; [tmp(1 :2: end)', tmp(2 :2: end)', ones(numel(tmp)/2, 1)*iSource]] ;

        t_idx_all{iSource} = zeros(numel(tmp)/2, 2) ;
        t_idx_all{iSource}(:, 1) = tmp(1 :2: end) ;
        t_idx_all{iSource}(:, 2) = tmp(2 :2: end) ;

        idx = find(arrayfun(@(x) ~isnumeric(aud{iSource}{x}), 1:numel(aud{iSource}))) ;
        tmp = aud{iSource}(idx) ;

        labels_all{iSource} = [tmp(1 :2: end)', tmp(2 :2: end)'] ;
        cpt = cpt+numel(idx) ;
    end

    [~, idx] = sort(t_idx(:, 1)) ;

    tmp = t_idx ;
    t_idx = zeros(size(tmp)) ;
    labels = cell(numel(idx), 2) ;

    for iLine = 1:numel(idx)
        t_idx(iLine, :) = tmp(idx(iLine), :) ;
        labels(iLine, :) = labels_all{tmp(idx(iLine), 3)}(1, :) ;
        labels_all{tmp(idx(iLine), 3)}(1, :) = [] ;
    end

    AVData.t_idx = t_idx ;
    AVData.labels = labels ;
    AVData.wrong = find(arrayfun(@(x) strcmp(labels{x, 2}, 'wrong'), 1:size(labels, 1))) ;
    AVData.correct = find(arrayfun(@(x) strcmp(labels{x, 2}, 'acceptable'), 1:size(labels, 1))) ;

end

% ==================================== %
% ========== INITIALIZATION ========== %
% ==================================== %

function htmINIT (obj)
    fprintf('\nInitialization of HeadTurningModulationKS\n');
    obj.audio_labels = obj.robot.auditoryCategoryList ;
    setappdata(0, 'audio_labels', obj.audio_labels) ;
    obj.visual_labels = obj.robot.visualCategoryList ;
    setappdata(0, 'visual_labels', obj.visual_labels) ;
    obj.AVPairs = obj.robot.acceptableAVPairs ;
    obj.nb_AVPairs = numel(obj.AVPairs) ;
    obj.HTM_robot = Robot() ;

    obj.nb_audio_labels = numel(obj.audio_labels) ;
    obj.nb_visual_labels = numel(obj.visual_labels) ;
    obj.nb_labels = obj.nb_audio_labels + obj.nb_visual_labels ;
    obj.INIT = false ;
end
% ==================================== %
% ========== INITIALIZATION ========== %
% ==================================== %

% ==================================== %
% ========== PLOT FUNCTIONS ========== %
% ==================================== %

function plotHeadMovements (obj)
    t = obj.robot.getAllObj('theta_hist') ;
    t = arrayfun(@(x) t{x}(1), 1:numel(t)) ;
    % tmp = find(arrayfun(@(x) isempty(t{x}), 1:obj.robot.nb_objects)) ;
    % if ~isempty(tmp)
    %     t{tmp} = obj.robot.getObj(tmp, 'theta') ;
    % end
    % t = cell2mat(arrayfun(@(x) t{x}(1), 1:numel(t), 'UniformOutput', false)) ;
    
    d = cell2mat(obj.robot.getAllObj('d')) ;
    t2 = unique(obj.theta_hist, 'stable') ;
    t2 = t2(2:end) ;

    d2 = [] ;
    cpt =  1 ;
    for iAngle = 1:numel(t)
        if cpt <= numel(t2) 
            if t(iAngle) == t2(cpt)
                d2 = [d2, d(iAngle)] ;
                cpt = cpt + 1 ;
            end
        end
    end
    figure ;
    polar(t, d, '*') ;
    hold on ;
    polar(t2, d2) ;
end


% ===

function plotGoodClassif (obj, varargin)

    p = inputParser ;
      p.addOptional('MinLim', 0) ;
      p.addOptional('MaxLim', 0) ;
      p.addOptional('Lim', [0, 0]) ;
      p.addOptional('Objects', [0, 0]) ;
      p.addOptional('MFI', true) ;
      p.addOptional('Max', true) ;
      p.addOptional('Rect', true) ;
      p.addOptional('Curv', true) ;
    p.parse(varargin{:}) ;
    p = p.Results ;

    if numel(p.Objects) == 1
        p.Objects = [p.Objects, p.Objects] ;
    end

    if sum(p.Objects) == 0
        objects = 1:obj.HTM_robot.nb_objects ;
    else
        objects = p.Objects(1):p.Objects(2) ;
    end

    cpt21 = obj.statistics.mfi ;
    cpt22 = obj.statistics.mfi_mean ;
    cpt11 = obj.statistics.max ;
    cpt12 = obj.statistics.max_mean ;

    correct = zeros(obj.HTM_robot.nb_objects, 1) ;
    correct2 = zeros(obj.HTM_robot.nb_objects, 1) ;
    for iObj = objects
        % === Object focused
        if obj.HTM_robot.getObj(iObj).theta == 0
            idx_audio = find(sum(obj.HTM_robot.getObj(iObj).data(1:obj.nb_audio_labels, :)) == 0, 1, 'last')+1 ;
            idx_vision = find(sum(obj.HTM_robot.getObj(iObj).data(obj.nb_audio_labels+1:end, :)) == 0, 1, 'last')+1 ;
            if ~isempty(idx_audio)
                tidx = obj.HTM_robot.getObj(iObj).tmIdx(idx_audio) ;
            elseif ~isempty(idx_vision)
                tidx = obj.HTM_robot.getObj(iObj).tmIdx(idx_vision) ;
            end
            if mean(cpt21(tidx-1:tidx-1)) > 0.5
                correct(iObj) = 1 ;
            else
                correct(iObj) = -1 ;
            end
            if mean(cpt11(tidx-1:tidx-1)) > 0.5
                correct2(iObj) = 1 ;
            else
                correct2(iObj) = -1 ;
            end
        end
    end

    % correct(p.Objects(1):p.Objects(end))

    C_0 = [0.2, 0.2, 0.2] ;
    C_1 = [0.4, 0.4, 0.4] ;
    C_2 = [0.75, 0.75, 0.75] ;
    C_3 = [1, 1, 1] ;

    figure ;
    hold on ;

    if p.Rect
        for iObj = 1:obj.HTM_robot.nb_objects
            x = obj.HTM_robot.getObj(iObj).tmIdx(1) ;
            X = [x, x, x+30, x+30] ;
            if p.Max
                Y1 = [0.5, 1, 1, 0.5] ;
            else
                Y1 = [0, 1, 1, 0] ;
            end
            Y2 = [0, 0.5, 0.5, 0] ;

            if correct(iObj) == -1
                C1 = C_0 ;
            elseif correct(iObj) == 1
                C1 = C_2 ;
            else
                C1 = C_3 ;
            end

            if correct2(iObj) == -1
                C2 = C_0 ;
            elseif correct2(iObj) == 1
                C2 = C_2 ;
            else
                C2 = C_3 ;
            end
            if p.MFI
                h1 = patch(X, Y1, C1) ;%, 'FaceAlpha', 0.6) ;
            end
            if p.Max
                h2 = patch(X, Y2, C2) ;%, 'FaceAlpha', 0.6) ;
            end
            if all(C1 == C_3)
                % hp = findobj(h,'type','patch');
                % hatch(h1, 45, [0.5, 0.5, 0.5], '-', 12, 2) ;
            end
        end
    end

    if p.Curv
        plot(cpt22(1:end), 'LineWidth', 4,...
                            'LineStyle', '-',...
                            'Color', [0.1, 0.1, 0.1]) ;
        plot(cpt12(1:end), 'LineWidth', 4,...
                            'LineStyle', '-',...
                            'Color', [0.6, 0.6, 0.6]) ;
    end


    lim = [0, 0] ;
    if sum(p.Objects) == 0
        if sum(p.Lim) == 0
            if p.MinLim == 0
                lim(1) = 1 ;
            else
                lim(1) = p.MinLim-10 ;
            end
            if p.MaxLim == 0
                lim(2) = numel(cpt12) ;
            else
                lim(2) = p.MaxLim+10 ;
            end
        else
            lim = p.Lim ;
        end
    else
        lim(1) = obj.HTM_robot.getObj(p.Objects(1)).tmIdx(1)-10 ;
        lim(2) = obj.HTM_robot.getObj(p.Objects(2)).tmIdx(end)+10 ;
    end
    
    set(gca, 'XLim', lim, 'Ylim', [0, 1]) ;

    title 'Mean of good classification over 1 simulation' ;
    xlabel 'time steps' ;
    ylabel 'mean of good classification' ;
end

% ===

function plotGoodClassifDetailed (obj, varargin)
        p = inputParser ;
          p.addOptional('MinLim', 0) ;
          p.addOptional('MaxLim', 0) ;
          p.addOptional('Lim', [0, 0]) ;
          p.addOptional('Objects', [0, 0]) ;
          p.addOptional('MFI', true) ;
          p.addOptional('Max', true) ;
        p.parse(varargin{:}) ;
        p = p.Results ;


    if numel(p.Objects) == 1
        p.Objects = [p.Objects, p.Objects] ;
    end
    if sum(p.Objects) == 0
        objects = 1:obj.HTM_robot.nb_objects ;
    else
        objects = p.Objects(1):p.Objects(2) ;
    end

    cpt21 = obj.statistics.mfi ;
    cpt22 = obj.statistics.mfi_mean ;
    cpt11 = obj.statistics.max ;
    cpt12 = obj.statistics.max_mean ;


    correct = zeros(obj.HTM_robot.nb_objects, 1) ;
    correct2 = zeros(obj.HTM_robot.nb_objects, 1) ;
    for iObj = objects

        % === Object focused
        if obj.HTM_robot.getObj(iObj).theta == 0
            idx_audio = find(sum(obj.HTM_robot.getObj(iObj).data(1:obj.nb_audio_labels, :)) == 0, 1, 'last')+1 ;
            idx_vision = find(sum(obj.HTM_robot.getObj(iObj).data(obj.nb_audio_labels+1:end, :)) == 0, 1, 'last')+1 ;
            if ~isempty(idx_audio)
                tidx = obj.HTM_robot.getObj(iObj).tmIdx(idx_audio) ;
            elseif ~isempty(idx_vision)
                tidx = obj.HTM_robot.getObj(iObj).tmIdx(idx_vision) ;
            end
            if mean(cpt21(tidx-1:tidx-1)) > 0.5
                correct(iObj) = 1 ;
            else
                correct(iObj) = -1 ;
            end
            if mean(cpt11(tidx-1:tidx-1)) > 0.5
                correct2(iObj) = 1 ;
            else
                correct2(iObj) = -1 ;
            end
        end
    end

    figure ;
    hold on ;

    limits = zeros(1, obj.cpt) ;
    tmIdx = zeros(1, obj.cpt) ;
    for iObj = 1:obj.HTM_robot.nb_objects
        x = obj.HTM_robot.getObj(iObj).tmIdx(1) ;
        s = size(obj.HTM_robot.getObj(iObj).data, 2) ;
        X = [x, x, x+(s-1), x+(s-1)] ;
        Y = [0, 1, 1, 0] ;
        
        patch(X, Y, [1, 1, 1], 'LineWidth', 2) ;

        % ttt = min([obj.HTM_robot.getObj(iObj).tmIdx(end-9), obj.HTM_robot.getObj(iObj).tmIdx(1)+29]) ;
        ttt = size(obj.HTM_robot.getObj(iObj).data, 2) ;
        ttt = obj.HTM_robot.getObj(iObj).tmIdx(1:ttt) ;

        tt = ttt ;

        limits(tt) = 1 ;
        
        tmp = ones(1, size(obj.HTM_robot.getObj(iObj).data, 2)) ;
        
        tmp(find(sum(obj.HTM_robot.getObj(iObj).data(obj.nb_visual_labels:end, :)) == 0)) = 0 ;
        tmIdx(tt) = tmp ;
    end

    C_0 = [0.2, 0.2, 0.2] ;
    C_1 = [0.35, 0.35, 0.35] ;
    C_2 = [0.75, 0.75, 0.75] ;
    C_3 = [1, 1, 1] ;

    for iStep = 1:obj.cpt
        % --- Bad Inference
        if cpt21(iStep) == 0
            % --- Missing Data
            if tmIdx(iStep) == 0
                C1 = C_0 ;
            % --- Full Data
            else
                C1 = C_1 ;
            end
        % --- Good Inference
        else
            % --- Missing Data
            if tmIdx(iStep) == 0
                C1 = C_2 ;
            % --- Full Data
            else
                C1 = C_3 ;
            end
        end

        if cpt11(iStep) == 0
            % --- Missing Data
            if tmIdx(iStep) == 0
                C2 = C_0 ;
            % --- Full Data
            else
                C2 = C_1 ;
            end
        else
            % --- Missing Data
            if tmIdx(iStep) == 0
                C2 = C_2 ;
            % --- Full Data
            else
                C2 = C_3 ;
            end
        end
        Y2 = [0, 0.5, 0.5, 0] ;
        if limits(iStep) == 1
            X = [iStep-1, iStep-1, iStep, iStep] ;
            if p.Max
                Y1 = [0.5, 1, 1, 0.5] ;
            else
                Y1 = [0, 1, 1, 0] ;
            end
            patch(X, Y1, C1) ;
            if p.Max
                patch(X, Y2, C2) ;
            end
        end
    end

    lim = [0, 0] ;
    if sum(p.Objects) == 0
        if sum(p.Lim) == 0
            if p.MinLim == 0
                lim(1) = 1 ;
            else
                lim(1) = p.MinLim ;
            end
            if p.MaxLim == 0
                lim(2) = numel(cpt12) ;
            else
                lim(2) = p.MaxLim ;
            end
        else
            lim = p.Lim ;
        end
    else
        lim(1) = obj.HTM_robot.getObj(p.Objects(1)).tmIdx(1) - 2 ;
        lim(2) = obj.HTM_robot.getObj(p.Objects(2)).tmIdx(1) + size(obj.HTM_robot.getObj(p.Objects(2)).data, 2) ;
    end
    
    set(gca, 'XLim', lim, 'Ylim', [0, 1]) ;

    % title 'Mean of good classification over 1 simulation' ;
    xlabel 'time steps' ;
    % ylabel 'mean of good classification' ;

end

% === 

function plotSHM (obj)

    AVPairs = obj.AVPairs ;

    for iPair = 1:numel(AVPairs)
        AVPairs{iPair} = [AVPairs{iPair}{1}, '_', AVPairs{iPair}{2}] ;
    end

    angles = 1 :360/(3+1): 360 ;
    angles = round(angles(1:end)) ;
    cpt = zeros(numel(AVPairs), 1) ;
    positions = [] ;
    positions_naive = [] ;

    for iObj = 1:obj.HTM_robot.nb_objects
        idx = find(strcmp(obj.HTM_robot.getObj(iObj).label, AVPairs)) ;
        % === Object focused
        if obj.HTM_robot.getObj(iObj).theta == 0
            % ff = [ff, obj.HTM_robot.getObj(iObj).theta_hist(1)] ;
            % cpt(idx) = cpt(idx)+1 ;
            positions = [positions ; angles(idx+1)] ;
        % === Object NOT focused
        else
            % ff = [ff, 0] ;
            % positions = [positions ; 0] ;
        end
        positions_naive = [positions_naive, angles(idx+1)] ;
    end

    angles = 0 :360/(9*(3+1)): 359 ;
    angles = deg2rad(angles) ;
    positions = deg2rad(positions) ;
    positions_naive = deg2rad(positions_naive) ;

    figure ; 

    h1 = rose(positions_naive, angles) ; 
    hold on ;
    h2 = rose(positions, angles) ;


    pos = get(gca, 'XLim') ;

    angles = angles(1 :9: end) ;

    h3 = polar(angles(2:end), ones(1, 3)*pos(2)) ;

    % set(h1, 'Color', 'red',...
    set(h1, 'Color', [0.2, 0.2, 0.2],...
            'LineWidth', 5,...
            'LineStyle', '-') ;
    % set(h2, 'Color', [0.6, 0.6, 0.6],...
    set(h2, 'Color', 'red',...
            'LineWidth', 3,...
            'LineStyle', '-') ;

    set(h3, 'LineStyle', 'none',...
            'Marker', '.',...
            'MarkerSize', 50,...
            'Color', [0, 0, 0] ) ;
end

% ===

function plotStatistics (obj)
    s = obj.statistics ;
    d = [s.alpha_a ; s.beta_a ; s.alpha_v ; s.beta_v]' ;
    figure ;
    bar(d, 'grouped') ;

end

% ===

function plotHits (obj, vec)

    msom = obj.HTM_robot.getMFI().MSOM ;
    
    if isstr(vec) || iscell(vec)
        if isstr(vec)
            if strcmp(vec, 'all')
                vec = arrayfun(@(x) [obj.AVPairs{x}{1}, '_', obj.AVPairs{x}{2}], 1:numel(obj.AVPairs), 'UniformOutput', false) ;
            else
                nb_labels = size(vec, 1) ;
                labels = {vec} ;
            end
        end
        if iscell(vec)
            nb_labels = size(vec, 2) ;
            labels = vec ;
        end
        data = cell(nb_labels, 1) ;
        for iLabel = 1:nb_labels
            tmIdx = [] ;
            for iObj = 1:obj.HTM_robot.nb_objects
                t = obj.HTM_robot.getObj(iObj).tmIdx(1) ;
                if strcmp(obj.gtruth{t}, labels{iLabel})
                    idx = find(sum(obj.HTM_robot.getObj(iObj).data(obj.nb_audio_labels+1:end, :)) > 0) ;
                    if ~isempty(idx)
                        s = size(obj.HTM_robot.getObj(iObj).data, 2) ;
                        if s <= 30
                            tidx = s ;
                        else
                            tidx = 30 ;
                        end
                        tmIdx = [tmIdx, obj.HTM_robot.getObj(iObj).tmIdx(1:tidx)] ;
                    end
                end
            end
            data{iLabel} = obj.data(:, tmIdx) ;
        end
    end

    subplot_dim2 = ceil(sqrt(nb_labels)) ;
    subplot_dim1 = numel(labels) - subplot_dim2 ;
    subplot_dim1 = max([subplot_dim1, 1]) ;

    for iLabel = 1:nb_labels
        vec = mean(data{iLabel}, 2) ;
        axis ;
        subplot(subplot_dim1, subplot_dim2, iLabel) ;

        set(gca, 'XLim' , [1, msom.som_dimension(1)+1],...
                 'YLim' , [1, msom.som_dimension(1)+1],...
                 'XTick', [1:msom.som_dimension(1)],...
                 'YTick', [1:msom.som_dimension(1)]) ;
        grid on ;
        hold on ;

        s = size(vec, 2) ;
        % d1 = data(:, 4) ;
        dist1 = zeros(msom.nb_nodes, s) ;
        dist2 = zeros(msom.nb_nodes, s) ;
        dist3 = zeros(msom.nb_nodes, s) ;

        for iVec = 1:s
            dist1(:, iVec) = sqrt(sum(bsxfun(@minus, vec(1:msom.modalities(1), iVec)', msom.som_weights{1}).^2, 2)) ;
            dist2(:, iVec) = sqrt(sum(bsxfun(@minus, vec(msom.modalities(1)+1:end, iVec)', msom.som_weights{2}).^2, 2)) ;
            dist3(:, iVec) = dist1(:, iVec).*dist2(:, iVec) ;
        end

        dist1 = mean(dist1, 2) ;
        dist2 = mean(dist2, 2) ;
        dist3 = mean(dist3, 2) ;

        dist1 = 1./dist1 ;
        dist1 = (dist1 - min(dist1))/max(dist1) ;
        
        dist2 = 1./dist2 ;
        dist2 = (dist2 - min(dist2))/max(dist2) ;
        
        dist3 = 1./dist3 ;
        dist3 = (dist3 - min(dist3))/max(dist3) ;


        [I, J] = ind2sub(msom.som_dimension(1), 1:msom.nb_nodes) ;

        for iNode = 1:msom.nb_nodes
            x = I(iNode) ;
            y = J(iNode) ;

            x1 = x + ((1-dist1(iNode))/2) ;
            y1 = y + ((1-dist1(iNode))/2) ;

            x1 = [x1, x1+dist1(iNode), x1+dist1(iNode), x1] ;
            y1 = [y1, y1, y1+dist1(iNode), y1+dist1(iNode)] ;

            x2 = x + ((1-dist2(iNode))/2) ;
            y2 = y + ((1-dist2(iNode))/2) ;

            x2 = [x2, x2+dist2(iNode), x2+dist2(iNode), x2] ;
            y2 = [y2, y2, y2+dist2(iNode), y2+dist2(iNode)] ;

            x3 = [x, x+1, x+1, x] ;
            y3 = [y, y, y+1, y+1] ;
            patch(x3, y3, 'blue', 'FaceAlpha', dist3(iNode)) ;

            if dist1(iNode) >= dist2(iNode)
                patch(x1, y1, 'red') ;
                patch(x2, y2, 'black') ;
            else
                patch(x2, y2, 'black') ;
                patch(x1, y1, 'red') ;
            end
        end
        for iData = 1:size(vec, 2)
            bmu = msom.findBestBMU(vec(:, iData)) ;
            x = I(bmu) ;
            y = J(bmu) ;
            rectangle('Position', [x, y, 1, 1],...
                      'EdgeColor', 'green',...
                      'LineWidth', 4,...
                      'LineStyle', '--') ;
        end
    end

end


end
    
end
