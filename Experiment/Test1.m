yahooDataSetUp = YahooDataSetUp;
spreadSheetSetUp = SpreadSheetSetUp;
matFileSetUp = MatFileSetUp;
marketData = MarketData (yahooDataSetUp, spreadSheetSetUp, matFileSetUp);
marketData = marketData.loadSymbolMCapRef;

tic
marketData = marketData.loadDataFromYahoo;
loadYahooTime = toc;
%% 
loadYahooTime/60

%% 
priceVolumeParfor = marketData.priceVolumeData;

priceVolumeParfor = cleanDataFcn(priceVolumeParfor);
priceVolumeParforVarNames = priceVolumeParfor{1}.Properties.VariableNames;
%%
priceVolumeFor = load("DataInput\PriceVolumeInput2010to2022Raw.mat");
priceVolumeFor = struct2cell(priceVolumeFor);
priceVolumeFor = cleanDataFcn(priceVolumeFor');
priceVolumeForVarNames = priceVolumeFor{1}.Properties.VariableNames;

%% compare

startDate = datetime("1-Jan-2016");
endDate = datetime("1-Jan-2022");
symbols = marketData.symbols;

priceVolData = cell(1,5);

% for idx = 1: numel(priceVolData)
    idx = 1;
    priceVolumeForCheck = priceVolumeFor{1,idx}(startDate:endDate,:);
    priceVolumeParforVarCheck = priceVolumeParfor{1,idx}(startDate:endDate,:);
    dataVar = priceVolumeParforVarCheck.Variables  == priceVolumeForCheck.Variables ;
    dataTT = priceVolumeFor{1,idx}(startDate:endDate,:);
    dataTT.Variables = dataVar;
    priceVolData{1,idx} = dataTT;
% end





