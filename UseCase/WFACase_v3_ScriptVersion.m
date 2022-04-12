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

% marketData = marketData.loadDataFromMatFile;
load("DataInput\priceVolumeData.mat");
marketData.priceVolumeData = priceVolumeData;
dataInputPreSelect = marketData.priceVolumeData;

% prepare data for only within the target time period
startDate   = datetime("01-Jan-2014", InputFormat="dd-MMM-uuuu");
endDate     = datetime("1-Mar-2023", InputFormat="dd-MMM-uuuu");    

dataInput = cell(1,numel(dataInputPreSelect));
for dataIdx = 1: numel(dataInputPreSelect)
    dataInput{dataIdx} = dataInputPreSelect{dataIdx}(startDate:endDate,:);
end

marketData.priceVolumeData = dataInput;
marketData = marketData.classifyMktCap;

marketData = struct(marketData);

%% Load setting and preparation

paramSetWFA = setUpWFAParam(marketData, nWalk=1)

% uniqMktCap = paramSetWFA.uniqMktCap;
% paramSetWFA.uniqMktCap = uniqMktCap(2);
% clear dataInputPreSelect marketData

%% runWFA
tic
mCapWalkResults = runMCapWalk(dataInput, paramSetWFA);
runMCapWalkTime = toc

% save mCapWalkResults
path            = pwd;
folder          = "DataOutput";
fileName        = "mCapWalkResults.mat";
fullFileName    = fullfile(path, folder,fileName);
save(fullFileName, "mCapWalkResults");

%% show performance evaluation
close all
combinedWFAResults = visualizeResults(mCapWalkResults, dataInput, paramSetWFA);
combinedWFAResults.summary

%% package WFAResults per symGroup and combinedResults
if exist("packageWFAResults", "var")
    clearvars packageWFAResults
end

packageWFAResults.lowBigCap             = mCapWalkResults{1} ;
packageWFAResults.lowMidCap             = mCapWalkResults{2} ;
packageWFAResults.lowSmallCap           = mCapWalkResults{3} ;
packageWFAResults.upBigCap              = mCapWalkResults{4};
packageWFAResults.upMidCap              = mCapWalkResults{5};
packageWFAResults.upSmallCap            = mCapWalkResults{6};
packageWFAResults.combinedWFAResults    = combinedWFAResults;

% save packageWFAResults
path        = pwd;
folder      = "DataOutput";
fileName    = "packageWFAResults_Jan2021_to_Mar2022.mat";
fullFileName = fullfile(path, folder,fileName);
save(fullFileName, "packageWFAResults");

%% save summary results to excel table
path        = pwd;
folder      = "DataOutput";
fileName    = "SummaryTable.xlsx";
fullFileName = fullfile(path, folder, fileName);
writetable(combinedWFAResults.summary, fullFileName);

%% End
disp("===============================END=====================================")
