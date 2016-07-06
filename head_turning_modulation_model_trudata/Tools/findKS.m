function ks = findKS (obj, ks_name)

	idx = find(arrayfun(@(x) isa(obj.blackboard.KSs{x}, ks_name), 1:numel(obj.blackboard.KSs)));
	ks = obj.blackboard.KSs{idx};
end