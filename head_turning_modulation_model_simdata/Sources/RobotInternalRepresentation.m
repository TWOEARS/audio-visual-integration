classdef RobotInternalRepresentation < handle

% --------------- %
% --- SUMMARY --- %
% -             - %

% -             - %
% --- SUMMARY --- %
% --------------- %



% --- Properties --- %
properties (SetAccess = public, GetAccess = public)
    environments   = cell(0) ; % list of environments
    focus          = 0 ; % current focused object by the robot
    previous_focus = 0 ;
    focus_hist     = [] ;
    shm            = 0 ;
    nb_objects     = 0 ;
    focus_origin = [] ;
    MFI;
    theta_hist = [];
    dist_hist = [];
    data = [];
    head_position = 0;
    head_position_hist = [];
    MotorOrderKS;
end


% --------------- %
% --- METHODS --- %
% -             - %
methods
% === Constructor === %
function obj = RobotInternalRepresentation (htm)
    obj.MFI = htm.MFI;
    obj.MotorOrderKS = htm.MotorOrderKS();
    obj.addEnvironment();
end

% === Other methods
function addEnvironment (obj)
    obj.environments{end+1} = PerceivedEnvironment(obj);
end

% === Add a new object to the environment
function addObject (obj)
    obj.getEnv().addObject();
    obj.nb_objects = obj.nb_objects + 1;
end

% === Update the label of the last object with a new INPUT_VECTOR
function updateObject (obj)
    obj.getEnv().updateObjectData(obj.data(:, end)   ,...
                                  obj.theta_hist(end),...
                                  obj.dist_hist(end)  ...
                                 );
end

function updateData (obj, data, theta, d)
    obj.data(:, end+1) = data;
    obj.theta_hist(end+1) = theta;
    obj.dist_hist(end+1) = d;
end

% === Compute focus
% function computeFocus (obj)
%     % global ISTEP ;
%     if isempty(obj.getEnv().objects)
%         obj.focus_hist = [obj.focus_hist, 0] ;
%         return ;
%     end
    
%     % --- DWmod-based focus computing
%     % dwmod_focus = obj.computeDWmodFocus();

%     % --- MFI-based focus computing
%     mfi_focus = obj.computeMFIFocus();

%     % --- Comparison of the two results
%     % if mfi_focus == 0
%     % 	focus = dwmod_focus ;
%     % 	obj.focus_origin(end+1) = 0 ;
%     % else
%     % 	focus = mfi_focus ;
%     % 	obj.focus_origin(end+1) = -1 ;
%     % end
%     focus = mfi_focus;

%     if obj.isPresent(focus)
%         obj.focus = focus;
%     end

%     obj.computeSHM();

%     % --- List the focus
%     obj.focus_hist = [obj.focus_hist, obj.focus];
% end

function focus = computeDWmodFocus (obj)
	focus = obj.getMaxWeightObject();
    if getObject(obj, focus, 'weight') < 0.98
    	focus = 0;
    end
end

function focus = computeMFIFocus (obj)
	focus = 0;
	if getObject(obj, 0, 'presence')
        requests = getObject(obj, 0, 'requests');
		if requests.check
			focus = numel(obj.getEnv().objects);
		end
	end
end

function computeSHM (obj)
    if obj.focus ~= obj.previous_focus
        obj.shm = obj.shm + 1;
        obj.previous_focus = obj.focus;
    end
end

% === Get Objects of Max Weight
function request = getMaxWeightObject (obj)
    obj_weights = getObject(obj, 'all', 'weight');
    [val, pos] = max(obj_weights);
    max_weight_obj = find(obj_weights == val);
    if numel(max_weight_obj) > 1
        % tsteps = cell2mat(obj.getObj(max_weight_obj, 'tsteps')) ;
        tsteps = getObject(obj, max_weight_obj, 'tsteps');
        [~, pos] = min(tsteps);
        request = max_weight_obj(pos);
    else
        request = pos;
    end
    request = int32(request);
end

% === Update every objects
function updateObjects (obj, tmIdx)
    if obj.nb_objects > 0
        obj.getEnv().updateObjects(tmIdx);
    end
    %obj.nb_objects = numel(obj.getEnv().objects) ;
    % obj.computeFocus();
end

function bool = isPresent (obj, idx)
    if find(idx == obj.getEnv().present_objects)
        bool = true;
    else
        bool = false;
    end 
end

function theta = motorOrder (obj)
    if ~isempty(obj.getEnv().objects) && obj.focus ~= 0
        theta = getObject(obj, obj.focus, 'theta');
    else
        theta = 0;
    end
end

% --------------------- %
% --- GET FUNCTIONS --- %
% -                   - %
function request = getAllClasses (obj, varargin)
    nb_classes = numel(obj.getEnv().AVClasses) ;
    request = cell(nb_classes, 1) ;
    for iClass = 1:nb_classes
        if nargin > 1
            request{iClass} = obj.getEnv().classes{iClass}.(varargin{1}) ;
        else
            request{iClass} = obj.getEnv().classes{iClass} ;
        end
    end
end

function [request, obj_number] = getObjectsOfClass (obj, idx, varargin)
    if ischar(idx)
        idx(idx == ' ') = '_' ;
        target = find(strcmp(idx, obj.getEnv().AVClasses)) ;
    else
        target = idx ;
    end
    objects = find(target == cell2mat(obj.getAllObj('cat'))) ;
    request = cell(numel(objects), 1) ;
    for iObj = 1:numel(objects)
        if nargin > 2
            request{iObj} = obj.getObj(objects(iObj)).(varargin{1}) ;
        else
            request{iObj} = obj.getObj(objects(iObj)) ;
        end
    end
    if nargout == 2
        obj_number = objects ;
    end
end

% === Get Environment information
function output = getEnv (obj, varargin)
    if nargin > 1
        fnames = fieldnames(obj.environments{end}) ;
        target = find(strcmp(fnames, varargin{1})) ;
        if nargin > 2
            output = obj.environments{end}.(fnames{target}) ;
            output = output{varargin{2}} ;
        else
            output = obj.environments{end}.(fnames{target}) ;
        end
    else
        output = obj.environments{end} ;
    end

    if isempty(output)
        output
    end
end

% function request = getPresentObj (obj, varargin) 
%     if nargin == 1
%         request = arrayfun(@(x) obj.getEnv().objects{x},...
%                            obj.getEnv().present_objects,...
%                            'UniformOutput', false) ;
%     else
%         request = arrayfun(@(x) obj.getEnv().objects{x}.(varargin{1}),...
%                            obj.getEnv().present_objects,...
%                            'UniformOutput', false) ;
%     end
% end

function request = getFocus (obj)
    request = obj.focus_hist ;
end
% -                   - %
% --- GET FUNCTIONS --- %
% --------------------- %


end
% -             - %
% --- METHODS --- %
% --------------- %
end



