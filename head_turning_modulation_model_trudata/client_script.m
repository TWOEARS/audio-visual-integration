p = '/home/bcl/AuditoryModel/TwoEars-1.2/';
addpath(genpath(p));
rmpath(genpath([p, 'audio-visual-integration/head_turning_modulation_model_simdata']));
rmpath(genpath([p, 'audio-visual-integration/LVTE']));
rmpath(genpath([p, 'TwoEars']));

pathToGenomix = getGenomixPath();
userpath(pathToGenomix)
odi_base = '192.168.11.100:8080';

client = genomix.client(odi_base);

kemar = client.load('kemar')
kemar.Homing()

jido = client.load('sendPosition');
currentPositionPort = jido.connect_port('currentPosition', 'currentPosition');
goalStatusArray = jido.connect_port('GoalStatus', 'move_base/status');

qr_vision = client.load('QR2matlab');
qr_vision.connect_port('messageIn', '/visp_auto_tracker/code_message' );
qr_vision.connect_port('poseIn', '/visp_auto_tracker/object_position' );
QR2 = qr_vision.Publish('-a');


bass = client.load('bass');
hardware        = 'hw:2,0';
SampleRate  = 44100;
nFramesPerChunk = 2205;
nChunksOnPort   = 20*0.5;
bass.Acquire('-a', hardware, SampleRate, nFramesPerChunk, nChunksOnPort);

kemarState = kemar.currentState();
maxLeft = kemarState.currentState.maxLeft;
maxRight = kemarState.currentState.maxRight;

[maxHeadLeft, maxHeadRight] = jido.getHeadTurnLimits();
maxHeadLeft = maxHeadLeft - rem(maxHeadLeft, 5);
maxHeadRight = maxHeadRight - rem(maxHeadRight, 5);
headOrientation = getCurrentHeadOrientation();