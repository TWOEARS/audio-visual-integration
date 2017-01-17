function bool = isPerformant (obj, idx, varargin)
% isPerformant function
% This knowledge source aims at providing a representation of the internal representation of the environment
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

	if isempty(idx)
		bool = false;
		return;
	end
    if nargin == 3 && strcmp(varargin{1}, 'Object')
         idx = getObject(obj, idx, 'audiovisual_category');
     end
	
    perf = getCategory(obj, idx, 'perf');
    
    if perf >= getInfo('q') && perf < 1 && getCategory(obj, idx, 'nb_inf') >= 10
        bool = true;
    elseif perf == 1 && getCategory(obj, idx, 'nb_inf') >= 10
    	bool = true;
    else
        bool = false;
    end
end