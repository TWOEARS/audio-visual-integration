function decreaseObjectWeight (obj)

	obj.weight = 1/(1+0.01*exp(2*obj.tsteps)) - 1;

end