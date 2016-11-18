function increaseObjectWeight (htm, iObj)
	obj = getObject(htm, iObj);
	obj.weight = 1/(1+100*exp(-2*obj.tsteps));

end