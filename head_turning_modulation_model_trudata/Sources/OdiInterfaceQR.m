classdef OdiInterfaceQR < handle
    %JIDOINTERFACE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess = public, SetAccess = private)
        BlockSize               % Block size used by the audio stream 
                                % server in samples.
        SampleRate              % Sample rate of the audio stream server 
                                % in Hz.
        AzimuthMax              % Maximum azimuthal look direction of the 
                                % KEMAR head in degrees.
        AzimuthMin              % Minimum azimuthal look direction of the
                                % KEMAR head in degrees.
        LengthOfSimulation      % TODO: How to integrate this?
        
    end
    
    properties (Access = public)
        client                  % Handle to the genomix client.
        kemar                   % KEMAR control interface.
        jido                    % Jido interface.
        bass                    % Interface to the audio stream server.
        qr_vision
        finished  %% added to stop bbs.run()
    end
    
    methods (Access = public)
        function obj = OdiInterfaceQR()
            pathToGenomix = '~/openrobots/lib/matlab';
            addpath(genpath(pathToGenomix));
            
            % Set up genomix client
            odi_base = '192.168.11.100:8080';
            obj.client = genomix.client(odi_base);
            %obj.client = genomix.client('jido-base:8080');
            
            % Load KEMAR module
            %obj.kemar = obj.client.load('kemar');
            
            % Load JIDO module
            obj.jido = obj.client.load('sendPosition'); % Il faut lier les ports
            
            % Load BASS module
            obj.bass = obj.client.load('bass');
            
            obj.qr_vision = obj.client.load('QR2matlab');
            
            currentPositionPort = obj.jido.connect_port('currentPosition', 'currentPosition');
            goalStatusArray = obj.jido.connect_port('GoalStatus', 'move_base/status');
            obj.qr_vision.connect_port('messageIn', '/visp_auto_tracker/code_message' );
            obj.qr_vision.connect_port('poseIn', '/visp_auto_tracker/object_position' );
               
            hardware        = 'hw:2,0';
            obj.SampleRate  = 44100;
            nFramesPerChunk = 2205;
            nChunksOnPort   = 20*0.5;
            obj.bass.Acquire('-a', hardware, obj.SampleRate, nFramesPerChunk, nChunksOnPort);
            
            QR2 = obj.qr_vision.Publish('-a');
            
            % Get BASS status info
            % audioObj = obj.bass.Audio(); % A voir
            obj.BlockSize = nFramesPerChunk * nChunksOnPort;
            
            % Get KEMAR properties
            % kemarState = obj.kemar.currentState();
            % obj.AzimuthMax = kemarState.currentState.maxLeft;
            % obj.AzimuthMin = kemarState.currentState.maxRight;
            obj.finished = false; %% init a false
        end
        
