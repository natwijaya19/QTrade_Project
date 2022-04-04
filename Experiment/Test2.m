
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

% dummy paramInput
paramInput = [
    40  %1
    200 %2
    1   %3
    5   %4
    10  %5
    6   %6
    1   %7
    120 %8
    20  %9
    5   %10
    8   %11
    5   %12
    ];
tradeSignal = tradeSignalShortMomFcn(paramInput, dataInput);
