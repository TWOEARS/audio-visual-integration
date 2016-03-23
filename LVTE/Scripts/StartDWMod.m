




 

%warning('off', 'all');
disp( 'Initializing Two!Ears, setting up binaural simulator...' );

% === Initialize Two!Ears model and check dependencies
startTwoEars();

environment=Environment();

environment.setPathToAudioFiles('/home/user/TwoEars-1.0.1/BinauralSimulator/tmp/sound_databases/IEEE_AASP/');
environment.readAuditoryCategories();
environment.readVisualCategories();
environment.createAVPairs();



environment.setRoomDimensions(10,10,2.4);
environment.initializeRobot(5,5,2);


% define scenario duration
scenarioDuration=60.0;

environment.setScenarioDuration(scenarioDuration);

% add silence for SSR
environment.addSilentSource();

% set up 3 source positions
environment.addSource('Source1',[3,3,2]);
environment.addSource('Source2',[7,7,2]);
environment.addSource('Source3',[7,5,2]);



% define visual schedules for sources
environment.getSource('Source1').setVisualSchedule(  {{0.0,'person',001}});
environment.getSource('Source2').setVisualSchedule(  {{0.0,'door',002}});
environment.getSource('Source3').setVisualSchedule(  {{0.0,'siren',001}});

environment.planAuditoryScheduleForAllSources(scenarioDuration);




% % define auditory schedules for sources
% environment.getSource('Source1').setAuditorySchedule(  {{0.0,'on,cont.','speech',001};...
%                                                 {2.0,'off'}
%                                                 {2.5,'on,cont.','speech',001};...
%                                                 {4,'off'}});
% 
%                                             
% environment.getSource('Source2').setAuditorySchedule(  {{5.0,'on,cont.','alert',002};...
%                                                 {8.0,'off'}});
% 
% 
% 
% environment.getSource('Source3').setAuditorySchedule(  {{9.0,'on,cont.','knock',001};...
%                                                 {11.0,'off'}});
                                            
                                            

% generate auditory ground truth for display
environment.generateAuditoryGroundTruthVector();

% instantiate the SSR
environment.instantiateSSR();



% === Initialise and run model
disp( 'Building blackboard system...' );

bbs = BlackboardSystem(0);
bbs.setRobotConnect(environment);
bbs.setDataConnect('AuditoryFrontEndKS');


% for i = 1 : numel( idModels )
%      auditoryIdentityKSs{i} = bbs.createKS('AuditoryIdentityModKS', {idModels(i).name, idModels(i).dir});
%      auditoryIdentityKSs{i}.setInvocationFrequency(10);
%  end
 

signalEnergyKS=bbs.createKS('SignalEnergyKS');
auditorySpeechClassifierKS=bbs.createKS('AuditoryIdentityModKS', {'speech','Training.2015.07.24.01.20.40.054'});
auditoryKnockClassifierKS=bbs.createKS('AuditoryIdentityModKS', {'knock','Training.2015.07.24.01.18.1.271'});
auditoryAlertClassifierKS=bbs.createKS('AuditoryIdentityModKS', {'alert','Training.2015.10.14.14.46.11.5842'});
auditoryClearthroatClassifierKS=bbs.createKS('AuditoryIdentityModKS', {'clearthroat','Training.2015.07.24.00.23.42.772'});
updateEnvironmentKS=bbs.createKS('UpdateEnvironmentKS',{bbs.robotConnect});
auditoryDisplayKS=bbs.createKS('VisualDisplayKS',{bbs.robotConnect});
visualDisplayKS=bbs.createKS('AuditoryDisplayKS',{bbs.robotConnect});
visualIdentityKS = bbs.createKS('VisualIdentityKS', {bbs.robotConnect});
multimodalFusionKS = bbs.createKS('MultimodalFusionKS', {bbs.robotConnect});
dWModKS = bbs.createKS('DWModKS', {bbs.robotConnect});


% activate in later stages?!

% locationKS=bbs.createKS('LocationModKS',{'default'});
% onfusionKS=bbs.createKS('ConfusionModKS');
% rotationKS=bbs.createKS('RotationModKS',{bbs.robotConnect});
% turnToSourceKS=bbs.createKS('TurnToSourceKS',{bbs.robotConnect});


bbs.blackboardMonitor.bind({bbs.scheduler},{updateEnvironmentKS},'replaceOld','AgendaEmpty');

bbs.blackboardMonitor.bind({updateEnvironmentKS}, {bbs.dataConnect}, 'replaceOld');

bbs.blackboardMonitor.bind({bbs.dataConnect}, {signalEnergyKS}, 'replaceOld' );
bbs.blackboardMonitor.bind({signalEnergyKS}, {visualIdentityKS}, 'replaceOld' );
% the following sequential bindings are unnecessarily complicated. Has to be addressed in a new
% version?! (Ideally, the MultimodalKusionKS would have to wait for
% 'completed' signals from all auditory classifiers before being launched.)
bbs.blackboardMonitor.bind({visualIdentityKS},{auditorySpeechClassifierKS}, 'replaceOld' );
bbs.blackboardMonitor.bind({auditorySpeechClassifierKS},{auditoryKnockClassifierKS}, 'replaceOld' );
bbs.blackboardMonitor.bind({auditoryKnockClassifierKS},{auditoryClearthroatClassifierKS}, 'replaceOld' );

bbs.blackboardMonitor.bind({auditoryClearthroatClassifierKS},{auditoryAlertClassifierKS}, 'replaceOld' );
bbs.blackboardMonitor.bind({auditoryAlertClassifierKS},{multimodalFusionKS}, 'replaceOld' );
bbs.blackboardMonitor.bind({multimodalFusionKS},{dWModKS}, 'replaceOld' );


bbs.blackboardMonitor.bind({updateEnvironmentKS},{visualDisplayKS}, 'replaceOld');
bbs.blackboardMonitor.bind({updateEnvironmentKS},{auditoryDisplayKS}, 'replaceOld');


% activate in later stages?!
%bbs.blackboardMonitor.bind({bbs.dataConnect},{energyKS}, 'replaceOld');
%bbs.blackboardMonitor.bind({bbs.dataConnect}, {locationKS}, 'replaceOld');
%bbs.blackboardMonitor.bind({locationKS}, {rotationKS}, 'replaceOld');


disp( 'Starting blackboard system.' );
bbs.run();

