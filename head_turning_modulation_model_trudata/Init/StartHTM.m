
clear all;
pause(1);
clear all;

disp( 'Initializing Two!Ears, setting up binaural simulator...' );

setupPaths();

global ROBOT_PLATFORM;
ROBOT_PLATFORM = 'JIDO';

if strcmp(ROBOT_PLATFORM, 'JIDO')
   % pathToGenomix = getGenomixPath();
   pathToGenomix = '/home/tforgue/openrobots/lib/matlab';
   Jido = JidoInterface(pathToGenomix);
elseif strcmp(ROBOT_PLATFORM, 'ODI')
   Jido = OdiInterface();
end

Jido.rotateHead(0, 'absolute');

% === Initialise and run model
disp( 'Building blackboard system...' );

bbs = BlackboardSystem(0);
bbs.setRobotConnect(Jido) ;
bbs.setDataConnect('AuditoryFrontEndKS', 16000);

[models, files] = retrieveAudioClassifiers();

auditoryClassifiersKS = createAuditoryIdentityKS(bbs, models);

signalLevelKS = bbs.createKS('SignalLevelKS');

VLKS = bbs.createKS('VisualLocationKS', {bbs.robotConnect});

VSSKS = bbs.createKS('VisualStreamSegregationKS', {bbs.robotConnect});

if strcmp(ROBOT_PLATFORM, 'JIDO')
   VIKS  = bbs.createKS('VisualIdentityKS', {bbs.robotConnect});
elseif strcmp(ROBOT_PLATFORM, 'ODI')
   VIKS  = bbs.createKS('VisualIdentityQRKS', {bbs.robotConnect});
end

% AVFKS = bbs.createKS('AudioVisualFusionKS', {bbs.robotConnect});

HTMKS = bbs.createKS('HeadTurningModulationKS', {bbs});

FCKS = bbs.createKS('FocusComputationKS', {bbs, HTMKS});

ODKS = bbs.createKS('ObjectDetectionKS', {bbs, HTMKS});

dnnLocationKS = bbs.createKS('DnnLocationKS');
%dnnLocationKS = bbs.createKS('DnnLocationKS', {'MCT-DIFFUSE-FRONT'});
%localisationDecisionKS = bbs.createKS('LocalisationDecisionKS', {false, 0.5});

MOKS = bbs.createKS('MotorOrderKS', {bbs, bbs.robotConnect});

<<<<<<< HEAD
EMKS = bbs.createKS('EnvironmentalMapKS', {bbs, HTMKS})
=======
EMKS = bbs.createKS('EnvironmentalMapKS', {bbs, HTMKS});
>>>>>>> tmp


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
%                            {localisationDecisionKS},...
%                            'replaceOld');
% bbs.blackboardMonitor.bind({localisationDecisionKS},...


for iClassifier = 2:numel(auditoryClassifiersKS)
    bbs.blackboardMonitor.bind({auditoryClassifiersKS{iClassifier-1}},...
                           {auditoryClassifiersKS{iClassifier}},...
                           'replaceOld' );
end

% if strcmp(ROBOT_PLATFORM, 'JIDO')
   bbs.blackboardMonitor.bind({auditoryClassifiersKS{end}},...
                              {VSSKS},...
                              'replaceOld' );

   bbs.blackboardMonitor.bind({VSSKS},...
                              {VLKS},...
                              'replaceOld');
% elseif strcmp(ROBOT_PLATFORM, 'ODI')
%    bbs.blackboardMonitor.bind({auditoryClassifiersKS{end}},...
%                               {VLKS},...
%                               'replaceOld' );
% end

% bbs.blackboardMonitor.bind({VLKS},...
%                            {AVFKS},...
%                            'replaceOld');
bbs.blackboardMonitor.bind({VLKS},...
                           {VIKS},...
                           'replaceOld');

% bbs.blackboardMonitor.bind({AVFKS},...
%                            {VIKS},...
%                            'replaceOld');

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
bbs.blackboardMonitor.bind({MOKS},...
                           {EMKS},...
                           'replaceOld');

disp( 'Starting blackboard system.' );

global CHANGE_SCENARIO;
CHANGE_SCENARIO = true;

bbs.run();
