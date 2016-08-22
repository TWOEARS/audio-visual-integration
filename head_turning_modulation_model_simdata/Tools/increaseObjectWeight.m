function increaseObjectWeight (obj)

	obj.weight = 1/(1+100*exp(-2*obj.tsteps));

end