function KS = createAuditoryIdentityKS (bbs, models, files)

	KS = arrayfun(@(x) bbs.createKS('IdentityKS', {files{x}, 'ClassifierData'}),...
				  1:numel(models),...
				  'UniformOutput', false);

end