% 'PerceivedEnvironment' class
% This class is part of the HeadTurningModulationKS
% It implements the Environment the robot is currently exploring.
% This class enables it to gather:
% 		1. the congruence distribution of the AV categories it has created
% 		2. the audiovisual objects it has already observed in it.
% Author: Benjamin Cohen-Lhyver
% Date: 01.02.16
% Rev. 2.0

classdef PerceivedEnvironment < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    present_objects = [] 	 ; % objects present in the environment
    objects = cell(0); % all detected objects
    htm;
    RIR;					% --- Robot Internal Representation
    MFI;					% --- Multimodal Fusion & Inference module
    MSOM;					% --- Multimodal Self Organizing Map
    DW;						% --- Dynamic Weighting module
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === Constructor [BEG] === %
function obj = PerceivedEnvironment (RIR)
	obj.RIR  = RIR; 	   % --- Robot Internal Representation
	obj.htm  = RIR.htm;    % --- Head Turning Modulation
	obj.MFI  = RIR.MFI;    % --- Multimodal Fusion & Inference module
	obj.MSOM = RIR.MSOM;   % --- Multimodal SelfOrganizing Map
	obj.DW   = obj.htm.DW; % --- Dynamic Weighting module
end
% === Constructor [END] === %

% --- Other methods --- %
function addObject (obj)
	theta_a = getLocalisationOutput(obj.htm);
	theta_v = obj.htm.blackboard.getLastData('visualLocationHypotheses').data;
	theta_v = theta_v('theta');
	% data = getClassifiersOutput(obj.htm);
	data = getClassifiersOutput(obj.htm);

	% --- Create a new PERCEIVEDOBJECT object
    obj.objects{end+1} = PerceivedObject(data,...
    									 theta_a,...
    									 theta_v);
	obj.objects{end}.updateTime(obj.htm.iStep);
    obj.addInput();
end

function addInput (obj)
	hyp = obj.htm.blackboard.getLastData('objectDetectionHypotheses').data;
	iObj = hyp.id_object;
	% --- No data missing
	if ~obj.objects{iObj}.requests.missing
		% --- Train nets
        data = retrieveObservedData(obj, iObj, 'best');
		obj.MFI.newInput(data);
	end
end

function updateObjectData (obj)
	hyp = obj.htm.blackboard.getLastData('objectDetectionHypotheses').data;
	iObj = hyp.id_object;

	data = getClassifiersOutput(obj.htm);

	theta_a = getLocalisationOutput(obj.htm);
	theta_v = obj.htm.blackboard.getLastData('visualLocationHypotheses').data;
	theta_v = theta_v('theta');

	if abs(theta_v - obj.objects{iObj}.theta_v(end)) > 15
		theta_v = obj.objects{iObj}.theta_v(end);
	end
	obj.objects{iObj}.updateData(data,...
								 theta_a,...
								 theta_v);
	obj.objects{iObj}.updateTime(obj.htm.iStep);
	% obj.objects{iObj}.presence = true;

	obj.addInput();
end

function checkInference (obj)
	for iObj = obj.present_objects'
		[inference, missing, check, verification, label] = obj.getObjectRequests(iObj);
		if inference && missing % --- If an inference has been requested & data is missing
			if check % --- If a CHECK has been requested (-> motor order)
				% --- Continue to turn the head to the object
			else % --- If a CHECK has not been yet requested: trigger a motor order?
				[AVClass, search] = obj.simulateAVInference(iObj);
				% if ~strcmp(AVClass, 'none_none')
					if isPerformant(obj, search) % --- If the category has been correctly inferred in the past: CHECK not needed
						obj.preventVerification(iObj, search, AVClass);
					else % --- If the cat. hasn't been well infered in the past -> CHECK needed
						obj.requestVerification(iObj, AVClass);
						obj.DW.updateInferenceCpt(search);
					end
				% end
			end
		% --- If no inference requested (AV data available) but a verification is requested
		% --- ADD A VERIFICATION WITH NO CHECK in order to verify the inference in the case we have AV thanks to DWmod
		elseif verification
			[AVClass, search] = obj.simulateAVInference(iObj);
			if strcmp(AVClass, label) && ~strcmp(AVClass, 'none_none') % --- If inferred AV is the same as observed AV
				obj.preventVerification(iObj, search, AVClass);
				obj.DW.updateGoodInferenceCpt(search);
				obj.objects{iObj}.requests.checked = true;
			else % --- If infered AV is NOT the same as observed AV
                obj.objects{iObj}.requests.label = AVClass;
				% --- Make the network learn with n more iterations
				obj.highTrainingPhase();
				% obj.objects{iObj}.requests.verification = true;
			end
		elseif ~missing % All data available
			[AVClass, search] = obj.simulateAVInference(iObj);
			obj.objects{iObj}.setLabel(AVClass, search);
			obj.objects{iObj}.requests.check = false;
		end
	end
end

% === Request a CHECK of infered AV vs observed AV
function requestVerification (obj, iObj, AVClass)
	obj.objects{iObj}.requests.check = true;
	obj.objects{iObj}.requests.verification = true;
	obj.objects{iObj}.requests.label = AVClass;
end

function preventVerification (obj, iObj, search, AVClass)
	if numel(obj.objects{iObj}.tmIdx) > 0
		obj.objects{iObj}.requests.check = false;
		obj.objects{iObj}.requests.verification = false;
		obj.objects{iObj}.requests.inference = false;
		% obj.objects{iObj}.requests.checked = false;
		obj.objects{iObj}.setLabel(AVClass, search);
	end
end

function [AVClass, search] = simulateAVInference (obj, iObj)
    data = retrieveObservedData(obj, iObj, 'best');
	AVClass = obj.MFI.inferCategory(data);
	search = find(strcmp(AVClass, obj.DW.labels));
end

function [inference, missing, check, verification, label] = getObjectRequests(obj, iObj)
	requests = getObject(obj, iObj, 'requests');
	inference = requests.inference;
	missing = requests.missing;
	check = requests.check;
	verification = requests.verification;
	label = requests.label;
end

function highTrainingPhase (obj)
	% --- Change the number of iterations of the MSOM
	% obj.MFI.MSOM.setParameters(20);
	% % --- Train again the MSOM with last data
	% obj.MFI.trainMSOM();
	% obj.MFI.MSOM.setParameters(10);
end

function computePresence (obj)
	obj.present_objects = find(getObject(obj, 'all', 'presence'));
	if isempty(obj.present_objects)
		obj.present_objects = [];
	end
end

function request = getCategories (obj, varargin)
	if nargin == 1
		request = obj.observed_categories;
	elseif nargin == 2
		if isstr(varargin{1})
			request = arrayfun(@(x) obj.observed_categories{x}.(varargin{1}),...
							   1:numel(obj.observed_categories),...
							   'UniformOutput', false);
		else
			request = arrayfun(@(x) obj.observed_categories{x}, varargin{1});
		end
	else
		if isstr(varargin{1})
			field = varargin{1};
			idx = varargin{2};
		else
			idx = varargin{1};
			field = varargin{2};
		end
		request = arrayfun(@(x) obj.observed_categories{x}.(field), idx, 'UniformOutput', false);
	end
end


function updateEnvironment (obj, tmIdx)
	
	obj.computePresence();
	
	obj.DW.setClasses();

	obj.checkInference();

	obj.DW.execute();

	arrayfun(@(x) obj.objects{x}.updateObj(), obj.present_objects);
		
end
	
end
% ===================== %
% === METHODS [END] === %
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %