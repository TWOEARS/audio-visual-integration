%warning('off', 'all');
disp( 'Initializing Two!Ears, setting up binaural simulator...' );

% ================= %
% === HTM MODIF === %
% ================= %

addpath(genpath('~/AuditoryModel/TwoEars-1.2'));
% addpath(genpath('~/openrobots/lib/matlab'));

% client = genomix.client('jido-base:8080') ;
% bass = client.load('bass') ;
% basc2 = client.load('basc2') ;
% connection = basc2.connect_port('Audio', 'bass/Audio');

% if (~strcmp(connection.status,'done'))
%     error(connection.exception.ex);
% end

% === Initialize Two!Ears model and check dependencies
% startTwoEars();

% QR2matlab = client.load('QR2matlab') ;
% QR2matlab.connect_port('dataIn', '/visp_auto_tracker/code_message') ;
Jido = OdiInterface();

%robot = Robot() ;
% robot.initializeBass(bass, basc2) ;


% ================= %
% === HTM MODIF === %
% ================= %

% === Initialise and run model
disp( 'Building blackboard system...' );

bbs = BlackboardSystem(0);
bbs.setRobotConnect(Jido) ;
bbs.setDataConnect('AuditoryFrontEndKS');

folder = 'ClassifierData' ;
%d = dir(fullfile(folder, 'T*')) ;
d = dir(folder);
nb_files = numel(d) ;
auditoryClassifiersKS = cell(0) ;
model_name = cell(0) ;

%models = dir(fullfile(folder, d.name, '*.mat'));

%nb_models = numel(models);

%for iFile = 1:nb_files
for iFile = 1:nb_files
    if strfind(d(iFile).name, '.mat')
        %model = dir(fullfile(folder, d(iFile).name, '*.mat'));
        model = d(iFile).name(1:strfind(d(iFile).name, '.')-1);
    	auditoryClassifiersKS{end+1} = bbs.createKS('IdentityKS', {d(iFile).name, folder}) ;
        model_name{end+1} = model;
    end
end

signalLevelKS = bbs.createKS('SignalLevelKS') ;
visualIdentityKS = bbs.createKS('VisualIdentityKS', {bbs.robotConnect});

headTurningModulationKS = bbs.createKS('HeadTurningModulationKS', {bbs.robotConnect});
%updateEnvironmentKS 			= bbs.createKS('UpdateEnvironmentKS', {bbs.robotConnect});
%localizerKS = bbs.createKS('DnnLocationKS');
localizerKS = bbs.createKS('GmmLocationKS');

motorOrderKS = bbs.createKS('MotorOrderKS', {bbs.robotConnect});
% 
% bbs.blackboardMonitor.bind({bbs.scheduler},...
% 						   {updateEnvironmentKS},...
% 						   'replaceOld', 'AgendaEmpty');
% 
% bbs.blackboardMonitor.bind({updateEnvironmentKS},...
% 						   {bbs.dataConnect},...
% 						   'replaceOld');

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
						   {headTurningModulationKS},...
						   'replaceOld' );

bbs.blackboardMonitor.bind({headTurningModulationKS},...
                           {MotorOrderKS},...
                           'replaceOld');

% setappdata(0, 'audio_labels', model_name) ;
% setappdata(0, 'visual_labels', {'siren', 'baby', 'female', 'fire'}) ;

disp( 'Starting blackboard system.' );

bbs.run();

