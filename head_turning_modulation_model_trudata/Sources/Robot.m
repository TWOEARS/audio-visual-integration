classdef Robot < handle

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
    robotController ;

    AzimuthMin ;
    AzimuthMax ;

    % block size used in the SSR
    BlockSize ;
    % the sample rate used in the SSR
    SampleRate ;
    finished ;
end
properties (SetAccess = private, GetAccess = private)
    field_of_view = 30 ;
    bass ;
    basc2 ;
    bufferSize ;

end


% --------------- %
% --- METHODS --- %
% -             - %
methods
% === Constructor === %
function obj = Robot ()
    obj.robotController = RobotController(obj) ;
    obj.BlockSize = 2048;
    obj.SampleRate = 44100;

    % prepare values for blackboard connection
    obj.AzimuthMin = -180;
    obj.AzimuthMax = 180;
    obj.finished = false;

    % --- At initialization: create a new environment
    obj.addEnvironment() ;

end

% === Other methods
function finished = isFinished (obj)
    finished = obj.finished ;
end


function addEnvironment (obj)
    obj.environments{end+1} = PerceivedEnvironment() ;
end

% === Add a new object to the environment
function addObject (obj, input_vector, theta, d)
    if obj.nb_objects > 0
        obj.getLastObj().presence = false ;
    end
    obj.getEnv().addObject(input_vector, theta, d) ;
    obj.nb_objects = obj.nb_objects + 1 ;
end

% === Update the label of the IDX object with a new INPUT_VECTOR
function updateLabel (obj, input_vector)
    obj.getEnv().updateLabel(input_vector) ;
end

function updateAngle (obj, theta)
    obj.getEnv().objects{end}.updateAngle(theta) ;
end

% === Compute focus
function computeFocus (obj)
    if isempty(obj.getEnv().objects)
        obj.focus_hist = [obj.focus_hist, 0] ;
        return ;
    end
    
    % --- DWmod-based focus computing
    dwmod_focus = obj.computeDWmodFocus() ;

    % --- MFI-based focus computing
    mfi_focus = obj.computeMFIFocus() ;

    % --- Comparison of the two results
    if mfi_focus == 0
    	focus = dwmod_focus ;
    	obj.focus_origin(end+1) = 0 ;
    else
    	focus = mfi_focus ;
    	obj.focus_origin(end+1) = -1 ;
    end
    % focus = mfi_focus ;

    if obj.isPresent(focus)
        obj.focus = focus ;
    end

    obj.computeSHM() ;

    % --- List the focus
    obj.focus_hist = [obj.focus_hist, obj.focus] ;
end

function focus = computeDWmodFocus (obj)
	focus = obj.getMaxWeightObject() ;
    if obj.getObj(focus, 'weight') < 0.98
    	focus = 0 ;
    end
end

function focus = computeMFIFocus (obj)
	focus = 0 ;
	if obj.getLastObj('presence')
		if obj.getLastObj().requests.check
			focus = numel(obj.getEnv().objects) ;
		end
	end
end

function computeSHM (obj)
    if obj.focus ~= obj.previous_focus
        obj.shm = obj.shm + 1 ;
        obj.previous_focus = obj.focus ;
    end
end

% === Get Objects of Max Weight
function request = getMaxWeightObject (obj)
    obj_weights = cell2mat(obj.getAllObj('weight')) ;
    [val, pos] = max(obj_weights) ;
    max_weight_obj = find(obj_weights == val) ;
    if numel(max_weight_obj) > 1
        tsteps = cell2mat(obj.getObj(max_weight_obj, 'tsteps')) ;
        [~, pos] = min(tsteps) ;
        request = max_weight_obj(pos) ;
    else
        request = pos ;
    end
    request = int32(request) ;
end

% === Update every objects
function updateObjects (obj, tmIdx)
    if obj.nb_objects > 0
        obj.getEnv().updateObjects(tmIdx) ;
    end
    obj.nb_objects = numel(obj.getEnv().objects) ;
    obj.computeFocus() ;
end

function bool = isPresent (obj, idx)
    if find(idx == obj.getEnv().present_objects)
        bool = true ;
    else
        bool = false ;
    end 
end

function theta = motorOrder (obj)
    if ~isempty(obj.getEnv().objects) && obj.focus ~= 0
        theta = obj.getObj(obj.focus, 'theta') ;
    else
        theta = 0 ;
    end
end


function initializeBass (obj, bass, basc2)
    obj.bass = bass ;
    obj.basc2 = basc2 ;
    
    hardware = 'hw:1,0' ;
    sampleRate = 44100 ;
    nFramesPerChunk = 2205 ;
    nChunksOnPort = 20 * 0.2;

    obj.bufferSize = nFramesPerChunk * nChunksOnPort ;
    
    % obj.bass.Acquire('-a', hardware, sampleRate, nFramesPerChunk, nChunksOnPort) ;
    
end


function orientation = getCurrentHeadOrientation (obj)
    orientation = obj.robotController.head.phi + obj.robotController.phi ;
end


% Get the auralized signal as perceived by the Kemar head. this
% function is required for communication with the blackboard, to
% feed the AFE.

% inputs:
%       dT:             the interval for which a signal chunk has
%                       to be acquired from the SSR
% outputs:
%       signal:         the acquired signal
%       trueIncrement:  ?
function [signal, trueIncrement] = getSignal(obj, dT)

    getBlocks = obj.basc2.GetBlocks(0);

    if (~strcmp(getBlocks.status,'done'))
        error(getBlocks.exception.ex);
    end

    newAudio = obj.basc2.newAudio();

    if ( newAudio.newAudio.lostFrames > 0 )
        disp(strcat('Lost data : ',int2str(newAudio.newAudio.lostFrames)));
    end
    
    % Append Audio
    left = cell2mat( newAudio.newAudio.left ) ;
    right = cell2mat(newAudio.newAudio.right) ;
    signal = [left, right] ;
    trueIncrement = numel(left) / obj.SampleRate ;
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



