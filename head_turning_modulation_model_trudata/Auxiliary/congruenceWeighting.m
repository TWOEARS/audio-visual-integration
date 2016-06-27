function weight = congruenceWeighting (posneg, val)

if strcmp(posneg, 'pos')
	weight = 1/(1+100*exp(-2*val)) ;
else
	weight = 1/(1+0.01*exp(2*val)) - 1 ;
end