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
						 'obs_struct'	   , [],...
						 'statistics'	   , [],...
                         'thr_theta'       , 10,...
                         'duration'        , 0 ...
                         );


    path_to_folder = '../../examples/attention_jido';

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

    % =========================================================================== %
    % =========================================================================== %
    % =========================================================================== %

    % --- Retrieve audiovisual pairs from 'AVPairs.xml' file
    % --- 'AVPairs.xml' can be edited
    % [AVPairs, audio_labels, visual_labels] = retrieveAudioVisualLabels();

    [audio_labels, file_names] = retrieveAudioIdentityModels();

    % visual_labels = retrieveVisualIdentityModels(htm);
    % visual_labels = {'siren', 'male', 'female', 'door', 'drawer', 'phone', 'book'};
    visual_labels = {'fake6', 'mag0', 'mag2', 'mag1', 'fake7', 'fake5', 'fake9', 'fake8', 'mag3', 'fake4'};
    % visual_labels = {'siren', 'dog', 'female', 'baby', 'engine', 'door', 'male', 'phone', 'female'};

    information.audio_labels    = audio_labels;
    information.nb_audio_labels = numel(information.audio_labels);

    information.visual_labels    = visual_labels;
    information.nb_visual_labels = numel(information.visual_labels);

    % information.AVPairs    = AVPairs;
    % information.nb_AVPairs = numel(information.AVPairs);

    information.nb_labels = information.nb_audio_labels + information.nb_visual_labels;

    information.obs_struct = struct('label'     , 'none_none',...
                                    'perf'      , 0,...
                                    'nb_goodInf', 0,...
                                    'nb_inf'    , 0,...
                                    'cpt'       , 0,...
                                    'proba'     , 0);
                                
    information.statistics = struct('max'     , [], ...
                                    'max_mean', [],...
                                    'mfi'     , [],...
                                    'mfi_mean', [],...
                                    'alpha_a' , 0,...
                                    'alpha_v' , 0,...
                                    'beta_a'  , 0,...
                                    'beta_v'  , 0,...
                                    'c'       , [],...
                                    'vec'     , [0 :0.1: 1]...
                                   );

    information.plot_fcn = {'focus'         ,...
                            'goodClassif'   ,...
                            'goodClassifObj',...
                            'shm'           ,...
                            'hits'          ,...
                            'headMovements' ,...
                            'statistics'     ...
                            };

    % information.scenario = struct('idx'       , 1        ,...
    %                               'scene'     , {{scene}},...
    %                               'unique_idx', {scene}   ...
    %                              );

    % [information.nb_objects, information.nb_steps] = adjustLength(nb_steps);
    
    % s = information.cpt_silence + information.cpt_object;
    % nb_objects = ceil(nb_steps / s);
    
    % information.nb_steps = nb_objects * s;

    % information.nb_objects = nb_objects;

    % information.cpt_object = 0;
    % information.cpt_silence = 1;
    % information.cpt_simulation = 0;

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