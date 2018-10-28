function value = getInfo (varargin)

	global information info_fnames;
	% information = getappdata(0, 'information');

	% fnames = fieldnames(information);

	if nargin == 0
		disp(information);
		BOOL = false;
		str = input('Please select a field to retrieve: ', 's');
		while ~BOOL
			varargin{1} = str;
			if ~strcmp(str, info_fnames)
				str = input('Error: Wrong Field. \nPlease select again a field to retrieve: ', 's');
			else
				BOOL = true;
			end
        end
    elseif strcmp(varargin{1}, 'show')
        disp(information);
        return;
	end

	if nargin == 1 && strcmp(varargin{1}, 'all')
		info_fnames = fieldnames(information);
	elseif nargin > 1
		info_fnames = varargin;
	else
		value = information.(varargin{1});
		return;
	end

	nb_fields = numel(info_fnames);

	for iParam = 1:nb_fields
		value.(info_fnames{iParam}) = information.(info_fnames{iParam});
	end

end