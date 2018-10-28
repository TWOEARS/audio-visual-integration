function decreaseObjectWeight (htm, iObj)

	obj = getObject(htm, iObj);
	if obj.weight_hist(end) >= 0
		obj.tsteps = 1;
	end
	obj.weight = 1/(1+0.01*exp(2*obj.tsteps)) - 1;
	obj.weight_hist(end+1) = obj.weight;
end