function [cpt_mfi, cpt_dw] = getShmByFocusType (htm)

	focus_origin = htm.FCKS.focus_origin;
	focus = htm.FCKS.focus;

	cpt_mfi = 0;
	cpt_dw = 0;

	for iStep = 1:htm.information.nb_steps-1
		if focus(iStep) ~= focus(iStep+1) && focus(iStep+1) ~= 0
			if focus_origin(iStep+1) == -1
				cpt_mfi = cpt_mfi + 1;
			elseif focus_origin(iStep+1) == 1
				cpt_dw = cpt_dw + 1;
			end
		end
	end
