

% This function reads all available visual categories
% file 'visualCategories.xml'
% input:
%       env:        the environment
        
function readVisualCategories(env)
        
    
     % clean up the list
    env.visualCategoryList=[];

    % open the visual category file, the following is quite self-
    % explanatory (by referring to the file structure)
    categoryFile = xmlread('visualCategories.xml');
    % parse xml structure
    categories = categoryFile.getElementsByTagName('category');
    for i = 0:categories.getLength-1
        category=categories.item(i);
        categoryName=char(category.getAttribute('name'));
        env.visualCategoryList=[env.visualCategoryList;{categoryName}];
    end

end        


        
        
        
        
        
        
        
        

