function ks = findKS (obj, ks_name)

	idx = find(arrayfun(@(x) isa(obj.blackboard.KSs{x}, ks_name), 1:numel(obj.blackboard.KSs)));
	if ~isempty(idx)
		ks = obj.blackboard.KSs{idx};
	else
		ks = 'no KS found';
	end
end