% 'PerceivedEnvironment' class
% This class is part of the HeadTurningModulationKS
% Author: Benjamin Cohen-Lhyver
% Date: 01.02.16
% Rev. 2.0

classdef PerceivedEnvironment < handle

% ===Properties (BEG) === %
properties (SetAccess = public, GetAccess = public)
    present_objects = [] 	  ; % objects present in the environment
    % classes 		= cell(0) ; % cell containing a structure with category, probabilities, counter, weight
    objects 		= cell(0) ; % all detected objects 
    % AVClasses = [] ;
    MFI = [] ;
    labels = {} ;
end
properties (SetAccess = private, GetAccess = public)
    counter = 0 ;
    nb_classes = 0 ;
    observed_categories = cell(0) ;
    obs_struct = struct('label'		, 'none_none',...
    					'perf'		, 0,...
    					'nb_goodInf', 0,...
    					'nb_inf'    , 0,...
    					'cpt'		, 0,...
    					'proba'	    , 0) ;
end
% ===Properties (END) === %

% === Methods (BEG) === %
methods
% --- Constructor (BEG) --- %
function obj = PerceivedEnvironment ()

	obj.MFI = MultimodalFusionAndInference() ;

	% --- Initialize categories
	obj.observed_categories{1} = obj.obs_struct ;
end
% --- Constructor (END) --- %

% --- Other methods --- %
function addObject (obj, data, theta, d)
	% --- Create a new PERCEIVEDOBJECT object
    obj.objects{end+1} = PerceivedObject(data, theta, d) ;
    obj.addInput() ;
end

function addInput (obj)
	if ~obj.objects{end}.requests.missing
		% --- Train nets
		obj.MFI.newInput(obj.objects{end}.getBestData()) ;
	end
end

function updateLabel (obj, data)
	obj.objects{end}.addData(data) ;
	obj.addInput() ;
end

function trainMSOM (obj)
	obj.MFI.trainMSOM() ;
end

function setClasses (obj)
	if isempty(obj.MFI.categories)
		obj.MFI.setCategories() ;
	end
	categories = obj.MFI.getCategories() ;
	for iClass = 1:numel(categories)
		% labels = obj.getCategories('label') ;
		search = find(strcmp(categories{iClass}, obj.labels)) ;
		if isempty(search)
			obj.createNewCategory(categories{iClass}) ;
		end			
	end
end

function createNewCategory (obj, label)
	obj.observed_categories{end+1} = obj.obs_struct ;
	obj.observed_categories{end}.label = label ;
	obj.labels = [obj.labels, label] ;
end


function checkInference (obj)
	labels = obj.labels ;
	for iObj = obj.present_objects
		% --- If an inference has been requested
		if obj.objects{iObj}.requests.inference
			% --- If visual data is still not available
			if obj.objects{iObj}.requests.missing
				% --- If a CHECK has been requested (-> motor order)
				if obj.objects{iObj}.requests.check
					% --- Continue to turn the head to the object
				% --- If a CHECK has not been yet requested -> trigger the motor order
				else
					% --- Simulate an AV inference
					AVClass = obj.MFI.inferCategory(obj.objects{iObj}.getBestData()) ;
					search = find(strcmp(AVClass, labels)) ;
					% --- If the category has been correctly inferred in the past
					% --- CHECK is not needed -> we trust the inference
					if obj.isPerformant(search)
						obj.objects{iObj}.requests.check = false ;
						obj.objects{iObj}.requests.verification = false ;
						obj.objects{iObj}.setLabel(AVClass) ;
						obj.objects{iObj}.cat = search ;
					% --- If the category has not been well infered in the past
					% --- CHECK is needed -> we don't trust the inference
					else
						% --- Request a CHECK of infered AV vs observed AV
						obj.objects{iObj}.requests.check = true ;
						obj.objects{iObj}.requests.label = AVClass ;
						obj.observed_categories{search}.nb_inf = obj.observed_categories{search}.nb_inf + 1 ;
					end
				end
			end
		% --- If no inference requested (AV data available)
		% --- But a verification is requested
		% --- ADD A VERIFICATION WITH NO CHECK in order to verify the inference in the case we have AV thanks to DWmod
		elseif obj.objects{iObj}.requests.verification
			% --- We now have the full AV data
			AVClass = obj.MFI.inferCategory(obj.objects{iObj}.getBestData()) ;
			search = find(strcmp(AVClass, labels)) ;
			% --- If infered AV is the same as observed AV
			if strcmp(AVClass, obj.objects{iObj}.requests.label)
				obj.objects{iObj}.requests.verification = false ;
				obj.objects{iObj}.requests.check = false ;

				obj.observed_categories{search}.nb_goodInf = obj.observed_categories{search}.nb_goodInf+1 ;

				obj.objects{iObj}.setLabel(AVClass) ;
				obj.objects{iObj}.cat = search ;
			else
				% --- 
			end
		% Else if all data available
		elseif ~obj.objects{iObj}.requests.missing
			% --- Infer AV class
			AVClass = obj.MFI.inferCategory(obj.objects{iObj}.getBestData()) ;
			search = find(strcmp(AVClass, labels)) ;

			obj.objects{iObj}.setLabel(AVClass) ;
			obj.objects{iObj}.cat = search ;
			obj.objects{iObj}.requests.check = false ;
		end
	end
