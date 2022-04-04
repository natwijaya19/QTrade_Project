
%%
dataInputRaw = load("DataInput\PriceVolumeInput2010to2022Raw.mat");
dataInputRaw = struct2cell(dataInputRaw);

startDate = datetime("1-Jan-2016");
endDate = datetime("1-Jan-2023");

dataInput = cell(numel(dataInputRaw),1);
for idx = 1:numel(dataInputRaw)
    dataInput{idx} = dataInputRaw{idx}(startDate:endDate,:);  
end

dataInput = cleanDataFcn(dataInput);

%% 
% tradeSignalShortMomFcn
