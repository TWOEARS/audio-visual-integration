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

classdef HTMFocusKS < AbstractKS
% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public)
    htm; 
    RIR;

    bbs;
 
    current_time = 0;
    mfiFocus = 0;
    dwFOcus = 0;

end


properties (SetAccess = public, GetAccess = public)
    %energy_thr = 0.01;
    %smoothing_theta = 5;
    cpt = 0;
    last_movement = 0;
    theta_hist = [];

    statistics = [];

    simulation_status = [];
end

methods

function obj = HTMFocusKS (bbs, htm)
    obj = obj@AbstractKS();
    obj.bbs = bbs;
    obj.invocationMaxFrequency_Hz = inf;

    obj.htm = htm;
    
    obj.RIR = htm.RIR;

end


%% execute functionality
function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)
    RIR = obj.RIR;

    if isempty(RIR.getEnv().objects)
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
    if mfi_focus == 0
        focus = dwmod_focus ;
        focus_origin = 0;
    else
        focus = mfi_focus ;
        focus_origin = -1;
    end
    % focus = mfi_focus ;

    if ~obj.isPresent(focus)
        focus = 0;
    end

    % --- List the focus
    %obj.focus_hist = [obj.focus_hist, obj.focus];

    focusedObject = containers.Map({'focus', 'focus_origin'},...
                                   {focus, focus_origin});

    obj.blackboard.addData('FocusedObject', focusedObject   ,...
                            false         , obj.trigger.tmIdx...
                          );
    notify(obj, 'KsFiredEvent');

end

function focus = computeDWmodFocus (obj)
    focus = obj.getMaxWeightObject();
    if getObject(obj.RIR, focus, 'weight') < 0.98
        focus = 0;
    end
end

function focus = computeMFIFocus (obj)
    focus = 0;
    if getObject(obj.RIR, 0, 'presence')
        request = getObject(obj.RIR, 0, 'requests');
        if request.check
            focus = numel(obj.RIR.getEnv().objects);
        end
    end
end


function bool = isPresent (obj, idx)
    if find(idx == obj.RIR.getEnv().present_objects)
        bool = true;
    else
        bool = false;
    end 
end


% === Get Objects of Max Weight
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

end