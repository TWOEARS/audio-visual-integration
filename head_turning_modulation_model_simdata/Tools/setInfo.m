function setInfo (parameter, value)

	global information

	% information = getappdata(0, 'information');
	
	information.(parameter) = value;

	% setappdata(0, 'information', information);
	
end