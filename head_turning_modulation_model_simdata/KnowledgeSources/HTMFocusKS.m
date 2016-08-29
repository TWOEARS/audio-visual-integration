% 'HeadTurningModulationKS' class
% This knowledge source triggers head movements based on two modules:
% 1. MultimodalFusionAndInference module;
% (reference to come)
% 2. Dynamic Weighing module 
% (reference: Benjamin Cohen-Lhyver, Modulating the Auditory Turn-to Reflex on the Basis of Multimodal Feedback Loops:
% the Dynamic Weighting Model, in IEEE-ROBIO 2015)
% Author: Benjamin Cohen-Lhyver
% Date: 01.06.16
% Rev. 2.0

classdef HTMFocusKS < handle
% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public)
    htm; 
    RIR;
 
    % current_time = 0;
    % mfiFocus = 0;
    % dwFocus = 0;

    focused_object = 0;
    focus_origin = 0; % to be renamed as "focus_type"
    previous_focus = 0;
    focus_hist = [];

end

% ===================== %
% === METHODS (BEG) === %
% ===================== %
methods

% === Constructor === %
function obj = HTMFocusKS (htm)
    obj.htm = htm;
    obj.RIR = htm.RIR;
end


% === Other Methods === %
function computeFocus (obj)
    RIR = obj.RIR; % --- RobotInternalRepresentaion

    if isempty(RIR.getEnv().objects)
        obj.focus_hist = [obj.focus_hist, 0];
        obj.focus_origin = [obj.focus_origin, 0];
        return;
    end
    
    % --- DWmod-based focus computing
    dwmod_focus = obj.computeDWmodFocus();

    % --- MFI-based focus computing
    mfi_focus = obj.computeMFIFocus();

    % --- Comparison of the two results
    if mfi_focus == 0
        focus = dwmod_focus ;
        focus_origin = 1;
    else
        focus = mfi_focus ;
        focus_origin = -1;
    end
    % focus = mfi_focus ;

    if ~obj.isPresent(focus)
        focus = 0;
    end

    obj.focused_object = focus;
    obj.focus_origin = [obj.focus_origin, focus_origin];

    obj.focus_hist = [obj.focus_hist, obj.focused_object];

end

% === Compute focused object thanks to the DYNAMIC WEIGHTING module (DWmod) algorithm
function focus = computeDWmodFocus (obj)
    focus = obj.getMaxWeightObject();
    if getObject(obj.RIR, focus, 'weight') < 0.98
        focus = 0;
    end
end

% === Compute focused object thanks to the MULTIMODAL FUSION and INFERENCE module (MFImod) algorithm
function focus = computeMFIFocus (obj)
    focus = 0;
    if getObject(obj.RIR, 0, 'presence')
        request = getObject(obj.RIR, 0, 'requests');
        if request.check
            focus = numel(obj.RIR.getEnv().objects);
        end
    end
end

function computeSHM (obj)
    if obj.focused_object ~= obj.previous_focus
        obj.shm = obj.shm + 1;
        obj.previous_focus = obj.focus;
    end
end

% === Check if the considered object is present in the environment
function bool = isPresent (obj, idx)
    if find(idx == obj.RIR.getEnv().present_objects)
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


end

% ===================== %
% === Methods (END) === %
% ===================== %



end