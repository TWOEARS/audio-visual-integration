% 'FocusComputationKS' class
% This knowledge source compute the object to be focused on.
% It is based on two distinct algorithms:
% 1. The Dynamic Weighting module
% 2. The Multimodal Fusion & Inference module
% Author: Benjamin Cohen-Lhyver
% Date: 01.06.16
% Rev. 2.0

classdef FocusComputationKS < handle
% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public)
    htm; 
    % RIR;
    
    nb_sources = 0;

    focus_origin = []; % to be renamed as "focus_type"
    focus = [];
    ratio = [];

    naive_focus = [];
    persistance = 0;
    % hypotheses = [];
end

% ===================== %
% === METHODS (BEG) === %
% ===================== %
methods

% === Constructor [BEG] === %
function obj = FocusComputationKS (htm)
    obj.htm = htm;
    % obj.RIR = htm.RIR;
    obj.nb_sources = getInfo('nb_sources');
    obj.naive_focus = zeros(1, obj.nb_sources);
    obj.persistance = getInfo('persistance');
end
% === Constructor [END] === %

% === Other Methods === %
function execute (obj)
    % RIR = obj.RIR; % --- RobotInternalRepresentaion

%     if RIR.nb_objects == 0
%         obj.focus(end+1) = 0;
%         obj.focus_origin(end+1) = 0;
%         return;
% %     elseif isempty(obj.htm.MSOM.categories)
% %         objects = getLastHypothesis(obj, 'ODKS', 'id_object');
% %         f = find(objects > 0);
% %         t = randi(numel(f));
% %         obj.focus(end+1) = f(t);
% %         return;
%     end

    hyp = getLastHypothesis(obj, 'ODKS', 'id_object');
    if all(hyp == 0)
        focus = 0;
        focus_origin = 0;
    else
        % --- DWmod-based focus computing
        if getInfo('modules') == 2 % --- MFImod only
            dwmod_focus = 0;
        else
            dwmod_focus = obj.computeDWmodFocus();
        end
        % dwmod_focus = 0;

        % --- MFI-based focus computing
        if getInfo('modules') == 1 % --- DWmod only
            mfi_focus = 0;
        else
            mfi_focus = obj.computeMFImodFocus();
        end
        % mfi_focus = 0;
        % --- Comparison of the two results
        if mfi_focus == 0 && dwmod_focus > 0       % --- DWmod takes the lead
            focus = dwmod_focus;
            focus_origin = 1;
        elseif mfi_focus == 0 && dwmod_focus == 0  % --- No focused object
            focus = 0;
            focus_origin = 0;
        % elseif mfi_focus == 0 && dwmod_focus == -1 % --- DWmod focus but AV category not performant
        %     focus = 0;
        %     focus_origin = 0;
        else                                       % --- MFImod takes the lead over the DWmod
            if getInfo('modules') == 3
                focus = mfi_focus;
                c = getCategory(obj, focus, 'Object');
                if c.congruence < 0
                    focus_origin = 1;
                else
                    focus_origin = -1;
                end
            else
                focus = mfi_focus;
                focus_origin = -1;
            end
        end
    end

    % if focus == 0
    %     objects = hyp(hyp ~= 0);
    %     perfs = arrayfun(@(x) isPerformant(obj.htm, objects(x), 'Object'), 1:numel(objects));
    %     %p = perfs(perfs == 0);
    %     if any(perfs == 0)
    %         p = find(perfs == 0);
    %         idx = randi(numel(p));
    %         focus = objects(p(idx));
    %         focus_origin = -1;
    %     end
    % end

    % if focus == 2
    %     focus = 0;
    % end

    obj.focus_origin(end+1) = focus_origin;
    obj.focus(end+1) = focus;
    obj.ratio = cumsum(obj.focus_origin)./(1:numel(obj.focus_origin));

    obj.computeNaiveSHM();
end

% === Compute focused object thanks to the DYNAMIC WEIGHTING module (DWmod) algorithm
function focus = computeDWmodFocus (obj)
    focus = obj.getMaxWeightObject();
    object = getObject(obj, focus);
    if object.weight <= 0 || ~object.presence
        focus = 0;
    end
end

