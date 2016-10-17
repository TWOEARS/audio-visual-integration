% 'PerceivedObject' class
% This class is part of the HeadTurningModulationKS
% Author: Benjamin Cohen-Lhyver
% Date: 01.02.16
% Rev. 2.0

classdef PerceivedObject < handle


% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
	label = 'none_none';
    audio_label = 'none';
    visual_label = 'none';

    audio_theta = 0;
    visual_theta = 0;
    theta = 0;
    theta_hist = [];
    % id 			= ''	   ; % hex

    presence = true;

    tsteps = 0;

    weight = 0;

    d = 0;
    dist_hist = [];

    cat    = 0; % int
    cat_hist = [];

    missing_hist = [];

end
properties (SetAccess = public, GetAccess = public)
    focus = 0;
    occ_thr = 5;
    cpt = 0;
    requests = struct('inference'   , false,...
    				  'check'       , false,...
    				  'verification', false,...
    				  'label' 		, ''   ,...
    				  'missing'     , true ,...
    				  'checked'     , false ...
    				 );
    tmIdx = [];
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods
% --- Constructor [BEG] --- %
function obj = PerceivedObject (data, theta)
	obj.theta = theta;
	obj.theta_hist(end+1) = theta;
	% obj.d = d;
	obj.tsteps = 1;
	obj.presence = true;
	obj.cpt = obj.cpt + 1;
	obj.addData(data);
end
% --- Constructor [END] --- %

function addData (obj, data)
	% obj.data_tmp = [obj.data_tmp, data];
	% obj.data = obj.data_tmp;
	obj.missingModality(data);
	obj.requestInference();
end

function missingModality (obj, data)
	if sum(data(1:getInfo('nb_audio_labels'), end)) < 0.2 ||...
	   sum(data(getInfo('nb_audio_labels')+1:end, end)) < 0.2
		obj.requests.missing = true;
	else
		obj.requests.missing = false;
	end
end

function requestInference (obj)
	% --- If not enough data
	if obj.cpt <= getInfo('smoothing')
		obj.requests.inference = false;
	else
		% --- If missing modality
		if obj.requests.missing
			obj.requests.inference = true;
		% --- If every modality
		else
			obj.requests.inference = false;
			if obj.requests.check
				obj.requests.verification = true;
			else
				obj.requests.verification = false;
			end
		end
	end
	obj.missing_hist(end+1) = obj.requests.missing;
end

function setLabel (obj, label)
	obj.label = label;
	obj.visual_label = label(1:strfind(label, '_')-1);
	obj.audio_label = label(strfind(label, '_')+1:end);
end

function updateCatHist (obj, value)
	t = obj.tsteps - 1;
	obj.cat_hist(end-t:end) = ones(1, t+1)*value;
end

function updateData (obj, data, theta)
	obj.addData(data);
	obj.theta_hist(end+1) = theta;
	obj.theta = theta;
	% obj.dist_hist(end+1) = d;
	% obj.d = d;
end

function updateTime (obj, t)
	if obj.presence
		obj.tmIdx(end+1) = t;
	end
end

function updateAngle (obj, theta)
	if isstr(theta)
		if strcmp(theta, 'init')
			theta = obj.theta_hist(1);
		end
	else
		if theta <= 5
			theta = 0;
		end
	end
	obj.theta = theta;
	obj.theta_hist(end+1) = theta;
end

function updateObj (obj)
	obj.cpt = obj.cpt + 1;
	if isempty(obj.cat_hist)
		obj.cat_hist = obj.cat;
		obj.tsteps = 1;
		return;
	end

	if obj.cat == obj.cat_hist(end)
		obj.tsteps = obj.tsteps + 1;
	else
		obj.tsteps = 1;
	end
	% --- Concatenation of the last value of category
	obj.cat_hist(end+1) = obj.cat;
end

% --------------------- %
% --- GET FUNCTIONS --- %
% -                   - %
function requestedData = getMeanData (obj, nb_samples)
	if nargin == 1
		nb_samples = obj.occ_thr ;
	end
	if nb_samples > size(obj.data, 2)
		m = size(obj.data, 2) ;
	else
		m = min([nb_samples, size(obj.data, 2)]) ;
	end
	% --- Mean on the last 5 samples
	requestedData = mean(obj.data(:, end-m+1:end), 2) ;
	% request = mean(obj.data(:, obj.smoothing_tsteps:end-obj.smoothing_tsteps)) ;
end

function requestedData = getData (obj, nb_samples)
	if nargin == 1
		requestedData = obj.data ;
	else
		requestedData = obj.data(:, nb_samples) ;
	end
end

function requestedData = getVisualData (obj, nb_samples)
	na = getInfo('nb_audio_labels');
	if nargin == 1
		requestedData = obj.data(na+1:end, :) ;
	elseif ischar(nb_samples) && strcmp(nb_samples, 'end')
		requestedData = obj.data(na+1:end, end) ;	
	else
		requestedData = obj.data(na+1:end, nb_samples) ;
	end
end

function requestedData = getAudioData (obj, nb_samples)
	na = getInfo('nb_audio_labels');
	if nargin == 1
		requestedData = obj.data(1:na, :) ;
	elseif ischar(nb_samples) && strcmp(nb_samples, 'end')
		requestedData = obj.data(1:na, end) ;
	else
		requestedData = obj.data(1:na, nb_samples) ;
	end
end

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