% 'FocusComputationKS' class
% This knowledge source compute the object to be focused on.
% It is based on two distinct algorithms:
% 1. The Dynamic Weighting module
% 2. The Multimodal Fusion & Inference module
% Author: Benjamin Cohen-Lhyver
% Date: 01.06.16
% Rev. 2.0

classdef FocusComputationKS < AbstractKS
% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public)
    htm; 
    RIR;

    bbs;

    focus_origin = []; % to be renamed as "focus_type"
    focus = [];
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS (BEG) === %
% ===================== %
methods

% === Constructor [BEG] === %
function obj = FocusComputationKS (bbs, htm)
    obj = obj@AbstractKS();
    obj.bbs = bbs;
    obj.invocationMaxFrequency_Hz = inf;

    obj.htm = htm;
    obj.RIR = htm.RIR;
end
% === Constructor [END] === %

% === Other Methods === %
% --- Execute functionality
function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)
    RIR = obj.RIR; % --- RobotInternalRepresentaion

    if RIR.nb_objects == 0
        focusedObject = containers.Map({'focus', 'focus_origin'},...
                                       {focus, focus_origin});
        obj.blackboard.addData('FocusedObject', 0,...
                               false, obj.trigger.tmIdx);
        notify(obj, 'KsFiredEvent');
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

    % === USEFUL??? === %
    % if ~obj.isPresent(focus)
    %     focus = 0;
    % end
    % === USEFUL??? === %

    obj.focus_origin(end+1) = focus_origin;
    obj.focus(end+1) = focus;

    % --- List the focus
    keySet = {'focus', 'focus_origin'};
    valueSet = {obj.focus, obj.focus_origin};
    focusedObject = containers.Map({'focus', 'focus_origin'},...
                                   {focus, focus_origin});
    obj.blackboard.addData('FocusedObject', focusedObject,...
                            false, obj.trigger.tmIdx);
    notify(obj, 'KsFiredEvent');
end

% === Compute focused object thanks to the DYNAMIC WEIGHTING module (DWmod) algorithm
function focus = computeDWmodFocus (obj)
    focus = obj.getMaxWeightObject();
    object = getObject(obj, focus);
    if object.weight <= 0 || ~getObject(obj, focus, 'presence')
        focus = 0;
    % elseif ~isPerformant(obj.htm.RIR.getEnv(), object.cat)
    %     focus = -1;
    end
end

% === Compute focused object thanks to the MULTIMODAL FUSION and INFERENCE module (MFImod) algorithm
function focus = computeMFIFocus (obj)
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
        % elseif requests.checked
        %     %focus = current_object;
        %     focus = 0;
        else
            focus = 0;
        end
    else
        focus = 0;
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
        tsteps = getObject(obj.RIR, max_weight_obj, 'tsteps');
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