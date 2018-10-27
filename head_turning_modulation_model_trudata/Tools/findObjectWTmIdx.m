function [object, idx] = findObjectWTmIdx (htm, tmIdx)
	env = getEnvironment(htm, 0);
	objects = env.objects;
	object = [];
	for iObject = 1:htm.RIR.nb_objects
		tmp = getObject(htm, iObject, 'tmIdx');
		if ~isempty(find(tmp == tmIdx))
			object = getObject(htm, iObject);
			idx = iObject;
		end
	end
	if isempty(object)
		object = 'silence';
		idx = 0;
	end
end