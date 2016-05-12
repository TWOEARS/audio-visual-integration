function incrementVariable (obj, variable, value)
    if nargin == 2
        value = 1;
    end
    eval(['obj.', variable, '=obj.', variable, '+', num2str(value)]);
end