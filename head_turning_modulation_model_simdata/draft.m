tt = zeros(info.nb_sources, 1);
for iSource = 1:info.nb_sources
	for iStep = 3:2:numel(info.timeline{iSource})
		tt(iSource) = tt(iSource) + info.timeline{iSource}(iStep)-info.timeline{iSource}(iStep-1);
	end
end




nb_sources = getInfo('nb_sources');
nb_steps = getInfo('nb_steps');
nb_al = getInfo('nb_audio_labels');
nb_vl = getInfo('nb_visual_labels');
nb_labels = getInfo('nb_labels');

audio_labels = getInfo('audio_labels');
visual_labels = getInfo('visual_labels');

av_classes = zeros(1, 5);

objects = {};

ii = [0, 0];

head_position = 0;

for iStep = 1:nb_steps

	for iSource = 1:nb_sources
		av_classes_step = [];
		data = htm.gtruth_data{iSource}(:, iStep);
		if 
		if all(data ~= 0) % donnée audio_visuelle
		if sum(data) ~= 0
			[~, tmp1] = max(data(1:nb_al));
			[~, tmp2] = max(data(nb_al+1:end));
			av_classes_step = [tmp1, tmp2, iSource];
			if (tmp1) == 14 && tmp2 == 1
				ii = [iStep, iSource];
			end
			BOOL = false;
			% BOOL2 = false;
			idx = 0;
			for iClass = 1:size(av_classes, 1)
				if all(av_classes_step == av_classes(iClass, [1:2, 4]))
					% if iSource == av_classes(iClass, 4)
						BOOL = true;
						idx = iClass;
					% else
					% 	BOOL2 = true;
					% end
				end
			end
			if BOOL
				av_classes(idx, 3) = av_classes(idx, 3)+1;
			else
				if sum(av_classes == 0)
					av_classes(1, :) = [av_classes_step(1:2), 1, av_classes_step(end), 1];
				else
					av_classes(end+1, :) = [av_classes_step(1:2), 1, av_classes_step(end), 1];
				end
			end

		end
	end

	for iClass1 = 1:size(av_classes, 1)
		tmp = 1;
		for iClass2 = iClass1:size(av_classes, 1)
			if iClass1 ~= iClass2
				if all(av_classes(iClass1, 1:2) == av_classes(iClass2, 1:2))
					tmp = tmp + 1;
				end
			end
		end
		av_classes(iClass1, 5) = tmp/numel(unique(av_classes(:, 1:2)));%size(av_classes, 1);
	end
end

	% [~, I] = sort(av_classes, 1);
	% av_classes = av_classes(I(:, 1), :);

	% % for iClass = 2:size(av_classes, 1)
	% av_classes(2:end, end) = av_classes(2:end, 3) / (size(av_classes, 1)-1);

av_classes(1, :) = [];

av_labels = cell(size(av_classes, 1), 2);

for iClass = 1:size(av_classes, 1)
	vl = visual_labels{av_classes(iClass, 2)};
	al = audio_labels{av_classes(iClass, 1)};
	av_labels{iClass, 1} = vl;
	av_labels{iClass, 2} = al;
end


% [~, I] = sort(av_classes, 1);

% av_classes = av_classes(I(:, 1), :);



svec = MSOM.sub_vec;

% d = zeros(size(svec));
d = zeros(MSOM.nb_nodes, 1);


for iNode = 1:MSOM.nb_nodes
	idx = [iNode-1, iNode-22, iNode+1, iNode+22];
	idx(idx <= 0) = [];
	idx(idx > 484) = [];
	v1 = MSOM.weights_vectors{1}(iNode, :);

	d(iNode) = mean(sqrt(sum(bsxfun(@minus, v1, MSOM.weights_vectors{1}(idx, :)).^2, 2)));
