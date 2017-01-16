function setupPaths ()

global TWOEARS_USER;

[~, TWOEARS_USER] = system('whoami');

switch lower(strtrim(TWOEARS_USER))
case {'tforgue'}
	p = '/home/tforgue/mystuff/work/laas/twoears/';
case {'bcl'}
    p = '/home/bcl/AuditoryModel/TwoEars-1.2/';
otherwise
	error('Two!Ears path not defined for user %s', TWOEARS_USER);
end

addpath(genpath(p));

rmpath(genpath([p, 'audio-visual-integration/head_turning_modulation_model_simdata']));
rmpath(genpath([p, 'audio-visual-integration/LVTE']));
rmpath(genpath([p, 'TwoEars']));
rmpath(genpath([p, 'audio-visual-integration/htm_v2']));
rmpath(genpath([p, '_old']));