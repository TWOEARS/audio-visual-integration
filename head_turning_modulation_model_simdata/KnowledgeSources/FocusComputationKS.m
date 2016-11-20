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

    hypotheses = [];
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

    % % === USEFUL??? === %
    % if ~obj.isPresent(focus)
%     if ~getObject(obj, focus, 'presence')
%         focus = 0;
%     end
    % % === USEFUL??? === %

    keySet = {'focus', 'focus_origin'};
    valueSet = {focus, focus_origin};

    obj.hypotheses{end+1} = containers.Map(keySet, valueSet);

    obj.focus_origin(end+1) = focus_origin;
    obj.focus(end+1) = focus;
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
            %if getObject(obj, current_object, 'presence')
                requests = getObject(obj, current_object, 'requests');
                if requests.check || ~isPerformant(obj.htm, current_object, 'Object')
                    focus(iSource) = current_object;
                    % === TO BE CHANGED === %
                    % obj.RIR.getEnv().objects{current_object}.requests.checked = true;
                    % === TO BE CHANGED === %
                % elseif requests.checked
                %     %focus = current_object;
                %     focus = 0;
                else
                    focus(iSource) = 0;
                end
            %else
            %    focus(iSource) = 0;
            %end
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
        % avcats = getObject(obj, objects, 'audiovisual_category');
        uv = unique(cell2mat(arrayfun(@(x) obj.focus(obj.focus==x), objects', 'UniformOutput', false)));
        if isempty(uv)
            focus = 0;
        else
            n  = histc(obj.focus, uv);
            [v, p] = min(n);
            if sum(n == v) > 1
                focus = obj.focus(end);
            end
            focus = objects(p);
        end
    end
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
    obj_weights = getObject(obj, 'all', 'weight');
    [val, pos] = max(obj_weights);
    max_weight_obj = find(obj_weights == val);
    if numel(max_weight_obj) > 1
        tsteps = getObject(obj, max_weight_obj, 'tsteps');
        [~, pos] = min(tsteps);
        request = max_weight_obj(pos);
    else
        request = pos;
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