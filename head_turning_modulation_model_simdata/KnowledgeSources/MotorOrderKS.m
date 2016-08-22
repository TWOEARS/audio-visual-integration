classdef MotorOrderKS < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    head_position = 0;
    head_position_hist = [];
    htm;

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
function obj = MotorOrderKS (htm)
	% obj.RIR = htm.RIR;
	obj.htm = htm;
end

function moveHead (obj)
	RIR = obj.htm.RIR;
    % --- If no sound -> make the head turn to 0° (resting state)
    % focus = RIR.focus;
    focus = htm.HTMFocusKS.focus;

    if obj.isFocusedObjectPresent() && focus ~= 0 % --- move the head
        % theta = obj.motorOrder();
        theta = getObject(RIR, RIR.focus, 'theta');
        % obj.RIR.updateAngle(0);
        setObject(RIR, 0, 'theta', 0);
        %RIR.getLastObj().theta = 0;
    else                                          % --- go back to resting state (O°)
        theta = -obj.head_position;
    end
    obj.head_position = mod(theta+obj.head_position, 360) ;
    obj.head_position_hist(end+1) = obj.head_position;
end

function bool = isFocusedObjectPresent (obj)
	RIR = obj.htm.RIR;
    if isempty(RIR.getEnv().present_objects)
        bool = false ;
    elseif find(RIR.focus == RIR.getEnv().present_objects)
        bool = true ;
    else
        bool = false ;
    end
end

end

end