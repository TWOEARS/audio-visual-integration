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
    RIR;
    
    nb_sources = 0;

    focus_origin = []; % to be renamed as "focus_type"
    focus = [];
    ratio = [];

    % hypotheses = [];
end

% ===================== %
% === METHODS (BEG) === %
% ===================== %
methods

% === Constructor [BEG] === %
function obj = FocusComputationKS (htm)
    obj.htm = htm;
    obj.RIR = htm.RIR;
    obj.nb_sources = getInfo('nb_sources');
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
        dwmod_focus = obj.computeDWmodFocus();
        % dwmod_focus = 0;

        % --- MFI-based focus computing
        mfi_focus = obj.computeMFImodFocus();
        
        % --- Comparison of the two results
        if mfi_focus == 0 && dwmod_focus > 0       % --- DWmod takes the lead
            focus = dwmod_focus;
            focus_origin = 1;
        elseif mfi_focus == 0 && dwmod_focus == 0  % --- No focused object
            % if obj.focus(end) ~= 0 && getObject(obj, obj.focus(end), 'audiovisual_category') ~= 1
                % if ~isPerformant(obj, obj.focus(end)) && getObject(obj, obj.focus(end), 'presence')
                %     % focus = obj.focus(end);
                %     % focus = 0;
                %     focus = obj.focus(end);
                %     focus_origin = obj.focus_origin(end);
                % else
                    focus = 0;
                    focus_origin = 0;
                % end
            % else
            %     focus = 0;
            % end
        elseif mfi_focus == 0 && dwmod_focus == -1 % --- DWmod focus but AV category not performant
            % focus = obj.focus(end);
            focus = 0;
            focus_origin = 0;
        else                                       % --- MFImod takes the lead over the DWmod
            focus = mfi_focus;
            focus_origin = -1;
        end
    end

    if focus == 0
        objects = hyp(hyp ~= 0);
        perfs = arrayfun(@(x) isPerformant(obj, objects(x), 'Object'), 1:numel(objects));
        %p = perfs(perfs == 0);
        if any(perfs == 0)
            p = find(perfs == 0);
            idx = randi(numel(p));
            focus = objects(p(idx));
        end
    end

    % % === USEFUL??? === %
    % if ~obj.isPresent(focus)
%     if ~getObject(obj, focus, 'presence')
%         focus = 0;
%     end
    % % === USEFUL??? === %

%     keySet = {'focus', 'focus_origin'};
%     valueSet = {focus, focus_origin};
% 
%     obj.hypotheses{end+1} = containers.Map(keySet, valueSet);

    obj.focus_origin(end+1) = focus_origin;
    obj.focus(end+1) = focus;
    obj.ratio = cumsum(obj.focus_origin)./(1:numel(obj.focus_origin));
end

% === Compute focused object thanks to the DYNAMIC WEIGHTING module (DWmod) algorithm
function focus = computeDWmodFocus (obj)
    %focus = zeros(obj.nb_sources, 1);
    focus = obj.getMaxWeightObject();
    object = getObject(obj, focus);
    %env = getEnvironment(obj, 0);
    if object.weight <= 0 || ~object.presence
        focus = 0;
    % elseif ~isPerformant(env, object.audiovisual_category)
    %     focus = -1;
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
                focus(iSource) = current_object;
            else
                focus(iSource) = 0;
            end
        end
    end
    focus = obj.solveConflicts(focus);
end

