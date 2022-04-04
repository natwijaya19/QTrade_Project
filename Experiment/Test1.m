yahooDataSetUp = YahooDataSetUp;
spreadSheetSetUp = SpreadSheetSetUp;
matFileSetUp = MatFileSetUp;
marketData = MarketData (yahooDataSetUp, spreadSheetSetUp, matFileSetUp);
marketData = marketData.loadSymbolMCapRef;

tic
marketData = marketData.loadDataFromYahoo;
loadYahooTime = toc;
%% 
priceVolumeParfor = marketData.priceVolumeData;

priceVolumeParfor = cleanDataFcn(priceVolumeParfor);
%%
priceVolumeFor = load("DataInput\PriceVolumeInput2010to2022Raw.mat");
priceVolumeFor = struct2cell(priceVolumeFor);
priceVolumeFor = cleanDataFcn(priceVolumeFor');

%% compare

startDate = datetime("1-Jan-2016");
endDate = datetime("1-Jan-2022");
symbols = marketData.symbols;

priceVolData = cell(1,5);

for idx = 1: numel(priceVolData)
    idx = 1;
    priceVolumeForVar = priceVolumeFor{1,idx}(startDate:endDate,:).Variables ;
    priceVolumeParforVar = priceVolumeParfor{1,idx}(startDate:endDate,:).Variables;
    dataVar = priceVolumeParforVar == priceVolumeForVar;
    dataTT = priceVolumeFor{1,idx}(startDate:endDate,:);
    dataTT.Variables = dataVar;
    priceVolData{1,idx} = dataTT;
end





