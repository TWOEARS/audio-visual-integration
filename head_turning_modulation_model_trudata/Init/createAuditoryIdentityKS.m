function KS = createAuditoryIdentityKS (bbs, models)

	folder = '/home/twoears/AuditoryModel/TwoEars-1.2/examples/identification_jido/Training.2016.01.31.21.11.16.074';
	KS = arrayfun(@(x) bbs.createKS('IdentityKS', {models{x}, folder}),...
				  1:numel(models),...
				  'UniformOutput', false);
end