
for ii = 1:51 
    TimeVal = tic;
    ii
    htm(ii)=HeadTurningModulationKS();
    nb_steps = 3000;
    htm(ii).robot.environments{1}.setQ(0.49+ii*0.01)
    htm(ii).run('steps',nb_steps, 'load', 1, 'save', 1);
    x = htm(ii);
    save(['Data/Simu_results/', num2str(ii)],'x');
    t(ii) = toc(TimeVal);
end


for ii = 1:51
    htm(ii).computeStatisticalPerformance();
end

%save('Data/Simu_results/htm_tot','htm');

for ii = 1:10
    htm(ii).plotGoodClassif();
    xlabel({'5 paires AV','Performance Threshold=0.90',['Simulation #',num2str(ii)]}, 'FontSize', 14);
end

for ii = 1:51
    pFactor(ii)= sum( (1- htm(ii).statistics.mfi_mean).^2) ;
end

for ii = 1:51
    m(ii) = mean(htm(ii).statistics.mfi_mean);

end
mean(m)
mfi_mean = mean(cell2mat(arrayfun(@(x) htm(x).statistics.mfi_mean', 1:51, 'UniformOutput', false)), 2);
std_q_mean = cell2mat(arrayfun(@(x) std([mfi_mean ; htm(x).statistics.mfi_mean']), 1:51, 'UniformOutput', false));     
    
