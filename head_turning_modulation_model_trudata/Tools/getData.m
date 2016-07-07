function data = getData (htm, iObj, gtruth)
	if nargin == 2
		gtruth = false;
	end

	if iObj == 0
		iObj = htm.RIR.nb_objects;
	end

	tmIdx = getObject(htm, iObj, 'tmIdx');
	if gtruth
    	data = htm.gtruth_data(:, tmIdx);
    else
    	data = htm.data(:, tmIdx);
    end
end