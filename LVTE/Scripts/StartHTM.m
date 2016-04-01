%warning('off', 'all');
disp( 'Initializing Two!Ears, setting up binaural simulator...' );

% === Initialize Two!Ears model and check dependencies
startTwoEars();

environment=Environment();

environment.pathToAudioFiles = ['/Users/bcl/SciWork/Dev/TwoEars_1.0/BinauralSimulator/tmp/sound_databases/IEEE_AASP/'] ;

environment.roomDims = [10, 10, 2.4] ;
environment.robotController.position = [5, 5, 0];

% define scenario duration
environment.duration = 60.0;

% add silence for SSR
% environment.addSilentSource();

% set up 3 source positions
environment.addSource('Source1', [3.0, 3.0, 2.0]);
environment.addSource('Source2', [7.5, 7.0, 2.0]);
environment.addSource('Source3', [4.0, 6.5, 2.0]);
% environment.addSource('Source4', [5.0, 8.0, 2.0]);
% environment.addSource('Source4', [6.0, 2.0, 2.0]);

% define visual schedules for sources
environment.getSource('Source1').setVisualSchedule({{0.0, 'person', 001}});
environment.getSource('Source2').setVisualSchedule({{0.0, 'door', 001}});
% environment.getSource('Source4').setVisualSchedule({{0.0, 'person2' , 002}});
environment.getSource('Source3').setVisualSchedule({{0.0, 'siren', 001}});
% environment.getSource('Source5').setVisualSchedule({{0.0, 'female' , 001}});

environment.planAuditoryScheduleForAllSources(60) ;

% instantiate the SSR
environment.instantiateSSR();

% === Initialise and run model
disp( 'Building blackboard system...' );

bbs = BlackboardSystem(0);
bbs.setRobotConnect(environment);
bbs.setDataConnect('AuditoryFrontEndKS');

signalLevelKS = bbs.createKS('SignalLevelKS') ;

% folder = '/Users/bcl/SciWork/Dev/twoears-wp4/Cognition/LVTE/ClassifierData' ;
% d = dir(fullfile(folder, 'T*')) ;
% nb_files = numel(d) ;
% auditoryClassifiersKS = cell(0) ;
% model_name = cell(1, numel(d)) ;

% for iFile = 1:nb_files
% 	model = dir(fullfile(folder, d(iFile).name, '*.mat')) ;
% 	model = model.name(1:strfind(model.name, '.')-1) ;
% 	auditoryClassifiersKS{iFile} = bbs.createKS('AuditoryIdentityKS', {model, d(iFile).name}) ;
% 	model_name{iFile} = model ;
% end

auditorySpeechClassifierKS	    = bbs.createKS('AuditoryIdentityKS', {'speech', 'Training.2015.07.24.01.20.40.054'} );
auditoryKnockClassifierKS  		= bbs.createKS('AuditoryIdentityKS', {'knock' , 'Training.2015.07.24.01.18.1.271'}  );
auditoryAlertClassifierKS		= bbs.createKS('AuditoryIdentityKS', {'alert' , 'Training.2015.10.14.14.46.11.5842'});
visualIdentityKS 				= bbs.createKS('VisualIdentityKS'   , {bbs.robotConnect});

updateEnvironmentKS 			= bbs.createKS('UpdateEnvironmentKS', {bbs.robotConnect});

visualDisplayKS 				= bbs.createKS('VisualDisplayKS'    , {bbs.robotConnect});
auditoryDisplayKS 				= bbs.createKS('AuditoryDisplayKS'  , {bbs.robotConnect});
headTurningModulationKS 		= bbs.createKS('HeadTurningModulationKS', {bbs.robotConnect});

localizerKS 				    = bbs.createKS('LocalizerKS'	    , {'default'});


bbs.blackboardMonitor.bind({bbs.scheduler},...
						   {updateEnvironmentKS},...
						   'replaceOld', 'AgendaEmpty');

bbs.blackboardMonitor.bind({updateEnvironmentKS},...
						   {bbs.dataConnect},...
						   'replaceOld');

bbs.blackboardMonitor.bind({bbs.dataConnect},...
						   {localizerKS},...
						   'replaceOld');

bbs.blackboardMonitor.bind({bbs.dataConnect},...
						   {signalLevelKS},...
                           'replaceOld' );

bbs.blackboardMonitor.bind({signalLevelKS},...
						   {visualIdentityKS},...
                           'replaceOld' );

bbs.blackboardMonitor.bind({visualIdentityKS},...
                           {auditorySpeechClassifierKS},...
                           'replaceOld' );

% bbs.blackboardMonitor.bind({visualIdentityKS},...
%                            {auditoryClassifiersKS{1}},...
%                            'replaceOld' );

% for iClassifier = 2:numel(auditoryClassifiersKS)
% 	bbs.blackboardMonitor.bind({auditoryClassifiersKS{iClassifier-1}},...
%                            {auditoryClassifiersKS{iClassifier}},...
%                            'replaceOld' );
% end
% bbs.blackboardMonitor.bind({auditoryClassifiersKS{end}},...
% 						   {headTurningModulationKS},...
% 						   'replaceOld' );

bbs.blackboardMonitor.bind({auditorySpeechClassifierKS},...
                           {auditoryKnockClassifierKS},...
                           'replaceOld' );
                       
bbs.blackboardMonitor.bind({auditoryKnockClassifierKS},...
                           {auditoryAlertClassifierKS},...
                           'replaceOld' );

bbs.blackboardMonitor.bind({auditoryAlertClassifierKS},...
                           {headTurningModulationKS},...
                           'replaceOld' );


bbs.blackboardMonitor.bind({updateEnvironmentKS},...
						   {auditoryDisplayKS},...
						   'replaceOld') ;
bbs.blackboardMonitor.bind({updateEnvironmentKS},...
						   {visualDisplayKS},...
						   'replaceOld') ;

disp( 'Starting blackboard system.' );
bbs.run();

