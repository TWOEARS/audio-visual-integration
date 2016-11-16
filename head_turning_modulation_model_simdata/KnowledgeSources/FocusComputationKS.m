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

    % focused_object = 0;
    focus_origin = []; % to be renamed as "focus_type"
    % previous_focus = 0;
    focus = [];
end

% ===================== %
% === METHODS (BEG) === %
% ===================== %
methods

% === Constructor === %
function obj = FocusComputationKS (htm)
    obj.htm = htm;
    obj.RIR = htm.RIR;
end


% === Other Methods === %
function execute (obj)
    RIR = obj.RIR; % --- RobotInternalRepresentaion

    if RIR.nb_objects == 0
        obj.focus(end+1) = 0;
        obj.focus_origin(end+1) = 0;
        return;
    end
    
    % --- DWmod-based focus computing
    dwmod_focus = obj.computeDWmodFocus();

    % --- MFI-based focus computing
    mfi_focus = obj.computeMFIFocus();

    % --- Comparison of the two results
    if mfi_focus == 0 && dwmod_focus > 0       % --- DWmod takes the lead
        focus = dwmod_focus;
        focus_origin = 1;
    elseif mfi_focus == 0 && dwmod_focus == 0  % --- No focused object
        focus = obj.focus(end);
        % focus = 0;
        focus_origin = 0;
    elseif mfi_focus == 0 && dwmod_focus == -1 % --- DWmod focus but AV category not performant
        focus = obj.focus(end);
        focus_origin = 0;
    else                                       % --- MFImod takes the lead over the DWmod
        focus = mfi_focus;
        focus_origin = -1;
    end

    % % === USEFUL??? === %
    % if ~obj.isPresent(focus)
    if ~getObject(obj, focus, 'presence')
        focus = 0;
    end
    % % === USEFUL??? === %

    obj.focus_origin(end+1) = focus_origin;
    obj.focus(end+1) = focus;
end

% === Compute focused object thanks to the DYNAMIC WEIGHTING module (DWmod) algorithm
function focus = computeDWmodFocus (obj)
    focus = obj.getMaxWeightObject();
    object = getObject(obj, focus);
    env = getEnvironment(obj, 0);
    if object.weight < 0
        focus = 0;
    % elseif ~isPerformant(env, object.audiovisual_category)
    %     focus = -1;
    end
end

% === Compute focused object thanks to the MULTIMODAL FUSION and INFERENCE module (MFImod) algorithm
function focus = computeMFIFocus (obj)
    focus = 0;
    % current_object = obj.htm.ODKS.id_object(end);
    current_object = getLastHypothesis(obj.htm, 'ODKS', 'id_object');
    if current_object == 0
        focus = 0;
        return;
    end

    if getObject(obj, current_object, 'presence')
        requests = getObject(obj, current_object, 'requests');
        if requests.check 
            focus = current_object;
            % === TO BE CHANGED === %
            % obj.RIR.getEnv().objects{current_object}.requests.checked = true;
            % === TO BE CHANGED === %
        elseif requests.checked
            focus = current_object;
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
    RIR = obj.RIR;
    obj_weights = getObject(RIR, 'all', 'weight');
    [val, pos] = max(obj_weights);
    max_weight_obj = find(obj_weights == val);
    if numel(max_weight_obj) > 1
        tsteps = getObject(RIR, max_weight_obj, 'tsteps');
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