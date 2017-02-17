tt = zeros(info.nb_sources, 1);
for iSource = 1:info.nb_sources
	for iStep = 3:2:numel(info.timeline{iSource})
		tt(iSource) = tt(iSource) + info.timeline{iSource}(iStep)-info.timeline{iSource}(iStep-1);
	end
end