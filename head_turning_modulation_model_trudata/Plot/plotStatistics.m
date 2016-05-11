
function plotStatistics (obj)
    s = obj.statistics ;
    d = [s.alpha_a ; s.beta_a ; s.alpha_v ; s.beta_v]' ;
    figure ;
    bar(d, 'grouped') ;

end
