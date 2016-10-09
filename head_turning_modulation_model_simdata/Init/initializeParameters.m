% 'initializeParameters' function
% This function creates the INFO variable which will be used all along the simulations.
% It cares all the needed information for the system to work, depending also on the user inputs.
% The file 'Config.xml' is used to retrieve some of the user parameters.
% Two more parameters are needed:
% 1. NB_STEPS is the duration of the simulation
% 2. SCENE is the indexes of the audiovisual pairs simulated in the current scenario.
% These audiovisual pairs are listed in the 'AVPairs.xml' file and the indexes refer to the lines of this file.

function initializeParameters ()

    disp('HTM: initialization of parameters');
    pause(0.25);
    disp('..................................................');
	
    information = struct('audio_labels'    , [],...
						 'visual_labels'   , [],...
						 'nb_audio_labels' , 0 ,...
						 'nb_visual_labels', 0 ,...
						 'nb_labels'	   , 0 ,...
						 'AVPairs'		   , 0 ,...
						 'nb_AVPairs'	   , 0 ,...
						 'fov'			   , 0 ,...
						 'distance_max'	   , 0 ,...
						 'nb_angles'	   , 0 ,...
						 'sources_position', [],...
                         'distances'       , [],...
                         'repartition'     , [],...
						 'obs_struct'	   , [],...
						 'statistics'	   , [],...
						 'thr_epsilon'	   , 0 ,...
						 'thr_wrong'       , 0 ,...
                         'thr_theta'       , 10,...
                         'nb_steps'        , 0 ,...
                         'cpt_silence'     , 0 ,...
                         'cpt_object'      , 0 ,...
                         'scenario'        , []...
                         );

    path_to_folder = '../../examples/attention_simulation';

    config_file = xmlread([path_to_folder, filesep, 'Config.xml']);

    parameters = config_file.getElementsByTagName('pair');

    nb_parameters = parameters.getLength();

    for iPair = 0:nb_parameters-1
        pair = parameters.item(iPair);

        parameter = char(pair.getAttribute('parameter'));
        value = char(pair.getAttribute('value'));
        if ~strcmp(parameter, 'notification')
            if strcmp(parameter, 'avpairs')
                scene = str2num(value);
            else
                value = str2num(value);
            end
        end
        information.(parameter) = value;
    end

    information = rmfield(information, 'avpairs');

    % % ================ %
    % % === EDITABLE === %
    % % ================ %
    % % --- Field of view of the robot
    % information.fov = 30;
    % % --- Max distance of an object to the robot
    % information.distance_max = 4;
    % % --- Number of sound sources

    % % --- Thresholds used for experts outputs emulation
    % % --- Minimum
    % information.thr_epsilon = 0.7;
    % % --- Wrong AV Pair
    % information.thr_wrong = 0.3;

    % information.smoothing = 1;
    % % --- ???
    % % information.thr_both = 1;
    
    % % information.cpt_object = 30;
    % % information.cpt_silence = 10;
    % % information.cpt_simulation = 0;

    % % --- Performance criterion
    % information.q = 0.8;

    % information.cpt_silence = 10;
    % information.cpt_object = 30;

    % information.notification = 'notification.wav';

    % =========================================================================== %
    % =========================================================================== %
    % =========================================================================== %

    % =================== %
    % === DO NOT EDIT === %
    % =================== %
    % --- Retrieve audiovisual pairs from 'AVPairs.xml' file
    % --- 'AVPairs.xml' can be edited
    [AVPairs, audio_labels, visual_labels] = retrieveAudioVisualLabels();

    % information.nb_angles = numel(AVPairs);
    information.nb_angles = numel(information.nb_sources);
    % --- Positions of the sound sources.
    % --- They are here plaed regularly around the robot,
    % --- outside the field of view of the robot when at resting state
    % information.sources_position = linspace(information.fov+1,...
    %                                         360-information.fov-1,...
    %                                         information.nb_angles);

    % --- Determining the sources position in a 2D environment
    tmp_sources_angular_pos = linspace(0,...
                                       360,...
                                       information.nb_sources+1);
    information.sources_position = tmp_sources_angular_pos(1:end-1);

    information.distances = rand(1, information.nb_sources) + randi([3, 7], 1, information.nb_sources);
    % d(d <= 3) = d(d <= 3) + 3;
    % d(d >= information.distance_max) = d(d >= information.distance_max) - 1.5;
    % if d <= 3
    %     d = d+4;
    % end
    %information.distances = d;

    % avpairs = mergeLabels(AVPairs(scene));

    % information.positions = [avpairs, information.sources_position'];

    information.audio_labels    = audio_labels;
    information.nb_audio_labels = numel(information.audio_labels);

    information.visual_labels    = visual_labels;
    information.nb_visual_labels = numel(information.visual_labels);

    information.AVPairs    = AVPairs;
    information.nb_AVPairs = numel(information.AVPairs);

    information.nb_labels = information.nb_audio_labels + information.nb_visual_labels;

    information.obs_struct = struct('label'     , 'none_none',...
                                    'perf'      , 0,...
                                    'nb_goodInf', 0,...
                                    'nb_inf'    , 0,...
                                    'cpt'       , 0,...
                                    'proba'     , 0,...
                                    'congruence', 0 ...
                                   );
                                
    information.statistics = struct('max'         , []        ,...
                                    'max_mean'    , []        ,...
                                    'max_shm'     , []        ,...
                                    'max_mean_shm', []        ,...
                                    'mfi'         , []        ,...
                                    'mfi_mean'    , []        ,...
                                    'alpha_a'     , 0         ,...
                                    'alpha_v'     , 0         ,...
                                    'beta_a'      , 0         ,...
                                    'beta_v'      , 0         ,...
                                    'c'           , []        ,...
                                    'vec'         , [0 :0.1: 1]...
                                   );

    information.plot_fcn = {'focus'         ,...
                            'goodClassif'   ,...
                            'goodClassifObj',...
                            'shm'           ,...
                            'hits'          ,...
                            'headMovements' ,...
                            'statistics'     ...
                           };

    if scene == 0
        scene = 1:numel(AVPairs);
    elseif scene(end) > numel(AVPairs)
        scene(scene > numel(AVPairs)) = [];
    end

    information.scenario = struct('idx'       , 1        ,...
                                  'scene'     , {{scene}},...
                                  'unique_idx', {scene}   ...
                                 );

    information.repartition = assignSource(scene, information.nb_sources);
    
    % [information.nb_objects, information.nb_steps] = adjustLength(nb_steps);

    nb_steps = information.nb_steps;
    s = information.cpt_silence + information.cpt_object;
    nb_objects = ceil(nb_steps / s);
    
    information.nb_steps = nb_objects * s;

    information.nb_objects = nb_objects;

    if isappdata(0, 'msom_weights')
        rmappdata(0, 'msom_weights');
    end

    setappdata(0, 'information', information);

    pause(0.1);
    disp('PARAMETERS OF CURRENT SIMULATION:');
    disp(information);

    pause(0.1);

    disp('HTM: initialization of parameters -- DONE');

end