end

function bool = isPerformant (obj, idx)
	if obj.observed_categories{idx}.perf >= 0.75
		bool = true ;
		if obj.observed_categories{idx}.perf == 1 && obj.observed_categories{idx}.nb_inf < 4
			bool = false ;
		end
	else
		bool = false ;
	end
end


function computeCategoryPerformance (obj)
	for iClass = 1:numel(obj.observed_categories)
		obj.observed_categories{iClass}.perf = obj.observed_categories{iClass}.nb_goodInf/...
											   obj.observed_categories{iClass}.nb_inf ;

		if isnan(obj.observed_categories{iClass}.perf) || isinf(obj.observed_categories{iClass}.perf)
			obj.observed_categories{iClass}.perf = 0 ;
		end
	end
end

function computeCategoryProba (obj)
	for iClass = 1:numel(obj.observed_categories)
		obj.observed_categories{iClass}.proba = obj.observed_categories{iClass}.cpt/numel(obj.objects) ;

		if isnan(obj.observed_categories{iClass}.proba) || isinf(obj.observed_categories{iClass}.proba)
			obj.observed_categories{iClass}.proba = 0 ;
		end
		obj.observed_categories{iClass}.proba = obj.observed_categories{iClass}.cpt/numel(obj.objects) ;

		if isnan(obj.observed_categories{iClass}.proba) || isinf(obj.observed_categories{iClass}.proba)
			obj.observed_categories{iClass}.proba = 0 ;
		end
	end
end


function reinitializeClasses (obj)
	for iClass = 1:numel(obj.observed_categories)
		obj.observed_categories{iClass}.cpt = 0 ;
	end
end

function categorizeObjects (obj)

	obj.reinitializeClasses() ;
	for iObj = 1:numel(obj.objects)
		if obj.objects{iObj}.cat > 0
			obj.observed_categories{obj.objects{iObj}.cat}.cpt = obj.observed_categories{obj.objects{iObj}.cat}.cpt + 1 ;
		else
			obj.observed_categories{1}.cpt = obj.observed_categories{1}.cpt + 1 ;
		end
	end

	cpts = cell2mat(arrayfun(@(x) obj.observed_categories{x}.cpt > 0,...
							 1:numel(obj.observed_categories),...
							 'UniformOutput', false)) ;
	obj.nb_classes = sum(cpts) ;

end

function countObjects (obj)
	for iObj = 1:numel(obj.objects)
		if iObj ~= obj.present_objects
			AVClass = obj.MFI.inferCategory(obj.objects{iObj}.getBestData()) ;
			obj.objects{iObj}.setLabel(AVClass) ;
			search = find(strcmp(AVClass, obj.labels)) ;
			obj.objects{iObj}.cat = search ;
		end
	end
end

function computePresence (obj)
	obj.present_objects = [] ;
	for iObj = 1:numel(obj.objects)
		if obj.objects{iObj}.presence
			obj.present_objects = [obj.present_objects, iObj] ;
		end
	end
end

function computeWeights (obj)
	% for iObj = 1:numel(obj.objects)
	for iObj = obj.present_objects
		obj_cat = obj.objects{iObj}.cat ;
		if obj_cat ~= 0
		% --- Compute weights thanks to weighting functions
			% --- Incongruent
			if obj.observed_categories{obj_cat}.proba <= 1/obj.nb_classes
				obj.objects{iObj}.setWeight('pos') ;
			% --- Congruent
			else
				obj.objects{iObj}.setWeight('neg') ;
			end
		end
	end
end

function cpt = getCounter (obj)
	cpt = obj.counter ;
end

function request = getCategories (obj, varargin)
	if nargin == 1
		request = obj.observed_categories ;
	elseif nargin == 2
		if isstr(varargin{1})
			request = arrayfun(@(x) obj.observed_categories{x}.(varargin{1}),...
							   1:numel(obj.observed_categories),...
							   'UniformOutput', false) ;
		else
			request = arrayfun(@(x) obj.observed_categories{x}, varargin{1}) ;
		end
	else
		if isstr(varargin{1})
			field = varargin{1} ;
			idx = varargin{2} ;
		else
			idx = varargin{1} ;
			field = varargin{2} ;
		end
		request = arrayfun(@(x) obj.observed_categories{x}.(field), idx) ;
	end
end



function updateObjects (obj, tmIdx)
	obj.counter = obj.counter + 1 ;
	
	obj.objects{end}.updateTime(tmIdx) ;

	% obj.trainMSOM() ;

	obj.computePresence() ;

	obj.labels = arrayfun(@(x) obj.observed_categories{x}.label,...
					  	  1:numel(obj.observed_categories),...
					  	  'UniformOutput', false) ;

	obj.setClasses() ;

	obj.checkInference() ;

	obj.categorizeObjects() ;

	obj.countObjects() ;

	obj.computeCategoryPerformance() ;

	% obj.computeCategoryProba() ;

	obj.computeWeights() ;
	
	arrayfun(@(x) obj.objects{x}.updateObj(), obj.present_objects) ;
		
end
	
end

end