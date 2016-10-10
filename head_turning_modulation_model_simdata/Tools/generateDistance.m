function d = generateDistance ()
    d = rand() + randi(getInfo('distance_max'));
    if d <= 3
    	d = d+4;
    end
end