



% An experimental setup to test the influence of audio-visual cue fusion on
% scenario analysis
 

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


N=8;
R=3;
for i=1:N
    name=sprintf('source%.3d',i);
    phi=i*360/N;
    x=R*cos(phi/180*pi)+environment.robotController.position(1);
    y=R*sin(phi/180*pi)+environment.robotController.position(2);
    environment.addSource(name,[x,y,2]);
end

% instantiate the SSR
environment.instantiateSSR();



% === Initialise and run model
disp( 'Building blackboard system...' );

bbs = BlackboardSystem(0);
bbs.setRobotConnect(environment);
bbs.setDataConnect('AuditoryFrontEndKS');


utteranceControlKS=bbs.createKS('UtteranceControlKS',{bbs.robotConnect});
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




bbs.blackboardMonitor.bind({bbs.scheduler},{updateEnvironmentKS},'replaceOld','AgendaEmpty');

bbs.blackboardMonitor.bind({updateEnvironmentKS}, {bbs.dataConnect}, 'replaceOld');

bbs.blackboardMonitor.bind({bbs.dataConnect}, {signalEnergyKS}, 'replaceOld' );
bbs.blackboardMonitor.bind({signalEnergyKS}, {utteranceControlKS}, 'replaceOld' );


disp( 'Starting blackboard system.' );
bbs.run();

