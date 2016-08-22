function value = getInfo (varargin)

	information = getappdata(0, 'information');

	fnames = fieldnames(information);

	if nargin == 0
		disp(information);
		BOOL = false;
		str = input('Please select a field to retrieve: ', 's');
		while ~BOOL
			varargin{1} = str;
			if ~strcmp(str, fnames)
				str = input('Error: Wrong Field. \nPlease select again a field to retrieve: ', 's');
			else
				BOOL = true;
			end
		end
	end

	if nargin == 1 && strcmp(varargin{1}, 'all')
		fnames = fieldnames(information);
	elseif nargin > 1
		fnames = varargin;
	else
		value = information.(varargin{1});
		return;
	end

	nb_fields = numel(fnames);

	for iParam = 1:nb_fields
		value.(fnames{iParam}) = information.(fnames{iParam});
	end

end