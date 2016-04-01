

% This function reads all available auditory categories, and category
% instances from the file 'auditoryCategories.xml'
% input:
%       env:        the environment

function readAuditoryCategories(env)
    
    % clean up the lists
    env.auditoryInstancesList=[];
    env.auditoryCategoryList=[];

    % open the auditory category file, the following is quite self-
    % explanatory (by referring to the file structure)
    categoryFile = xmlread('auditoryCategories.xml');
    % parse xml structure
    categories = categoryFile.getElementsByTagName('category');
    for i = 0:categories.getLength-1
        category=categories.item(i);
        categoryName=char(category.getAttribute('name'));
        env.auditoryCategoryList=[env.auditoryCategoryList;{categoryName}];

        instances=categories.item(i).getElementsByTagName('instance');
        for j=0:instances.getLength()-1
            instance = instances.item(j);                    
            id=str2num(instance.getAttribute('id'));
            stimulus=char(instance.getAttribute('stimulus'));
            
            env.auditoryInstancesList=[...
                env.auditoryInstancesList;{categoryName,id,stimulus}];
        end
    end

end
