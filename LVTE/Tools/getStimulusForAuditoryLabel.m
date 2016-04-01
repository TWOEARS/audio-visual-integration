
% This function returns a stimulus (.wav file id) for a given instance
% of a given category
% 
% input:
%       env:        the environment
%       category:   the category from which the instance should be taken
%       instance:   the actual instance index to retrieve the .wav file id
%                   for

function stimulus=getStimulusForAuditoryLabel(env,category,instance)
    % scan all auditory instances
    for i=1:size(env.auditoryInstancesList,1)
        % iff the category matches the processed instances category
        if(strcmp(env.auditoryInstancesList(i,1),category))
            % and iff the instance id matches the currently processed
            % instances id
            if(env.auditoryInstancesList{i,2}==instance)
                % retrieve the .wav file id for the processed instance
                stimulus=env.auditoryInstancesList{i,3}; 
                % and return
                break;
            end
        end
    end
end
