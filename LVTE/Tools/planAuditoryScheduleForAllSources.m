
% This function generates a stimuli schedule for all sources in an
% environment.
% input:
%       env:        the environment
%       interval:   the silent interval between any two stimuli
%       ratio:      the ratio of wrong audio-visual stimuli
%                   pairs produces (compared to the acceptable ones)

function planAuditoryScheduleForAllSources(env, interval, ratio)
    nargin
    % the starting time
    t = 1.0 ;

    % loop until the simulation is finished
    while (t < env.duration)
    
        % select a random source ID
        sourceID = floor(rand()*(size(env.sources,1)-1))+2 ;

        % find source visual category
        visCat = env.sources{sourceID,1}.getVisualCategoryAtTime(t);

        % employ rand nr gen in order to decide if an acceptable
        % pair (ratio% probability) or a wrong pair ((1-ratio)20% probability)
        % will be used to instantiate
        useAcceptable = rand();
        if useAcceptable > 1-ratio
            % use wrong AV pair from file 'wrongAVPairs.xml'
            for j = 1:size(env.wrongAVPairs,1)
                if (strcmp(env.wrongAVPairs{j}{1},visCat))
                    stimulus = getStimulusForAuditoryLabel(env, env.wrongAVPairs{j}{2},1) ;
                    stimulus = strcat(env.pathToAudioFiles, stimulus) ;
                    % read sound file
                    [sig, fs] = audioread(stimulus);
                    % resample it to the SSR's sampling rate
                    s = resample(sig, env.SampleRate, fs) ;
                    % get stimulus length
                    length = size(s,1)/env.SampleRate ;

                    % generate schedule entry for the processed source
                    env.sources{sourceID}.auditorySchedule{size(...
                            env.sources{sourceID,1}.auditorySchedule,2)+1}=...
                                {t,'on',env.wrongAVPairs{j}{2},1,'wrong'};
                    env.sources{sourceID}.auditorySchedule{size(...
                        env.sources{sourceID,1}.auditorySchedule,2)+1}=...
                                {t+length,'off'};

                    % forward time according to the length of the stimulus
                    t = t+length ;
                    break ;
                end
            end

        else
            % use acceptable AV pair
            for j = 1:size(env.acceptableAVPairs,1)
                if (strcmp(env.acceptableAVPairs{j}{1},visCat))
                    stimulus = getStimulusForAuditoryLabel(env,env.acceptableAVPairs{j}{2},1) ;
                    stimulus = strcat(env.pathToAudioFiles,stimulus) ;
                    % read sound file
                    [sig, fs] = audioread(stimulus) ;
                    % resample it to the SSR's sampling rate
                    s = resample(sig, env.SampleRate, fs) ;
                    % get stimulus length
                    length = size(s,1)/env.SampleRate ;

                    % generate schedule entry for the processed source
                    env.sources{sourceID}.auditorySchedule{size(...
                        env.sources{sourceID,1}.auditorySchedule,2)+1}=...
                        {t,'on',env.acceptableAVPairs{j}{2},1,'acceptable'};
                    env.sources{sourceID}.auditorySchedule{size(...
                        env.sources{sourceID,1}.auditorySchedule,2)+1}=...
                        {t+length,'off'};

                    % forward time according to the length of the stimulus
                    t = t+length ;
                    break ;
                end
            end
        end
        % forward time according to the requested interval
        t = t+interval ;
        end
end

