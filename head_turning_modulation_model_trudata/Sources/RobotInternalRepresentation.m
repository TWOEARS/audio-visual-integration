% 'RobotInternalRepresentation' class
% This class is part of the HeadTurningModulationKS
% Author: Benjamin Cohen-Lhyver
% Date: 01.02.16
% Rev. 2.0

classdef RobotInternalRepresentation < handle

% --------------- %
% --- SUMMARY --- %
% -             - %

% -             - %
% --- SUMMARY --- %
% --------------- %



% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    environments = cell(0); % list of environments
    nb_objects = 0;
    MFI;
    MSOM;
    htm;
    data = [];
    theta_hist = [];
    theta_v_hist = [];
    head_position = 0;
    position = [0, 0];
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods
% === Constructor [BEG] === %
function obj = RobotInternalRepresentation (htm)
    obj.htm = htm;
    obj.MFI = htm.MFI;
    obj.MSOM = htm.MSOM;
    obj.addEnvironment();
end
% === Constructor [END] === %

% === Other methods
function finished = isFinished (obj)
    finished = obj.finished;
end

function addEnvironment (obj)
    obj.environments{end+1} = PerceivedEnvironment(obj) ;
end

% === Add a new object to the environment
function addObject (obj)
    obj.getEnv().addObject();
    obj.nb_objects = obj.nb_objects + 1;
end

% === Update
function updateObject (obj)
    obj.getEnv().updateObjectData(obj.data(:, end),...
                                  obj.theta_hist(end));
end

function updateData (obj)
    obj.data(:, end+1) = obj.htm.data(:, end);
    theta = getLocalisationOutput();
    obj.theta_hist(end+1) = theta;
    % obj.dist_hist(end+1) = d;
end

% === Update every objects
function updateObjects (obj)
    tmIdx = obj.htm.current_time;
    if obj.nb_objects > 0
        obj.getEnv().updateObjects(tmIdx);
    end
end

% =================================== %
% ========== GET FUNCTIONS ========== %
% =================================== %

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
% === Get Object information
function request = getObj (obj, idx, varargin)
    if isempty(obj.getEnv().objects)
    	request = false ;
        return ;
    end
    if nargin == 2
        if numel(idx) > 1
            request = arrayfun(@(x) obj.getEnv().objects{x},...
                               idx,...
                               'UniformOutput', false) ;
        else
            request = obj.getEnv().objects{idx} ;
        end
    elseif nargin == 3
        if numel(idx) > 1
            request = arrayfun(@(x) obj.getEnv().objects{x}.(varargin{1}),...
                                   idx,...
                                   'UniformOutput', false) ;
        else
            request = obj.getEnv().objects{idx}.(varargin{1}) ;
        end
    end
end
function request = getAllObj (obj, varargin)
    if isempty(obj.getEnv().objects)
        request = [] ;
        return ;
    end
    if nargin == 1
        request = arrayfun(@(x) obj.getEnv().objects{x},...
                           1:numel(obj.getEnv().objects),...
                           'UniformOutput', false) ;
    else
        request = arrayfun(@(x) obj.getEnv().objects{x}.(varargin{1}),...
                           1:numel(obj.getEnv().objects),...
                           'UniformOutput', false) ;
    end
end
function request = getLastObj (obj, varargin)
    if isempty(obj.getEnv().objects)
        request = [] ;
        return ;
    end
    if nargin == 1
        request = obj.getEnv().objects{end} ;
    else
        request = obj.getEnv().objects{end}.(varargin{1}) ;
    end
end
function request = getPresentObj (obj, varargin) 
    if nargin == 1
        request = arrayfun(@(x) obj.getEnv().objects{x},...
                           obj.getEnv().present_objects,...
                           'UniformOutput', false) ;
    else
        request = arrayfun(@(x) obj.getEnv().objects{x}.(varargin{1}),...
                           obj.getEnv().present_objects,...
                           'UniformOutput', false) ;
    end
end

function request = getMFI (obj, varargin)
    if nargin == 1
        request = obj.getEnv().MFI ;
    else
        request = obj.getEnv().MFI.(varargin{1}) ;
    end
end

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



