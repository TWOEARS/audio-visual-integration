function missing = isDataMissing (obj)	

	a = obj.data_tmp(1:obj.nb_alabels, end) ;
	v = obj.data_tmp(obj.nb_alabels+1:end, end) ;
	eq_prob_a = 1/obj.nb_alabels ;
	eq_prob_v = 1/obj.nb_vlabels ;
	eq_prob_thr_a = eq_prob_a + 0.1*eq_prob_a ;
	eq_prob_thr_v = eq_prob_v + 0.1*eq_prob_v ;
	if sum(a) < 0.1 || sum(v) < 0.1
		missing = true ;
	elseif all(a <= eq_prob_thr_a) && all(a >= eq_prob_thr_a)
		missing = true ;
	elseif all(v <= eq_prob_thr_v) && all(v >= eq_prob_thr_v)
		missing = true ;
	else
		missing = false ;
	end

end