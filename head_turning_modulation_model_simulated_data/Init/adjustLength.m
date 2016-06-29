function [nb_objects, nb_steps] = adjustLength(nb_steps, set_info)


	if nargin == 1
		set_info = false;
	end

	cpt_silence = getInfo('cpt_silence');
	cpt_object = getInfo('cpt_object');

	s = cpt_silence + cpt_object;
    nb_objects = ceil(nb_steps / s);

    if set_info
    	setInfo('nb_steps', nb_objects*s);
		setInfo('nb_objects',nb_objects);
		return;
	end

end