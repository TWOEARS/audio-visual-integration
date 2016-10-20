function audio_labels = retrieveAudioIdentityModels (htm)

	KSs = htm.bbs.blackboard.KSs;
    
    idKSs = find(arrayfun(@(x) isa(KSs{x}, 'IdentityKS'), 1:numel(KSs)));
    
    modelnames = arrayfun(@(x) KSs{x}.modelname, idKSs, 'UniformOutput', false);

    audio_labels = modelnames;
    
    % names = arrayfun(@(x) strfind(modelnames{x}, '.model.mat'), 1:numel(modelnames));
    
    % audio_labels = arrayfun(@(x) modelnames{x}(1:names(x)-1), 1:numel(modelnames), 'UniformOutput', false);

end