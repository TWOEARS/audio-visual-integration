function [model_names, file_names] = retrieveAudioClassifiers ()

	folder = 'ClassifierData';

    d = dir(folder);
    nb_files = numel(d);
    % auditoryClassifiersKS = cell(0);
    model_names = cell(0);
    file_names = cell(0);

    for iFile = 1:nb_files
        if strfind(d(iFile).name, '.mat')
            model = d(iFile).name(1:strfind(d(iFile).name, '.')-1);
            % auditoryClassifiersKS{end+1} = bbs.createKS('IdentityKS', {d(iFile).name, folder}) ;
            model_names{end+1} = model;
            file_names{end+1} = d(iFile).name;
        end
    end

end