%         function configureAudioStreamServer(obj, sampleRate, frameSize, ...
%                 bufferSizeSec)
%             % CONFIGUREAUDIOSTREAMSERVER
%             
%             % Check input arguments
%             p = inputParser();
%             
%             p.addRequired('SampleRate', @(x) validateattributes(x, ...
%                 {'numeric'}, {'scalar', 'real'}));
%             p.addRequired('FrameSize', @(x) validateattributes(x, ...
%                 {'numeric'}, {'scalar', 'integer'}));
%             p.addRequired('BufferSizeSec', @(x) validateattributes(x, ...
%                 {'numeric'}, {'scalar', 'real'}));
%             p.parse(sampleRate, frameSize, bufferSizeSec);
%             
%             % Compute number of frames per chunk
%             numFramesPerChunk = ceil(p.Results.BufferSizeSec * ...
%                 p.Results.SampleRate / p.Results.FrameSize);
%             
%             % Setup audio stream server
%             obj.bass.Acquire('-a', 'hw:1,0', p.Results.SampleRate, ...
%                 p.Results.FrameSize, numFramesPerChunk);
%             
%             % Update block size
%             obj.BlockSize = round(numFramesPerChunk * p.Results.FrameSize);
%         end


        function [earSignals, signalLengthSec] = getSignal(obj, ...
                timeDurationSec)
            % GETSIGNAL This function acquires binaural signals from the
            %   robot via the binaural audio stream server.
            
            % Read audio buffer
            audioBuffer = obj.bass.Audio();
            
            % Get binaural signals
            % Sclaing factor estimated empirically
            earSignals = [cell2mat(audioBuffer.Audio.left)' ./ (2^31), ...
                0.7612 .* (cell2mat(audioBuffer.Audio.right)' ./ (2^31))];
            
            % Get default buffer size of the audio stream server
            bufferSize = size(earSignals, 1);
            
            % Convert desired chunk length into samples
            if nargin == 2
                chunkLength = round(timeDurationSec * obj.SampleRate);
            else
                chunkLength = bufferSize;
            end
            
            % Check if chunk length is smaller than buffer length
            if chunkLength > bufferSize
                error(['Desired chunk length exceeds length of the ', ...
                    'audio buffer.']);
            end

            % Get corresponding signal chunk
            earSignals = earSignals(bufferSize - chunkLength + 1 : end, :);
            
            % Get signal length
            signalLengthSec = length(earSignals) / ...
                audioBuffer.Audio.sampleRate;

            sig = getappdata(0, 'sig');
            sig = [sig ; earSignals];
            setappdata(0, 'sig', sig);
            
        end
        
        function output = getQR (obj)
            
            output = obj.qr_vision.dataOut();
            output = output.dataOut().message;
            
        end
        
        function moveRobot(obj, posX, posY, theta, varargin)
            % MOVEROBOT
            
            % Check input arguments
            p = inputParser();
            defaultMode = 'relative';
            expectedModes = {'absolute', 'relative'};
            
            p.addRequired('PosX', @(x) validateattributes(x, ...
                {'numeric'}, {'scalar', 'real'}));
            p.addRequired('PosY', @(x) validateattributes(x, ...
                {'numeric'}, {'scalar', 'real'}));
            p.addRequired('Theta', @(x) validateattributes(x, ...
                {'numeric'}, {'scalar', 'real'}));
            p.addOptional('Mode', defaultMode, ...
                @(x) any(validatestring(x, expectedModes)));
            p.parse(posX, posY, theta, varargin{:});
            
            % Execute motion command depending on selected mode
            switch p.Results.Mode
                case 'absolute'
                    obj.jido.moveAbsolutePosition('-a', '/map', ...
                        p.Results.PosX, p.Results.PosY, p.Results.Theta);
                case 'relative'
                    obj.jido.moveRelativePosition('-a', '/map', ...
                        p.Results.PosX, p.Results.PosY, p.Results.Theta);
                otherwise
                    error('Mode not supported.');
            end
        end
        
        function rotateHead(obj, angle, varargin)
            % ROTATEHEAD
            
            % Check input arguments
            p = inputParser();
            defaultMode = 'relative';
            expectedModes = {'absolute', 'relative'};
            
            p.addRequired('Angle', @(x) validateattributes(x, ...
                {'numeric'}, {'scalar', 'real'}));
            p.addOptional('Mode', defaultMode, ...
                @(x) any(validatestring(x, expectedModes)));
            p.parse(angle, varargin{:});
            
            % TODO: Prevent head from exceeding azimuth limits
            
            % Execute motion command depending on selected mode
            switch p.Results.Mode
                case 'absolute'
                    obj.kemar.MoveAbsolutePosition(p.Results.Angle);
                case 'relative'
                    obj.kemar.MoveRelativePosition(p.Results.Angle);
                otherwise
                    error('Mode not supported.');
            end
        end
        
        function azimuth = getCurrentHeadOrientation(obj)
            % GETCURRENTHEADORIENTATION
            
            % Get current state of the KEMAR head
%             kemarState = obj.kemar.currentState();
            
            % Get head angle
%             azimuth = kemarState.currentState.position;
            % --- EDIT --- %
            navig = obj.jido.NavigationState();
            pos = navig.NavigationState.position;
            azimuth = pos.orientation;
            % --- EDIT --- %
        end
        
        function delete(obj)
            % DELETE Destructor
            
            % Shut down the audio stream server
            delete(obj.bass);
            clear obj.bass;
            
            % Disconnect and shut down Jido interface
            delete(obj.jido);
            clear obj.jido;
            
            % Disconnect and shut down KEMAR interface
            delete(obj.kemar);
            clear obj.kemar;
            
            % Shut down genomix client
            delete(obj.client);
            clear obj.client;
        end
        
        function result = isFinished(obj)
            % Just live with this...
            %result = false;
            result = obj.finished;
        end
    end
end
