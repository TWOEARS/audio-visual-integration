function request = modulesActivity (htm)

	env = getEnvironment(htm, 0);

	request = [];

	for iObject = 1:numel(env.objects);
		c = getCategory(htm, iObject, 'Object');
		
		tau_dw = c.proba/(0.1*env.DW.nb_classes);

		tau_mfi = c.perf/getInfo('q');

		tau_dw = tau_mfi - tau_dw*myHeaviside(1, tau_mfi);

		if tau_mfi > 1
			request(end+1) = tau_dw;
		else
			request(end+1) = tau_mfi;
		end
	end