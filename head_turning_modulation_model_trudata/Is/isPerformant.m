function bool = isPerformant (obj, idx)
    perf = cell2mat(getCategory(obj, idx, 'perf'));
    
    if perf >= getInfo('q') && perf < 1
        bool = true;
    else
        bool = false;
    end
end