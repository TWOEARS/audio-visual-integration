% 'PerceivedObject' class
% This class is part of the HeadTurningModulationKS
% Author: Benjamin Cohen-Lhyver
% Date: 01.11.15
% Rev. 2.0

classdef PerceivedObject < handle

% --- Properties --- %
properties (SetAccess = public, GetAccess = public)
	label = 'none_none';
    audio_label = 'none';
    visual_label = 'none';

    theta = 0;
    theta_hist = [];
    % id 			= ''	   ; % hex

    presence = true;

    tsteps = 0;

    weight = 0;

    d = 0 ;
    dist_hist = [];

    cat    = 0 ; % int
    cat_hist = [] ;

end
properties (SetAccess = public, GetAccess = public)
    focus = 0;
    occ_thr = 5;
    % data = [];
    % data_tmp = [];
    % mean_data = [];
    cpt = 0;
    requests = struct('inference'   , false,...
    				  'check'       , false,...
    				  'verification', false,...
    				  'label' 		, ''   ,...
    				  'missing'     , true  ...
    				 );
    tmIdx = [];
end

% --- Methods --- %
methods
% --- Constructor (BEG) --- %
function obj = PerceivedObject (data, theta, d)
	obj.theta = theta;
	obj.d = d;
	obj.tsteps = 1;
	obj.presence = true;
	obj.cpt = obj.cpt + 1;
	obj.addData(data);
end
% --- Constructor (END) --- %

function addData (obj, data)
	% obj.data_tmp = [obj.data_tmp, data];
	% obj.data = obj.data_tmp;
	obj.missingModality(data);
	obj.requestInference();
	% obj.weightData() ;
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
end

% function weightData (obj)
% 	s = size(obj.data_tmp, 2) ;
% 	obj.data = zeros(size(obj.data_tmp)) ;
% 	ws = ones(1, s) ;
	
% 	m = min([s, obj.smoothing_tsteps]) ;

% 	ws(1:m) = exp(1:m)/exp(obj.smoothing_tsteps) ;

% 	% if s > obj.smoothing_tsteps
% 	% 	m = min([s-obj.smoothing_tsteps, obj.smoothing_tsteps]) ;
% 	% 	ws(end-m+1:end) = exp(m :-1: 1)/exp(obj.smoothing_tsteps) ;
% 	% end

% 	obj.data = bsxfun(@times, obj.data_tmp(1:obj.nb_alabels, :), ws) ;
% 	obj.data = [obj.data ; obj.data_tmp(obj.nb_alabels+1:end, :)] ;
% end


function setLabel (obj, label)
	obj.label = label;
	obj.visual_label = label(1:strfind(label, '_')-1);
	obj.audio_label = label(strfind(label, '_')+1:end);
end

function updateCatHist (obj, value)
	t = obj.tsteps - 1;
	obj.cat_hist(end-t:end) = ones(1, t+1)*value;
end

function updateData (obj, data, theta, d)
	obj.addData(data);
	obj.theta_hist(end+1) = theta;
	obj.theta = theta;
	obj.dist_hist(end+1) = d;
	obj.d = d;
end

function updateTime (obj, t)
	if obj.presence
		obj.tmIdx(end+1) = t;
	end
end

function updateAngle (obj)

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

% function request = getBestData (obj)
% 	s = size(obj.data, 2) ;
% 	if s < obj.smoothing_tsteps
% 		request = obj.data(:, end) ;
% 	elseif s >= obj.smoothing_tsteps && s < 2*obj.smoothing_tsteps
% 		% good_visual_data = obj.getGoodVisualData(obj.smoothing_tsteps:s) ;
% 		good_visual_data = obj.getGoodVisualData() ;
% 		request = mean(obj.data(1:getInfo('nb_audio_labels'), obj.smoothing_tsteps:end), 2) ;
% 		request = [request ; mean(good_visual_data, 2)] ;
% 	else
% 		% good_visual_data = obj.getGoodVisualData(obj.smoothing_tsteps:s-obj.smoothing_tsteps) ;
% 		good_visual_data = obj.getGoodVisualData() ;
% 		request = mean(obj.data(1:getInfo('nb_audio_labels'), obj.smoothing_tsteps:end-obj.smoothing_tsteps+1), 2) ;
% 		request = [request ; mean(good_visual_data, 2)] ;
% 	end
% end

% function request = getGoodVisualData (obj)
% 	na = getInfo('nb_audio_labels');
% 	nv = getInfo('nb_visual_labels');
	
% 	cpt = find(sum(obj.data(na+1:end, :)) > 0.1) ;

% 	if isempty(cpt)
% 		request = zeros(nv, 1) ;
% 	else
% 		request = obj.data(na+1:end, cpt) ;
% 	end
% end

function requestedData = getData (obj, nb_samples)
	if nargin == 1
		requestedData = obj.data ;
	% elseif numel(nb_samples) == 2
	% 	requestedData = obj.data(:, [nb_samples(1):nb_samples(2)]) ;
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

% function requestedData = getInference (obj)
% 	requestedData = obj.inference(end-1:end) ;
% end
% -                   - %
% --- GET FUNCTIONS --- %
% --------------------- %

end

end