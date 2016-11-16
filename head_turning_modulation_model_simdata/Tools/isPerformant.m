function bool = isPerformant (obj, idx)

	% if idx == 0
	% 	bool = false;
	% 	return;
	% end
	
    perf = cell2mat(getCategory(obj, idx, 'perf'));
    
    if perf >= getInfo('q') && perf < 1
        bool = true;
    elseif perf == 1 && cell2mat(getCategory(obj, idx, 'nb_inf')) > 5
    	bool = true;
    else
        bool = false;
    end
end