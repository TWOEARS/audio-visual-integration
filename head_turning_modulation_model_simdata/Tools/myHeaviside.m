function request = myHeaviside (x, y)

request = zeros(1, numel(y));

request(y >= x) = 1;
