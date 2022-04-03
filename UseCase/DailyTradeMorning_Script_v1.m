%% Start
clear
close all
clc

disp("===============================START=====================================")

%% Load the market data
yahooDataSetUp      = YahooDataSetUp;
yahooDataSetUp.path = pwd;
spreadSheetSetUp    = SpreadSheetSetUp;
matFileSetUp        = MatFileSetUp;
matFileSetUp.path   = pwd;

marketData = MarketData (yahooDataSetUp, spreadSheetSetUp, matFileSetUp);
marketData = marketData.loadSymbolMCapRef;
marketData = marketData.loadDataFromMatFile;
marketData = marketData.classifyMktCap;

%% 
marketData = marketData.loadDataFromYahoo;


%% Save the priceVolume data to matfile
priceVolumeData = marketData.priceVolumeData;

path            = pwd;
folderName      = "dataInput";
fileName        = "priceVolumeData.mat";
fullFileName    = fullfile(path, folderName, fileName);
save(fullFileName,"priceVolumeData");


%% Save the priceVolume data to excel spreadsheet

priceVolumeData = marketData.priceVolumeData;

path            = pwd;
folderName      = "dataInput";
fileName        = "priceVolumeData.xlsx";
fullFileName    = fullfile(path, folderName, fileName);
sheetName       = ["openPrice", "highPrice", "lowPrice", "closePrice", "volume"];

for dataIdx = 1: numel(priceVolumeData)
    % dataIdx = 1;
    dataTable = priceVolumeData{dataIdx};
    writetimetable(dataTable, fullFileName, Sheet=sheetName(dataIdx));
end

%% select dataset for tradeSignal

% load paramSet
%% Load setting and preparation
paramSetWFA = setUpWFAParam(marketData, nWalk=30, maxFcnEval=120);

nStepTest = paramSetWFA.nStepTest;
nStepTrain = paramSetWFA.nStepTrain;
maxLookback = paramSetWFA.maxLookback;
nRowRequired = maxLookback+nStepTrain+nStepTest;
    
priceVolumeData = marketData.priceVolumeData;

tradeDataset  = cell(1,numel(priceVolumeData));
nRowData = size(priceVolumeData{1},1);
rowData = (nRowData - nRowRequired) : nRowData;
for dataIdx = 1:numel(priceVolumeData)
    tradeDataset{dataIdx} = priceVolumeData{dataIdx}(rowData,:);
end

%% generate tradeSignal



%% load latest portfolio allocation
path            = pwd;
folderName      = "dataInput";
fileName        = "latestPort.xlsx";
fullFileName    = fullfile(path, folderName, fileName);
latestPort      = readtable(fullFileName) ;


%% calc. new portfolio allocation and trade list





%% symList to sell





%% symList to buy




