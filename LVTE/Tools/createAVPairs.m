
% This function generates acceptable and wrong audio-visual pairs for
% cognitive simulation. These pairs can basically be seen as external
% expert domain knowledge.

% input:
%       env:        the environment

function createAVPairs(env)
    
    % read the acceptable pairs from the corresponding xml file
    acceptablePairsFile = xmlread('acceptableAVPairs.xml');
    % parse xml structure (quite self-explanatory)
    acceptablePairs = acceptablePairsFile.getElementsByTagName('pair');
    for i = 0:acceptablePairs.getLength-1
        pair=acceptablePairs.item(i);
        % read the visual category
        A=char(pair.getAttribute('A'));
        % read the auditory category
        B=char(pair.getAttribute('B'));
        % push the pair to the acceptable example 'memory'
        env.acceptableAVPairs{i+1,1}={A,B};
        
    end

    % read the acceptable pairs from the corresponding xml file
    wrongPairsFile = xmlread('wrongAVPairs.xml');
    % parse xml structure (quite self-explanatory)
    wrongPairs = wrongPairsFile.getElementsByTagName('pair');
    for i = 0:wrongPairs.getLength-1
        pair=wrongPairs.item(i);
        % read the visual category
        A=char(pair.getAttribute('A'));
        % read the auditory category
        B=char(pair.getAttribute('B'));
        % push the pair to the wrong example 'memory'
        env.wrongAVPairs{i+1,1}={A,B};
        
    end
end