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

    theta = [];
    theta_v = [];
    % theta_hist = [];
    % id 			= ''	   ; % hex

    presence = true;

    tsteps = 0;

    weight = 0;

    d = 0;
    dist_hist = [];

    audiovisual_category = 0 ; % int
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
% === Constructor [BEG] === %
function obj = PerceivedObject (data, theta, theta_v)
	obj.theta(end+1) = theta;
	obj.theta_v(end+1) = theta_v;
	% obj.d = d;
	obj.tsteps = 1;
	obj.presence = true;
	obj.cpt = obj.cpt+1;
	obj.addData(data) ;
end
% === Constructor [END] === %

function addData (obj, data)
	obj.missingModality(data);
	obj.requestInference();
end

% === TO BE CHANGED: take into account visual information instead of classification output! === %
function missingModality (obj, data)
	if sum(data(1:getInfo('nb_audio_labels'), end)) < 0.2 ||...
	   sum(data(getInfo('nb_audio_labels')+1:end, end)) < 0.2
		obj.requests.missing = true;
	else
		obj.requests.missing = false;
	end
end
% === TO BE CHANGED: take into account visual information instead of classification output! === %

function requestInference (obj)
	% --- If not enough data
	if obj.cpt <= getInfo('smoothing')
		obj.requests.inference = false;
	else
		if obj.requests.missing % --- If missing modality
			obj.requests.inference = true;
		else 				    % --- If every modality
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

function updateData (obj, data, theta, theta_v)
	obj.addData(data);
	obj.theta(end+1) = theta;
    obj.theta_v(end+1) = theta_v;
end

function updateTime (obj, t)
    if t == 0
        return;
    end
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
	% --- Concatenation of the last value of category
	obj.cat_hist(end+1) = obj.audiovisual_category;
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

function request = getBestData (obj)
	s = size(obj.data, 2) ;
	a = getInfo('nb_audio_labels');
	v = getInfo('nb_visual_labels');

	if s <= obj.smoothing_tsteps
		if ~isempty(obj.data)
			request = obj.data(:, end) ;
		else
			request = [] ;
		end
	elseif s >= obj.smoothing_tsteps && s < 2*obj.smoothing_tsteps
		% good_visual_data = obj.getGoodVisualData(obj.smoothing_tsteps:s) ;
		good_visual_data = obj.getGoodVisualData(1:s) ;
		request = mean(obj.data(1:a, obj.smoothing_tsteps:end), 2) ;
		request = [request ; mean(good_visual_data, 2)] ;
	else
		% good_visual_data = obj.getGoodVisualData(obj.smoothing_tsteps:s-obj.smoothing_tsteps) ;
		good_visual_data = obj.getGoodVisualData(1:s) ;
		request = mean(obj.data(1:a, obj.smoothing_tsteps:end-obj.smoothing_tsteps+1), 2) ;
		request = [request ; mean(good_visual_data, 2)] ;
	end
end

function request = getGoodVisualData (obj, idx)
	a = getInfo('nb_audio_labels');
	v = getInfo('nb_visual_labels');
	cpt = [] ;
	for iStep = idx
		if sum(obj.data(a+1:end, iStep)) > 0.1
			cpt = [cpt, iStep] ;
		end
	end
	if isempty(cpt)
		request = zeros(v, 1) ;
	else
		request = obj.data(a+1:end, cpt) ;
	end
end

function requestedData = getData (obj, nb_samples)
	if nargin == 1
		requestedData = obj.data ;
	% elseif numel(nb_samples) == 2
	% 	requestedData = obj.data(:, [nb_samples(1):nb_samples(2)]) ;
	else
		requestedData = obj.data(:, nb_samples) ;
	end
end

% function requestedData = getVisualData (obj, nb_samples)
% 	if nargin == 1
% 		requestedData = obj.data(obj.nb_audio+1:end, :) ;
% 	elseif ischar(nb_samples) && strcmp(nb_samples, 'end')
% 		requestedData = obj.data(obj.nb_audio+1:end, end) ;	
% 	else
% 		requestedData = obj.data(obj.nb_audio+1:end, nb_samples) ;
% 	end
% end

% function requestedData = getAudioData (obj, nb_samples)
% 	if nargin == 1
% 		requestedData = obj.data(1:obj.nb_audio, :) ;
% 	elseif ischar(nb_samples) && strcmp(nb_samples, 'end')
% 		requestedData = obj.data(1:obj.nb_audio, end) ;
% 	else
% 		requestedData = obj.data(1:obj.nb_audio, nb_samples) ;
% 	end
% end

function requestedData = getInference (obj)
	requestedData = obj.inference(end-1:end) ;
end
% -                   - %
% --- GET FUNCTIONS --- %
% --------------------- %

end

end