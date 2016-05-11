function getAVdata(aud)

	if ~iscell(aud)
		aud = aud.robotConnect.auditoryGTVector ;
	end

	aud(1) = [] ;
	nb_sources = numel(aud) ;

	t_idx_all = cell(1, nb_sources) ;

	t_idx = [] ;

	labels_all = cell(1, nb_sources) ;

	cpt = 0 ;

	for iSource = 1:nb_sources
		aud{iSource}(1) = [] ;
		aud{iSource}(strcmp(aud{iSource}, '')) = [] ;

		
		idx = find(arrayfun(@(x) isnumeric(aud{iSource}{x}), 1:numel(aud{iSource}))) ;
		tmp = cell2mat(aud{iSource}(idx)) ;
		
		t_idx = [t_idx ; [tmp(1 :2: end)', tmp(2 :2: end)', ones(numel(tmp)/2, 1)*iSource]] ;

		t_idx_all{iSource} = zeros(numel(tmp)/2, 2) ;
		t_idx_all{iSource}(:, 1) = tmp(1 :2: end) ;
		t_idx_all{iSource}(:, 2) = tmp(2 :2: end) ;

		idx = find(arrayfun(@(x) ~isnumeric(aud{iSource}{x}), 1:numel(aud{iSource}))) ;
		tmp = aud{iSource}(idx) ;

		labels_all{iSource} = [tmp(1 :2: end)', tmp(2 :2: end)'] ;
		cpt = cpt+numel(idx) ;
	end

	[~, idx] = sort(t_idx(:, 1)) ;

	tmp = t_idx ;
	t_idx = zeros(size(tmp)) ;
	labels = cell(numel(idx), 2) ;

	for iLine = 1:numel(idx)
		t_idx(iLine, :) = tmp(idx(iLine), :) ;
		labels(iLine, :) = labels_all{tmp(idx(iLine), 3)}(1, :) ;
		labels_all{tmp(idx(iLine), 3)}(1, :) = [] ;
	end

	AVdata.t_idx = t_idx ;
	AVdata.labels = labels ;
	AVdata.wrong = find(arrayfun(@(x) strcmp(labels{x, 2}, 'wrong'), 1:size(labels, 1))) ;
	AVdata.correct = find(arrayfun(@(x) strcmp(labels{x, 2}, 'acceptable'), 1:size(labels, 1))) ;

	setappdata(0, 'AVdata', AVdata) ;

end