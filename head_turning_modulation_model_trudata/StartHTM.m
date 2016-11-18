
% clear all;
% pause(1);
% clear all;

%disp( 'Initializing Two!Ears, setting up binaural simulator...' );

% === TO BE CHANGED BY A OMRE ELEGANT WAY TO INCLUDE THE NEEDED FOLDERS... === %
%p = '/home/twoears/AuditoryModel/TwoEars-1.2/';
p = '/home/tforgue/mystuff/work/laas/twoears/';
addpath(genpath(p));
% addpath(genpath([p, 'audio-visual-integration/head_turning_modulation_model_trudata']));
% addpath(genpath([p, 'blackboard-system']));
% addpath(genpath([p, 'main']));
% addpath(genpath([p, 'auditory-front-end']));
% addpath(genpath([p, 'examples']));

rmpath(genpath([p, 'audio-visual-integration/head_turning_modulation_model_simdata']));
rmpath(genpath([p, 'audio-visual-integration/LVTE']));
rmpath(genpath([p, 'TwoEars']));
% addpath(genpath(p));
% === TO BE CHANGED BY A MORE ELEGANT WAY TO INCLUDE THE NEEDED FOLDERS... === %

pathToGenomix = getGenomixPath();
% --- OdiInterface: class making the interface between the robot and the system
Jido = JidoInterface(pathToGenomix);

% === Initialise and run model
disp( 'Building blackboard system...' );

bbs = BlackboardSystem(0);
bbs.setRobotConnect(Jido) ;
bbs.setDataConnect('AuditoryFrontEndKS');

[models, files] = retrieveAudioClassifiers();

auditoryClassifiersKS = createAuditoryIdentityKS(bbs, models);

signalLevelKS = bbs.createKS('SignalLevelKS');

visualIdentityKS = bbs.createKS('VisualIdentityKS', {bbs.robotConnect});

visualLocationKS = bbs.createKS('VisualLocationKS', {bbs.robotConnect});

visualStreamSegregationKS = bbs.createKS('VisualStreamSegregationKS', {bbs.robotConnect});

audioVisualFusionKS = bbs.createKS('AudioVisualFusionKS', {bbs.robotConnect});

headTurningModulationKS = bbs.createKS('HeadTurningModulationKS', {bbs});

focusComputationKS = bbs.createKS('FocusComputationKS', {bbs, headTurningModulationKS});

objectDetectionKS = bbs.createKS('ObjectDetectionKS', {bbs, headTurningModulationKS});

dnnLocationKS = bbs.createKS('DnnLocationKS');

motorOrderKS = bbs.createKS('MotorOrderKS', {bbs, bbs.robotConnect});


bbs.blackboardMonitor.bind({bbs.scheduler},...
                           {bbs.dataConnect},...
                           'replaceOld', 'AgendaEmpty');

bbs.blackboardMonitor.bind({bbs.dataConnect},...
                           {dnnLocationKS},...
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
                           {visualStreamSegregationKS},...
                           'replaceOld' );

bbs.blackboardMonitor.bind({visualStreamSegregationKS},...
                           {visualLocationKS},...
                           'replaceOld');

bbs.blackboardMonitor.bind({visualLocationKS},...
                           {audioVisualFusionKS},...
                           'replaceOld');

bbs.blackboardMonitor.bind({audioVisualFusionKS},...
                           {visualIdentityKS},...
                           'replaceOld');

bbs.blackboardMonitor.bind({visualIdentityKS},...
                           {objectDetectionKS},...
                           'replaceOld');

bbs.blackboardMonitor.bind({objectDetectionKS},...
                           {headTurningModulationKS},...
                           'replaceOld' );
                       
bbs.blackboardMonitor.bind({headTurningModulationKS},...
                           {focusComputationKS},...
                           'replaceOld');

bbs.blackboardMonitor.bind({focusComputationKS},...
                           {motorOrderKS},...
                           'replaceOld');


setInfo('duration', 60);

disp( 'Starting blackboard system.' );

bbs.run();
