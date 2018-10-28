function [angles_cpt, angles_rad] = getAnglesCpt (htm)
	
	tmp = zeros(1, htm.information.nb_sources);
	sources = getObject(htm, 'all', 'source');

	for iStep = 2:htm.information.nb_steps
		if htm.FCKS.focus(iStep-1) ~= htm.FCKS.focus(iStep) && htm.FCKS.focus(iStep) ~= 0
			idx = sources(htm.FCKS.focus(iStep));
			tmp(idx) = tmp(idx)+1;
		end
	end

	angles_cpt = [tmp ; htm.FCKS.naive_focus];
	angles_rad = deg2rad(htm.information.sources_position);
