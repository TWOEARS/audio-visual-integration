
clear all;
pause(1);
clear all;

disp( 'Initializing Two!Ears, setting up binaural simulator...' );

addpath(genpath('~/Dev/TwoEars-1.2'));
rmpath(genpath('~/Dev/TwoEars-1.2/audio-visual-integration/head_turning_modulation_model_simulated_data'));
rmpath(genpath('~/Dev/TwoEars-1.2/audio-visual-integration/LVTE'));

Jido = OdiInterface();

% === Initialise and run model
disp( 'Building blackboard system...' );

bbs = BlackboardSystem(0);
bbs.setRobotConnect(Jido) ;
bbs.setDataConnect('AuditoryFrontEndKS');


[models, files] = retrieveAudioClassifiers();

auditoryClassifiersKS = createAuditoryIdentityKS(bbs, models, files);

signalLevelKS = bbs.createKS('SignalLevelKS');

visualIdentityKS = bbs.createKS('VisualIdentityQRKS', {bbs.robotConnect});

headTurningModulationKS = bbs.createKS('HeadTurningModulationKS', {bbs});

htmFocusKS = bbs.createKS('HTMFocusKS', {bbs, headTurningModulationKS});

objectDetectionKS = bbs.createKS('ObjectDetectionKS', {bbs, headTurningModulationKS});

localizerKS = bbs.createKS('GmmLocationKS');

motorOrderKS = bbs.createKS('MotorOrderKS', {bbs.robotConnect});


bbs.blackboardMonitor.bind({bbs.scheduler},...
                           {bbs.dataConnect},...
                           'replaceOld', 'AgendaEmpty');

bbs.blackboardMonitor.bind({bbs.dataConnect},...
                           {localizerKS},...
                           'replaceOld');

bbs.blackboardMonitor.bind({bbs.dataConnect},...
                           {signalLevelKS},...
                           'replaceOld' );

bbs.blackboardMonitor.bind({signalLevelKS},...
                           {auditoryClassifiersKS{1}},...
                           'replaceOld' );

for iClassifier = 2:numel(auditoryClassifiersKS)
    bbs.blackboardMonitor.bind({auditoryClassifiersKS{iClassifier-1}},...
                           {auditoryClassifiersKS{iClassifier}},...
                           'replaceOld' );
end

bbs.blackboardMonitor.bind({auditoryClassifiersKS{end}},...
                           {visualIdentityKS},...
                           'replaceOld' );

bbs.blackboardMonitor.bind({visualIdentityKS},...
                           {objectDetectionKS},...
                           'replaceOld' );        

bbs.blackboardMonitor.bind({objectDetectionKS},...
                           {headTurningModulationKS},...
                           'replaceOld' );
                       
bbs.blackboardMonitor.bind({headTurningModulationKS},...
                           {htmFocusKS},...
                           'replaceOld');

bbs.blackboardMonitor.bind({htmFocusKS},...
                           {motorOrderKS},...
                           'replaceOld');


setInfo('duration', 60);

disp( 'Starting blackboard system.' );

bbs.run();