% === Compute focused object thanks to the MULTIMODAL FUSION and INFERENCE module (MFImod) algorithm
function focus = computeMFImodFocus (obj)
    focus = zeros(obj.nb_sources, 1);
    hyp = getLastHypothesis(obj, 'ODKS', 'id_object');
    for iSource = 1:obj.nb_sources
        current_object = hyp(iSource);
        if current_object == 0
            focus(iSource) = 0;
        else
            requests = getObject(obj, current_object, 'requests');
            if requests.check || ~isPerformant(obj.htm, current_object, 'Object')
            % if requests.check && ~isPerformant(obj.htm, current_object, 'Object')
                focus(iSource) = current_object;
            else
                focus(iSource) = 0;
            end
        end
    end

    if numel(obj.focus) <= obj.persistance
        idx = numel(obj.focus)-1;
    else
        idx = obj.persistance;
    end

    search_focus = find(focus == obj.focus(end));

    if obj.focus(end) ~= 0 && ~isempty(search_focus) && any(obj.focus(end-idx:end) ~= search_focus)
        focus = hyp(search_focus);
    elseif sum(focus) ~= 0
        if all(obj.focus(end-idx:end) == obj.focus(end)) && sum(focus > 0) > 1
            focus(focus == obj.focus(end)) = 0;
        end
        foc = focus;
        foc(foc == 0) = [];
        avc = getObject(obj, foc, 'audiovisual_category');
        [val, pos] = unique(avc);
        perfs = zeros(1, numel(pos));
        for iCat = 1:numel(pos)
            perfs(iCat) = getCategory(obj, pos(iCat), 'perf');
        end
        [~, winner] = min(perfs);
        focus = foc(pos(winner(1)));
    else
        if getObject(obj, obj.focus(end), 'presence') && sum(obj.focus(end-idx:end) == obj.focus(end)) < obj.persistance
            focus = obj.focus(end)
        else
            focus = 0;
        end
        % focus = obj.solveConflicts(focus);
	end
end

% function focus = solveConflicts (obj, focuses)
%     % objects = find(focuses);
%     objects = focuses(focuses ~= 0);
%     if isempty(objects)
%         focus = 0;
%     elseif numel(objects) == 1
%         focus = objects;
%     else
%         labels = getObject(obj, objects, 'label');
%         if ~iscell(labels)
%             labels = {labels};
%         end
%         env = getEnvironment(obj, 0);
%         dw = getEnvironment(obj, env.behavior, 'DW');
%         dw_labels = arrayfun(@(x) dw.observed_categories{x}.label, dw.classes, 'UniformOutput', false);
%         avcats = [];
%         for iLabel = 1:numel(labels)
%             avcats(end+1) = find(strcmp(dw_labels, labels{iLabel}));
%         end
%         % avcats = getObject(obj, objects, 'audiovisual_category');
%         undef_cats = find(avcats == 1);
%         if ~isempty(undef_cats)
%             if numel(undef_cats) == 1
%                 focus = objects(undef_cats);
%             else
%                 missing_hist = arrayfun(@(x) sum(getObject(obj, x, 'missing_hist')), undef_cats);
%                 tm_idx = arrayfun(@(x) numel(getObject(obj, x, 'tmIdx')), undef_cats);
%                 if numel(unique(tm_idx)) == 1
%                     if find(obj.focus(end) == objects)
%                         focus = obj.focus(end);
%                     else
%                         focus = objects(randi(numel(objects)));
%                     end
%                 else
%                     [~, pos] = min(tm_idx);
%                     focus = obj.focus(pos);
%                 end
%             end
%         else
%             if find(obj.focus(end) == objects)
%                 focus = obj.focus(end);
%             else
%                 focus = objects(randi(numel(objects)));
%             end
%         end
%     end
% end

% === Check if the considered object is present in the environment
function bool = isPresent (obj, idx)
    present_objects = getEnvironment(obj, 0, 'present_objects');
    if find(idx == present_objects)
        bool = true;
    else
        bool = false;
    end 
end


