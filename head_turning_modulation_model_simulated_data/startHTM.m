% === Parameters of the simulation

% --- Take all audiovisual pairs 
scene = 0;
addpath(genpath('~/Dev/TwoEars-1.2/audio-visual-integration/head_turning_modulation_model_simulated_data'));

rmpath(genpath('~/Dev/TwoEars-1.2/audio-visual-integration/head_turning_modulation_model_trudata'));
rmpath(genpath('~/Dev/TwoEars-1.2/audio-visual-integration/LVTE'));

htm = HeadTurningModulationKS()