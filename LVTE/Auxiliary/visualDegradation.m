function [y] = visualDegradation(vis,categoryEstimate,categoryGT)


if(strcmp(categoryEstimate,categoryGT))
    y=0.5+(0.5./(1+exp(-20*(vis-0.5))));
else
    y=0.5-(0.5./(1+exp(-20*(vis-0.5))));
end

end

