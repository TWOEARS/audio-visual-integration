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
end
properties (SetAccess = private, GetAccess = private)
    field_of_view = 30 ;
end


% --------------- %
% --- METHODS --- %
% -             - %
methods
% === Constructor === %
function obj = Robot ()
    obj.addEnvironment() ;
end

% === Other methods
function addEnvironment (obj)
    obj.environments{end+1} = PerceivedEnvironment() ;
end

% === Add a new object to the environment
function addObject (obj, input_vector, theta, d)
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

function plotFocus (obj)

	AVdata = getappdata(0, 'AVdata') ;

	correctAVPairs = {'person_speech', 'door_knock', 'siren_alert'} ;

	figure ;

	subplot(1, 10, 1:8)
	hold on ;

	nb_tsteps = numel(obj.focus_hist) ;

	xvec = linspace(0, 60.004, nb_tsteps) ;
	naive = zeros(1, numel(obj.focus_hist)) ;

	colors = {'black', 'red', 'green'} ;
	audio_labels = obj.getCF().audio_labels ;

	tstop = 0 ;
	for iObj = 1:size(AVdata.t_idx, 1)
		tstart = AVdata.t_idx(iObj, 1) ;
		duration = AVdata.t_idx(iObj, 2) - tstart ;

		audio_color = find(strcmp(AVdata.t_idx(iObj, 3), audio_labels)) ;
		% audio_color = colors{audio_color} ;
		audio_color = colors{AVdata.t_idx(iObj, 3)} ;

		if find(iObj == AVdata.wrong)
			visual_color = 'red' ;
			wrong = true ;
		else
			visual_color = 'green' ;
			wrong = false ;
		end
		if wrong
			if find(strcmp(obj.getObj(iObj, 'label'), correctAVPairs))
    			correct = true ;
    		else
    			correct = false ;
    		end
    	end
        
        rectangle('Position', [tstart iObj-0.25 duration 0.5],...
                  'FaceColor', [1 1 1],...
                  'LineWidth', 6) ;
        rectangle('Position', [tstart iObj duration 0.25],...
                  'FaceColor', audio_color,...
                  'EdgeColor', audio_color) ;
        rectangle('Position', [tstart iObj-0.25 duration 0.25],...
                  'FaceColor', visual_color,...
                  'EdgeColor', visual_color) ;

        search_stop = find(tstop <= xvec, 1, 'first') ;
        search_start = find(tstart >= xvec, 1, 'last') ;
        search_duration = find(tstart+duration <= xvec, 1, 'first') ;

        nvalues = numel([search_stop:search_start]) ;
        nduration = numel([search_start:search_duration]) ;
        naive(search_stop:search_start) = ones(1, nvalues)*(iObj-1) ;

        naive(search_start:search_duration) = ones(1, nduration)*iObj ;
		
		if wrong && correct
			text(tstart, iObj+0.25, '*', 'FontSize', 52, 'Color', 'cyan') ;
		elseif wrong && ~correct
			text(tstart, iObj+0.25, '*', 'FontSize', 52, 'Color', 'blue') ;
		end
        tstop = tstart+duration ;
    end
    
    % search_stop = find(tstop <= xvec, 1, 'first') ;
    nduration = numel([search_duration:nb_tsteps]) ;
    naive(search_duration:end) = ones(1, nduration)*iObj ;

    rectangle('Position', [2 20-1 7 2],...
              'FaceColor', [1 1 1],...
              'LineWidth', 4) ;
    rectangle('Position', [2 20-1 7 1],...
              'FaceColor', [0 0 0]+0.45,...
              'EdgeColor', [0 0 0]+0.45) ;
    rectangle('Position', [2 20 7 1],...
              'FaceColor', [0 0 0]+0.90,...
              'EdgeColor', [0 0 0]+0.90) ;

    text(3, 20.50, 'Audio label', 'FontSize', 16) ;
    text(3, 19.40, 'Visual label', 'FontSize', 16) ;

    plot(xvec, obj.focus_hist, 'LineWidth', 4) ;
    plot(xvec, [zeros(1, 21), obj.focus_origin], 'r', 'LineWidth', 3) ;

    plot(xvec, naive, 'k--', 'LineWidth', 2) ;

    legend({'Objects focused',...
    		'DWmod (0) or MFImod (-1) based computation',...
    		'Purely reflexive robot'},...
    		'FontSize', 16,...
    		'Location', 'northwest') ;

    set(gca, 'XLim', [0, 61],...
    		 'XTickLabel', [0 :10: 61],...
    		 'YLim', [-2, obj.nb_objects+2]) ;
    xlabel('Time of simulation (sec)', 'FontSize', 16) ;
    ylabel('Object number', 'FontSize', 16) ;
    title('Focused objects based on DWmod and MFImod computations', 'FontSize', 20) ;

    hold off ;

    % --- Hist

    proba = cell2mat(obj.getEnv().getCategories('proba')) ;
    proba = proba(2:end) ;
    perf = cell2mat(obj.getEnv().getCategories('perf')) ;
    perf = perf(2:end) ;
    cat_labels = obj.getEnv().getCategories('label') ;
    cat_labels = cat_labels(2:end) ;

    cat_labels = arrayfun(@(x) [cat_labels{x}(1:find(cat_labels{x} == '_')-1), ' ', cat_labels{x}(find(cat_labels{x} == '_')+1:end)],...
    					  1:numel(cat_labels),...
    					  'UniformOutput', false) ;

    subplot(1, 10, 9:10)
    hold on ;
    bar(proba,'FaceColor', 'none',...
    		  'EdgeColor', 'red',...
    	      'LineStyle', '-',...
    	      'LineWidth', 3) ;
    bar(perf,'FaceColor', 'none',...
    		 'EdgeColor', 'blue',...
    		 'LineStyle', ':',...
    		 'LineWidth', 2) ;
    set(gca, 'XTick', [1:numel(cat_labels)],...
    		 'XTickLabel', cat_labels,...
    		 'XTickLabelRotation', 45,...
    		 'YLim', [0, 1],...
    		 'FontSize', 12) ;

    legend({'proba', 'perf'}, 'FontSize', 16) ;

end


end
% -             - %
% --- METHODS --- %
% --------------- %
end