end
	% v2 = MSOM.weights_vectors{1}(iNode2, :);
	% tmp = sqrt(sum((v1-v2).^2));

	% d(iNode) = mean([d(iNode), tmp]);


	for iNode2 = 1:MSOM.nb_nodes



		% if iNode == 1
		% 	idx = [iNode, iNode2;...
		% 		   iNode+1, iNode2];
		% 	if iNode2 == 1
		% 		idx = [idx ;...
		% 			   iNode+1, iNode2+1;...
		% 			   iNode, iNode2+1];
		% 	elseif iNode2 == MSOM.som_dimension(1)
		% 		idx = [idx ;...
		% 			   iNode, iNode2-1;...
		% 			   iNode+1, iNode2-1];
		% 	else
		% 		idx = [idx ;...
		% 			   iNode, iNode2-1;...
		% 			   iNode+1, iNode2-1;...
		% 			   iNode+1, iNode2+1;...
		% 			   iNode, iNode2+1];
		% 	end
		% elseif iNode == MSOM.som_dimension(1)
		% 	idx = [iNode, iNode2;...
		% 	  	   iNode]
			
		% end
		
		v1 = MSOM.weights_vectors{1}(iNode, :);
		v2 = MSOM.weights_vectors{1}(iNode2, :);
		tmp = sqrt(sum((v1-v2).^2));

		d(iNode) = mean([d(iNode), tmp]);
	end
	iNode
	% d = d.*MSOM.aleph{iNode, 5};
end

d = reshape(d, 22, 22);

d2 = d./(max(max(d)));

axis;

set(gca, 'XLim' , [1, MSOM.som_dimension(1)+1],...
         'YLim' , [1, MSOM.som_dimension(1)+1],...
         'XTick', [1:MSOM.som_dimension(1)],...
         'YTick', [1:MSOM.som_dimension(1)]);
grid on;
hold on;


[I, J] = ind2sub(MSOM.som_dimension(1), 1:MSOM.nb_nodes);

for iNode = 1:MSOM.nb_nodes
    x = I(iNode);
    y = J(iNode);

    patch([x, x+1, x+1, x], [y, y, y+1, y+1], 'blue', 'FaceAlpha', d2(x, y));
end




    x1 = x + ((1-dist1(iNode))/2) ;
    y1 = y + ((1-dist1(iNode))/2) ;

    x1 = [x1, x1+dist1(iNode), x1+dist1(iNode), x1] ;
    y1 = [y1, y1, y1+dist1(iNode), y1+dist1(iNode)] ;

    x2 = x + ((1-dist2(iNode))/2) ;
    y2 = y + ((1-dist2(iNode))/2) ;

    x2 = [x2, x2+dist2(iNode), x2+dist2(iNode), x2] ;
    y2 = [y2, y2, y2+dist2(iNode), y2+dist2(iNode)] ;

    x3 = [x, x+1, x+1, x] ;
    y3 = [y, y, y+1, y+1] ;
    patch(x3, y3, 'blue', 'FaceAlpha', dist3(iNode)) ;

    if dist1(iNode) >= dist2(iNode)
        patch(x1, y1, 'red') ;
        patch(x2, y2, 'black') ;
    else
        patch(x2, y2, 'black') ;
        patch(x1, y1, 'red') ;
    end
end



% =========



d = [];

for ii = 1:22
	tmp = [];
	for jj = 1:22
		tmp(end+1) = sqrt(sum(msom.weights_vectors{1}(ii, :) - msom.weights_vectors{1}(jj, :)).^2);
	end
	d(end+1) = mean(tmp);
end



connections = [1, 1 ;...
			   1, 2 ;...
			   1, 22 ;...
			   1, 23 ;...
			   2, 1 ;...
			   2, 2 ;...
			   2, 3 ;...
			   2, 22 ;...
			   2, 23 ;...
			   2, 24 ;...]



vec = fliplr(reshape(prod(msom.som_dimension):-1:1, msom.som_dimension(1), msom.som_dimension(2))');
msom.vec = repmat(vec, 3, 3);
msom.sub_vec = msom.vec(msom.som_dimension(1)+1:2*msom.som_dimension(1), msom.som_dimension(1)+1:2*msom.som_dimension(1));



figure('Color', 'white');

d = htm.data{3}(:, 16);
H = [d(38:end) ; d(1:37)];
N = numel(H);
for ii=1:N
  h = bar(ii, H(ii));
  if ii == 1, hold on, end
  if ii <= getInfo('nb_visual_labels')
    col = [0, 1, 1];
  else
    col = [0, 0, 1];
  end
  set(h, 'FaceColor', col) 
end
set(gca, 'XTick', 1:getInfo('nb_labels'),...
		 'XTickLabel', [getInfo('visual_labels'), getInfo('audio_labels')],...
		 'XTickLabelRotation', 45,...
		 'XLim', [0, 56],...
		 'FontSize', 16);

