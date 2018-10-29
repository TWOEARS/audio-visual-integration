function bool = isPerformant (obj, idx, varargin)
% isPerformant function
% This knowledge source aims at providing a representation of the internal representation of the environment
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

	if isempty(idx)
		bool = false;
		return;
    elseif getInfo('modules') == 1
        bool = true;
        return;
	end

    env = getEnvironment(obj, 0);
    % dw = getEnvironment(obj, env.behavior, 'DW');


    if nargin == 3 && strcmp(varargin{1}, 'Object')
        % obj_label = getObject(obj, idx, 'label');
        % idx = find(strcmp(obj_label, dw.labels));
        idx = getObject(obj, idx, 'audiovisual_category');
    end
	
    % perf = getCategory(obj, idx, 'perf');
    % perf = dw.observed_categories{idx}.perf;
    perf = obj.MFI.observed_categories{idx}.perf;
    % nb_inf = dw.observed_categories{idx}.nb_inf;
    nb_inf = obj.MFI.observed_categories{idx}.nb_inf;
    
    if perf >= getInfo('q') && perf < 1 %&& nb_inf >= 5 % && perf < 1 && getCategory(obj, idx, 'nb_inf') >= 5
        bool = true;
    elseif perf == 1 && nb_inf > 2
    	bool = true;
    else
        bool = false;
    end
end