function value = getInfo (parameter)

	information = getappdata(0, 'information');
	value = information.(parameter);
	
end