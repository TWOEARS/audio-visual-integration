classdef MotorOrderKS < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    head_position = 0;
    head_position_hist = [];
    htm;
    HTMFocusKS;
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
function obj = MotorOrderKS (htm, htmFocusKS)
	% obj.RIR = htm.RIR;
	obj.htm = htm;
    obj.HTMFocusKS = htmFocusKS;
end
% ========================= %
% === CONSTRUCTOR [END] === %
% ========================= %

function moveHead (obj)
	RIR = obj.htm.RIR;
    % --- If no sound -> make the head turn to 0° (resting state)
    % focus = RIR.focus;
    focus = obj.HTMFocusKS.focused_object;

    if obj.isFocusedObjectPresent() && focus ~= 0 % --- move the head
        % theta = obj.motorOrder();
        theta = getObject(RIR, focus, 'theta');
        % obj.RIR.updateAngle(0);
        setObject(RIR, 0, 'theta', 0);            % --- go back to resting position (O°)
        %RIR.getLastObj().theta = 0;
    else                                          % --- go back to resting state (O°)
        theta = -obj.head_position;
    end
    obj.head_position = mod(theta+obj.head_position, 360) ;
    obj.head_position_hist(end+1) = obj.head_position;
end

function bool = isFocusedObjectPresent (obj)
	RIR = obj.htm.RIR;
    focus = obj.HTMFocusKS.focused_object;

    if isempty(RIR.getEnv().present_objects)
        bool = false;
    % elseif find(RIR.focus == RIR.getEnv().present_objects)
    elseif find(focus == RIR.getEnv().present_objects)
        bool = true;
    else
        bool = false;
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