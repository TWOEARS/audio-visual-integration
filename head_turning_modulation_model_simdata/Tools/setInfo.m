function setInfo (parameter, value)

	information = getappdata(0, 'information');
	
	information.(parameter) = value;

	setappdata(0, 'information', information);
	
end