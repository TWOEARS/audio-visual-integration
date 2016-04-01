

% This function generates the auditory ground truth (GT) vector used for 
% visualization purposes
% input:
%       env:        the environment

function generateAuditoryGroundTruthVector(env)
    % allocate memory
    env.auditoryGTVector=cell(size(env.sources,1),1);
    % loop over all sources, neglecting the 'silent' source at index 1
    for i=2:size(env.sources,1)                
        % set up named entry in the GT vector
        env.auditoryGTVector{i}={env.sources{i,1}.name};
        % scan the auditory schedule of the processed source
        for j=1:size(env.sources{i,1}.auditorySchedule,2)   
            % IFF the current schedule entry is an 'on' entry, append the
            % GT vector with the corresponding onset information            
            if ~isempty(strfind(...
                    env.sources{i,1}.auditorySchedule{j}{2},'on'))
                try
                    % if the try works, the auditory schedule was probably
                    % automatically generated OR the experimenter created
                    % it manually, and added the acceptable/wrong cognitive
                    % information required for setting up a correct GT
                    % vector
                    env.auditoryGTVector{i}=[...
                        env.auditoryGTVector{i},{...
                        env.sources{i,1}.auditorySchedule{j}{1},...
                        env.sources{i,1}.auditorySchedule{j}{3},...
                        env.sources{i,1}.auditorySchedule{j}{5}}];                        
                catch
                    % if the try failed, generate an appropriate 'dummy'
                    % entry for the cognitive acceptable/wrong field
                    env.auditoryGTVector{i}=[...
                        env.auditoryGTVector{i},...
                        {env.sources{i,1}.auditorySchedule{j}{1},...
                        env.sources{i,1}.auditorySchedule{j}{3},...
                        'acceptable'}];                                                
                end
            end
            % IFF the current schedule entry is an 'off' entry, append the
            % GT vector with the corresponding offset information
            if ~isempty(strfind(...
                env.sources{i,1}.auditorySchedule{j}{2},'off'))
                
                env.auditoryGTVector{i}=[env.auditoryGTVector{i},...
                        {env.sources{i,1}.auditorySchedule{j}{1},''}];                        
            end
        end                
    end
end
