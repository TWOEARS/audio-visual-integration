
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
bbs.setDataConnect('AuditoryFrontEndKS', 16000);

[models, files] = retrieveAudioClassifiers();

auditoryClassifiersKS = createAuditoryIdentityKS(bbs, models);

signalLevelKS = bbs.createKS('SignalLevelKS');

VIKS  = bbs.createKS('VisualIdentityKS', {bbs.robotConnect});

VSSKS = bbs.createKS('VisualStreamSegregationKS', {bbs.robotConnect});

VLKS = bbs.createKS('VisualLocationKS', {bbs.robotConnect});

AVFKS = bbs.createKS('AudioVisualFusionKS', {bbs.robotConnect});

HTMKS = bbs.createKS('HeadTurningModulationKS', {bbs});

FCKS = bbs.createKS('FocusComputationKS', {bbs, HTMKS});

ODKS = bbs.createKS('ObjectDetectionKS', {bbs, HTMKS});

dnnLocationKS = bbs.createKS('DnnLocationKS');

MOKS = bbs.createKS('MotorOrderKS', {bbs, bbs.robotConnect});


bbs.blackboardMonitor.bind({bbs.scheduler},...
                           {bbs.dataConnect},...
                           'replaceOld', 'AgendaEmpty');

bbs.blackboardMonitor.bind({bbs.dataConnect},...
                           {dnnLocationKS},...
                           'replaceOld');

% bbs.blackboardMonitor.bind({bbs.dataConnect},...
%                            {signalLevelKS},...
%                            'replaceOld' );

bbs.blackboardMonitor.bind({dnnLocationKS},...
                           {auditoryClassifiersKS{1}},...
                           'replaceOld' );

for iClassifier = 2:numel(auditoryClassifiersKS)
    bbs.blackboardMonitor.bind({auditoryClassifiersKS{iClassifier-1}},...
                           {auditoryClassifiersKS{iClassifier}},...
                           'replaceOld' );
end

bbs.blackboardMonitor.bind({auditoryClassifiersKS{end}},...
                           {VSSKS},...
                           'replaceOld' );

bbs.blackboardMonitor.bind({VSSKS},...
                           {VLKS},...
                           'replaceOld');

bbs.blackboardMonitor.bind({VLKS},...
                           {AVFKS},...
                           'replaceOld');

bbs.blackboardMonitor.bind({AVFKS},...
                           {VIKS},...
                           'replaceOld');

bbs.blackboardMonitor.bind({VIKS},...
                           {ODKS},...
                           'replaceOld');

bbs.blackboardMonitor.bind({ODKS},...
                           {HTMKS},...
                           'replaceOld' );
                       
bbs.blackboardMonitor.bind({HTMKS},...
                           {FCKS},...
                           'replaceOld');

bbs.blackboardMonitor.bind({FCKS},...
                           {MOKS},...
                           'replaceOld');


setInfo('duration', 60);

disp( 'Starting blackboard system.' );

bbs.run();
