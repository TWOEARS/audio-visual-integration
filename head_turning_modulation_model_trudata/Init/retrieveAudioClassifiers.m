function [model_names, file_names] = retrieveAudioClassifiers ()

    global ROBOT_PLATFORM
	% folder = '/home/twoears/AuditoryModel/TwoEars-1.2/examples/identification_jido/Training.2016.01.31.21.11.16.074';
    
    % folder = '/home/twoears/AuditoryModel/TwoEars-1.2/audio-visual-integration/head_turning_modulation_model_trudata/Dataset/mc2_models_dataset_1';
    % folder = '/home/twoears/AuditoryModel/TwoEars-1.2/twoears-demos/identification_distractor_NIGENS/models.0db';
    if strcmp(ROBOT_PLATFORM, 'ODI')
        folder = '/home/bcl/AuditoryModel/TwoEars-1.2/database-internal/learned_models/IdentityKS/mc3_fc3_segmented_nsGroundtruth_models_dataset_1/x';
    elseif strcmp(ROBOT_PLATFORM, 'JIDO')
        folder = '/home/tforgue/mystuff/work/laas/twoears/database-internal/learned_models/IdentityKS/mc3_fc3_segmented_nsGroundtruth_models_dataset_1';
    end

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