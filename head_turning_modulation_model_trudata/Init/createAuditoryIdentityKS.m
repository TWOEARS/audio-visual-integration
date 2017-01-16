function KS = createAuditoryIdentityKS (bbs, models)

	global ROBOT_PLATFORM;
	% folder = '/home/twoears/AuditoryModel/TwoEars-1.2/examples/identification_jido/Training.2016.01.31.21.11.16.074';
	% folder = '/home/twoears/AuditoryModel/TwoEars-1.2/audio-visual-integration/head_turning_modulation_model_trudata/Dataset/mc2_models_dataset_1';
	if strcmp(ROBOT_PLATFORM, 'ODI')
    	folder = '/home/bcl/AuditoryModel/TwoEars-1.2/database-internal/learned_models/IdentityKS/mc3_fc3_segmented_nsGroundtruth_models_dataset_1/x';
    elseif strcmp(ROBOT_PLATFORM, 'JIDO')
    	folder = '/home/tforgue/mystuff/work/laas/twoears/database-internal/learned_models/IdentityKS/mc3_fc3_segmented_nsGroundtruth_models_dataset_1';
    end
	% folder = '/home/twoears/AuditoryModel/TwoEars-1.2/twoears-demos/identification_distractor_NIGENS/models.0db';
	KS = arrayfun(@(x) bbs.createKS('IdentityKS', {models{x}, folder, false}),...
				  1:numel(models),...
				  'UniformOutput', false);
end