function focus = solveConflicts (obj, focuses)
    % objects = find(focuses);
    objects = focuses(focuses ~= 0);
    if isempty(objects)
        focus = 0;
    elseif numel(objects) == 1
        focus = objects;
    else
        avcats = getObject(obj, objects, 'audiovisual_category');
        undef_cats = find(avcats == 1);
        if ~isempty(undef_cats)
            if numel(undef_cats) == 1
                focus = objects(undef_cats);
            else
                missing_hist = arrayfun(@(x) sum(getObject(obj, x, 'missing_hist')), undef_cats);
                tm_idx = arrayfun(@(x) numel(getObject(obj, x, 'tmIdx')), undef_cats);
                if numel(unique(tm_idx)) == 1
                    if find(obj.focus(end) == objects)
                        focus = obj.focus(end);
                    else
                        focus = objects(randi(numel(objects)));
                    end
                else
                    [~, pos] = min(tm_idx);
                    focus = obj.focus(pos);
                end
            end
        else
            if find(obj.focus(end) == objects)
                focus = obj.focus(end);
            else
                focus = objects(randi(numel(objects)));
                % focus = 0;
            end
        end
    end
            
        % avcats = getObject(obj, objects, 'audiovisual_category');
        %uv = unique(cell2mat(arrayfun(@(x) obj.focus(obj.focus==x), objects', 'UniformOutput', false)));
        %uv = cell2mat(arrayfun(@(x) sum(obj.focus==x), objects', 'UniformOutput', false));
        % --- Looking at how many time steps 'objects' had missing information
        missing_hist = arrayfun(@(x) sum(getObject(obj, x, 'missing_hist')), objects');
        %if isempty(uv)
        %if all(uv == 0)
        % --- If every 'objects' had the same number of time steps missing information
%         if numel(unique(missing_hist)) == 1
%             pos = find(obj.focus(end) == objects);
%             % --- If last focus is present in 'objects' -> keep focusing it
%             if ~isempty(pos)
%                 focus = objects(pos);
%             % --- If not, take a random object
%             else
%                 focus = objects(randi(numel(objects)));
%             end
%         % --- If some objects had more missing time steps
%         else
%             % --- Find the one with the max time steps
%             [v, p] = max(missing_hist);
%             if objects(p) == obj.focus(end)
%                 focus = objects(p);
%             else
%                 s = sum(obj.focus(end-4:end) == objects(p));
%                 if s == 5
%                     focus = objects(p);
%                 else
%                     focus = obj.focus(end);
%                 end
%             end
%                 
            % --- To avoid deadlock situations, impose a 5 tsteps delay
            %tmp = arrayfun(@(x) sum(getObject(obj, x, 'missing_hist')), objects');
%             pos = find(obj.focus(end) == objects);
%             if ~isempty(pos)
%                 if abs(missing_hist(pos) - missing_hist(p)) >= 5
%                     focus = objects(p);
%                 else
%                     focus = objects(pos);
%                 end
%             else
%                 focus = objects(p);
%             end
            % --- introducing a 5 time steps smoothing delay
%             ff = missing_hist - v;
%             t1 = find(ff < 0);
%             if isempty(t1)
%                 focus = objects(p);
%             else
%                 t2 = find(ff > -5);
%                 %if isempty(t2)
%                 if ~isempty(t2)
%                     ii = intersect(t1, t2);
%                     if isempty(ii)
%                         % check tmp(2)
%                         [~, p] = max(ff(t1));
%                         focus = objects(p);
%                     else
%                         focus = objects(p);
%                     end
%                 end
%             end
%             %n  = histc(obj.focus, uv);
%             %[v, p] = min(n);
%             [v, p] = min(uv);
%             %if sum(n == v) > 1
%             if sum(uv == v) > 1
%                 [v2, m] = max(uv);
%                 ff = find(uv-v2 < -5);
%                 if isempty(ff)
%                     focus = objects(m);
%                 else
%                     [~, p] = min(uv(ff));
%                     focus = objects(p);
%                 end
%                 %focus = obj.focus(end);
%                 % focus = obj.focus(p(1));
%             else
%                 focus = objects(p);
%             end
%         end
%     end
end

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
    present_objects = present_objects(present_objects > 0)';
    % env = getEnvironment(obj, 0);
    % present_objects = env.present_objects';
    obj_weights = getObject(obj, present_objects, 'weight');
    [val, pos] = max(obj_weights);
    max_weight_obj = find(obj_weights == val);
    if numel(max_weight_obj) > 1
        tsteps = getObject(obj, max_weight_obj, 'tsteps');
        [~, pos] = min(tsteps);
        request = max_weight_obj(pos);
    else
        request = present_objects(pos);
    end
    request = int32(request);
end

% ===================== %
% === METHODS [END] === %
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %
end