% === Get Objects of Max Weight (DWmod computation)
function request = getMaxWeightObject (obj)
    % obj_weights = getObject(obj, 'all', 'weight');
    present_objects = getLastHypothesis(obj, 'ODKS', 'id_object');
    present_objects = present_objects(present_objects > 0)'; % === indique le no de l'objet, pas de la source
    % env = getEnvironment(obj, 0);
    % present_objects = env.present_objects';
    % if obj.htm.RIR.environments{end}.behavior == obj.htm.RIR.nb_environments
        obj_weights = getObject(obj, present_objects, 'weight');
        [val, pos] = max(obj_weights);
        max_weight_obj = find(obj_weights == val);
        if numel(max_weight_obj) > 1
            tsteps = getObject(obj, present_objects(max_weight_obj), 'start_emission');
            [~, pos] = max(tsteps);
            request = present_objects(max_weight_obj(pos));

            % if numel(obj.focus) <= 9
            %     idx = numel(obj.focus)-1;
            % else
            %     idx = 9;
            % end

            % % tmp = find(present_objects(max_weight_obj) == obj.focus(end));
            % search_focus = find(present_objects(max_weight_obj) == obj.focus(end));

            % if ~isempty(search_focus)
            %     idx = present_objects(max_weight_obj(search_focus));
            % end

            % % if obj.focus(end) ~= 0 && ~isempty(search_focus) && any(obj.focus(end-idx:end) ~= search_focus)
            % if obj.focus(end) ~= 0 && ~isempty(search_focus) && any(obj.focus(end-idx:end) ~= idx)
            %     % if any(obj.focus(end-idx:end) ~= search_focus)
            %     tt = present_objects(max_weight_obj);
            %     request = tt(search_focus);

            % % if ~isempty(tmp)
            % %     request = tt(tmp);
            %     % obj.tmp(obj.htm.iStep) = 1;
            % else
            %     max_weight_obj(search_focus) = [];
            %     t_obj_start = getObject(obj, present_objects(max_weight_obj), 'start_emission');
            %     [~, pos] = max(t_obj_start);
            %     request = present_objects(max_weight_obj(pos));
            %     % t_obj_stop = getObject(obj, present_objects(max_weight_obj), 'stop_emission');
            %     % iStep = obj.htm.iStep;
            %     % tsteps = getObject(obj, present_objects(max_weight_obj), 'tsteps');
            %     % [~, pos] = min(tsteps);
            %     % request = max_weight_obj(pos);
            %     % tmp = present_objects(max_weight_obj);
            %     % request = tmp(pos);
            % end
        else
            request = present_objects(pos);
        end
        request = int32(request);
        if val <= 0.9
            request = 0;
        end
    % else
    %     env = getEnvironment(obj.htm, 0);
    %     dw = obj.htm.RIR.environments{env.behavior}.DW;
    %     categories = dw.observed_categories(env.classes);
    %     objects = getObject(obj.htm, env.present_objects);
    %     if numel(env.present_objects) == 1
    %         objects = {objects};
    %     end
    %     cong_vec = zeros(1, numel(objects));
    %     idx = zeros(1, numel(objects));
    %     for iObject = 1:numel(env.present_objects)
    %         for iCat = 1:numel(categories)
    %             if strcmp(categories{iCat}.label, objects{iObject}.label)
    %                 idx(iObject) = iCat;
    %                 cong_vec(iObject) = categories{iCat}.congruence;
    %             end
    %         end
    %     end
        
    %     [val, pos] = max(cong_vec);
    %     max_weight_obj = find(cong_vec == val);
    %     if numel(cong_vec) > 1
    %         tsteps = getObject(obj, max_weight_obj, 'tsteps');
    %         [~, pos] = min(tsteps);
    %         request = max_weight_obj(pos);
    %     else
    %         request = env.present_objects(pos);
    %     end
    %     % if getObject(obj, request, 'weight') < 0
    %     %     request = 0;
    %     % end
    % end
end

function computeNaiveSHM (obj)
    iStep = obj.htm.iStep;
    if iStep > 2
        id_object = getHypothesis(obj, 'ODKS', 'id_object');
        obj_update = id_object(:, iStep-2)-id_object(:, iStep-1);
        tmp = find(obj_update < 0);
        if ~isempty(tmp)
            tt = id_object(tmp, end);
        else
            tt = tmp;
        end
    else
        tt = [];
    end

    if ~isempty(tt)
        sources = getObject(obj, tt, 'source');
        obj.naive_focus(sources) = obj.naive_focus(sources) + 1;
    end

end

% ===================== %
% === METHODS [END] === %
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %
end