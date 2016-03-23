function [y] = visualDegradation_Distance(d)
    y=1-1./(1+exp(-(d-10)/2));
end

