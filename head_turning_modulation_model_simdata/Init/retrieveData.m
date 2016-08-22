function pos = retrieveData(nb_pairs, nb_steps)
    
    
    %filePath = ['Data/', num2str(nb_pairs), '_', num2str(nb_steps), '/'] ; % save with datetime('now')
    %fileList = dir([filePath, '*.mat']);

  
    %if ( ~isempty(fileList) )  

       % fileList = cellstr(vertcat(fileList(:).name));
    	% disp('List of available simulation files:');
    	% disp(vertcat(fileList{:}));
     %    prompt = 'Enter the number of the simulation to load: ';
     %    ii = input(prompt);
     %   load([filePath, fileList{ii}]);

        load('Data/5_3000/19-May-2016 16:04:00');

        setappdata(0, 'AVPairs', simuData.AVPairs);
        setappdata(0, 'gtruth', simuData.gtruth);
        setappdata(0, 'audioLabels',simuData.audioLabels );
        setappdata(0, 'visualLabels', simuData.visualLabels);
        setappdata(0, 'data', simuData.data);
        setappdata(0, 'thetaObj', simuData.thetaObj);
        setappdata(0, 'distHist', simuData.distHist);

        pos = 1;

    %else
    %    pos = 0;
   % end
    
end