% PerceivedObject class
% This class is part of the HeadTurningModulationKS
% Author: Benjamin Cohen-Lhyver
% Date: 01.02.16
% Rev. 2.0

classdef PerceivedObject < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
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
	obj.theta_v(end+1) = theta_v;
	obj.source = source;
	% obj.d = d;
	obj.tsteps = 1;
	obj.presence = true;
	obj.cpt = obj.cpt + 1;
	obj.isDataMissing(data);
end
% === Constructor [END] === %

% === TO BE CHANGED: take into account visual information instead of classification output! === %
% function missingModality (obj, data)
% 	if sum(data(1:getInfo('nb_audio_labels'), end)) < 0.2 ||...
% 	   sum(data(getInfo('nb_audio_labels')+1:end, end)) < 0.2
% 		obj.requests.missing = true;
% 	else
% 		obj.requests.missing = false;
% 	end
% end
% === TO BE CHANGED: take into account visual information instead of classification output! === %

function isDataMissing (obj, data)
	if sum(data(1:getInfo('nb_audio_labels'), end)) < 0.2 ||...
	   sum(data(getInfo('nb_audio_labels')+1:end, end)) < 0.2
		obj.requests.missing = true;
	else
		obj.requests.missing = false;
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
				% obj.requests.checked = true;
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

% function updateCatHist (obj, value)
% 	t = obj.tsteps - 1;
% 	obj.cat_hist(end-t:end) = ones(1, t+1)*value;
% end

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

function updateAngle (obj, theta)
	if isstr(theta)
		% === TO BE CHANGED: the first results of locationKS are not good === %
		if strcmp(theta, 'init')
			theta = obj.theta(1);
		end
		% === TO BE CHANGED: the first results of locationKS are not good === %
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

% % --------------------- %
% % --- GET FUNCTIONS --- %
% % -                   - %
% function requestedData = getMeanData (obj, nb_samples)
% 	if nargin == 1
% 		nb_samples = obj.occ_thr ;
% 	end
% 	if nb_samples > size(obj.data, 2)
% 		m = size(obj.data, 2) ;
% 	else
% 		m = min([nb_samples, size(obj.data, 2)]) ;
% 	end
% 	% --- Mean on the last 5 samples
% 	requestedData = mean(obj.data(:, end-m+1:end), 2) ;
% 	% request = mean(obj.data(:, obj.smoothing_tsteps:end-obj.smoothing_tsteps)) ;
% end

% function requestedData = getData (obj, nb_samples)
% 	if nargin == 1
% 		requestedData = obj.data ;
% 	else
% 		requestedData = obj.data(:, nb_samples) ;
% 	end
% end

% function requestedData = getVisualData (obj, nb_samples)
% 	na = getInfo('nb_audio_labels');
% 	if nargin == 1
% 		requestedData = obj.data(na+1:end, :) ;
% 	elseif ischar(nb_samples) && strcmp(nb_samples, 'end')
% 		requestedData = obj.data(na+1:end, end) ;	
% 	else
% 		requestedData = obj.data(na+1:end, nb_samples) ;
% 	end
% end

% function requestedData = getAudioData (obj, nb_samples)
% 	na = getInfo('nb_audio_labels');
% 	if nargin == 1
% 		requestedData = obj.data(1:na, :) ;
% 	elseif ischar(nb_samples) && strcmp(nb_samples, 'end')
% 		requestedData = obj.data(1:na, end) ;
% 	else
% 		requestedData = obj.data(1:na, nb_samples) ;
% 	end
% end

% -                   - %
% --- GET FUNCTIONS --- %
% --------------------- %


% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end