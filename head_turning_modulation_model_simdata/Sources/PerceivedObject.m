% PerceivedObject class
% This class is part of the HeadTurningModulationKS
% Author: Benjamin Cohen-Lhyver
% Date: 01.02.16
% Rev. 2.0

classdef PerceivedObject < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public,
            GetAccess = public)
	audiovisual_category = 1; % int
	audio_label = 'none';
    cat_hist = [];
    cpt = 0;
    d = 0;
    dist_hist = [];
	label = 'none_none';
    missing_hist = [];
    presence = true;    
    requests = struct('inference'   , false,...
    				  'check'       , false,...
    				  'verification', false,...
    				  'label' 		, ''   ,...
    				  'missing'     , true ,...
    				  'checked'     , false ...
    				 );
    source = 0;
    theta = [];
    theta_v = [];
    tmIdx = [];
    tsteps = 0;
    visual_label = 'none';
    weight = 0;
    weight_hist = 0;
    idx_data = 1;
    start_emission = 0;
    stop_emission = 0;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods
% === Constructor [BEG] === %
function obj = PerceivedObject (data, theta, theta_v, source)
	obj.theta(end+1) = theta;
	if isempty(theta_v)
		theta_v = -1;
	end
	obj.theta_v(end+1) = theta_v;
	obj.source = source;
	% obj.d = d;
	obj.tsteps = 1;
	obj.presence = true;
	obj.cpt = obj.cpt + 1;
	obj.isDataMissing(data);
end
% === Constructor [END] === %

function isDataMissing (obj, data)
	if getInfo('modules') == 1
		obj.requests.missing = false;
	else
		if sum(data(1:getInfo('nb_audio_labels'), end)) < 0.2 ||...
		   sum(data(getInfo('nb_audio_labels')+1:end, end)) < 0.2
			obj.requests.missing = true;
		else
			obj.requests.missing = false;
		end
	end
	% --- If not enough data
	if obj.cpt < getInfo('smoothing')
		obj.requests.inference = false;
	else
		if obj.requests.missing % --- If missing modality
			obj.requests.inference = true;
			obj.requests.checked = false;
		else 					% --- If every modality
			obj.requests.inference = false;
			if obj.requests.check
				obj.requests.verification = true;
				obj.requests.checked = false;
			else
				obj.requests.verification = false;
			end
		end
	end
	obj.missing_hist(end+1) = obj.requests.missing;
end

function setLabel (obj, label, search)
	obj.label = label;
	obj.visual_label = label(1:strfind(label, '_')-1);
	obj.audio_label = label(strfind(label, '_')+1:end);
	obj.audiovisual_category = search;
end

function updateData (obj, data, theta, theta_v)
	% obj.addData(data);
	obj.isDataMissing(data);
	obj.theta(end+1) = theta;
	obj.theta_v(end+1) = theta_v;
end

function updateTime (obj, t)
	if obj.presence
		obj.tmIdx(end+1) = t;
	end
end

function setPresence (obj, bool)
	if obj.presence == true && bool == false
		obj.requests.missing = false;
		obj.requests.inference = false;
	end
	obj.presence = bool;
end

function updateAngle (obj, theta)
	if isstr(theta)
		if strcmp(theta, 'init')
			theta = obj.theta(1);
		end
	else
		if theta <= 5
			theta = 0;
		else
			theta = theta;
		end
	end
	obj.theta(end+1) = theta;
end

function initializeRequests (obj)
    obj.requests = struct('inference'   , false,...
				  'check'       , false,...
				  'verification', false,...
				  'label' 		, ''   ,...
				  'missing'     , true ,...
				  'checked'     , false ...
				 );
end

function updateObj (obj)
	obj.cpt = obj.cpt + 1;
	if isempty(obj.cat_hist)
		obj.cat_hist = obj.audiovisual_category;
		obj.tsteps = 1;
		return;
	end

	if obj.audiovisual_category == obj.cat_hist(end)
		obj.tsteps = obj.tsteps + 1;
	else
		obj.tsteps = 1;
	end
	% --- Concatenation of the last value of audiovisual_category
	obj.cat_hist(end+1) = obj.audiovisual_category;
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end