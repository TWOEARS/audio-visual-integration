function visual_vec = getVisualClassifiersOutput (obj)
    visual_hyp = obj.blackboard.getLastData('visualIdentityHypotheses').data ;
    visual_vec = cell2mat(arrayfun(@(x) visual_hyp(obj.visual_labels{x}),...
                                    1:numel(obj.visual_labels),...
                                    'UniformOutput', false))' ;
    visual_vec = visual_vec/sum(visual_vec) ;
    visual_vec(isnan(visual_vec)) = 0 ;
    
    % visual_vec = zeros(getInfo('nb_visual_labels'), 1);
end