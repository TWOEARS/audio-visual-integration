function [model_names, file_names] = retrieveAudioClassifiers ()

	folder = '/home/twoears/AuditoryModel/TwoEars-1.2/examples/identification_jido/Training.2016.01.31.21.11.16.074';
    % folder = '/home/twoears/AuditoryModel/TwoEars-1.2/twoears-demos/identification_distractor_NIGENS/models.0db';

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