function [priceVolumeData, indexIHSG] = loadDataFromYahooFcn(symbols, startDate, endDate, interval, maxRetry)

%%loadMarketDataFromYahoo

% assume symbols array contain some invalid symbols.
% required data
%   - list of symbols >> should be string array
%   - startDate
%   - nYearPeriod
%   - endDate
%   - interval >> interval day period
%   - maxRetry >> for error handling

%-----------------------------------------------------------------------------------------------


% get nRow from sampleData
symbols = sort(symbols,"ascend");
sampleSymbol = 'BBCA.JK';

% sample data for preallocation TT in loop
sampleData = getMarketDataViaYahoo(char(sampleSymbol), startDate, endDate, interval);
sampleData = table2timetable(sampleData);
sampleVarName = sampleData.Properties.VariableNames;
timeCol = sampleData.Date;
[nRowSampleData, nColSampleData] = size(sampleData);
sampleVariableTypes = repmat({'double'}, 1, nColSampleData);

TT = timetable('Size', size(sampleData), 'VariableTypes', sampleVariableTypes, 'RowTimes', timeCol,...
    'VariableNames', sampleVarName);

TT.Variables = nan(nRowSampleData, nColSampleData);

% preallocation for preallocation dataTT in loop. dataTT in created to
% maintain nSymbols in output and input price volume data

nSymbols = numel(symbols);
nRow = nRowSampleData;
% sz = [nRow, nSymbols];
% varSample = zeros(nRow,nSymbols);
variableTypes = repmat({'double'}, 1,nSymbols);
varName = symbols';

% preallocation for each price volume data
openPriceTT = timetable('Size', [nRow,nSymbols], 'VariableTypes', variableTypes , 'RowTimes', timeCol, ...
    'VariableNames', varName);
highPriceTT = openPriceTT;
lowPriceTT = openPriceTT;
closePriceTT = openPriceTT;
volumeTT = openPriceTT;

% looping through all symbol
close all;
% waitbarFig = waitbar(0, "Downloading data from yahoo");
progressCounter = 1:5:nSymbols;

parfor Idx = 1: nSymbols
%     waitbar(Idx/nSymbols, waitbarFig, "Downloading data from yahoo");
    symi = strcat(symbols(Idx), ".JK");

    % preallocate helper
    dataTT = timetable('Size', [nRow,1], 'VariableTypes', {'double'} , 'RowTimes', timeCol, ...
    'VariableNames', "preallocation");

    % progressCounter
    if ismember(Idx, progressCounter)
        disp(strcat(string(Idx)," ", string(symi)))
    end

    dataIdx = tryGetMarketDataViaYahoo(symi, startDate, endDate, interval, maxRetry);
    if isempty(dataIdx)
        dataIdx = TT;
    end
    dataSynced = synchronize(dataTT, dataIdx);
    dataSynced.preallocation = [];

    % Put data to each variable timetable
    openPriceTT(:,Idx).Variables = dataSynced(:,1).Variables ;
    highPriceTT(:,Idx).Variables = dataSynced(:,2).Variables;
    lowPriceTT(:,Idx).Variables = dataSynced(:,3).Variables;
    closePriceTT(:,Idx).Variables = dataSynced(:,4).Variables;
    volumeTT(:,Idx).Variables = dataSynced(:,6).Variables;

end


% load indexIHSG
indexIHSGSymbol = '^JKSE';

indexIHSG = tryGetMarketDataViaYahoo(indexIHSGSymbol, startDate,...
    endDate, interval, maxRetry);
if isempty(indexIHSG)
    indexIHSG = TT;
end

% replace string .JK from each symbol name with _open, _high, _low, _close
% and _volume
symbolsVarName = openPriceTT.Properties.VariableNames;

openPriceVar = strcat(string(symbolsVarName), "_Open");
highPriceVar  = strcat(string(symbolsVarName), "_High");
lowPriceVar = strcat(string(symbolsVarName), "_Low");
closePriceVar = strcat(string(symbolsVarName), "_Close");
volumeVar = strcat(string(symbolsVarName), "_Volume");

openPriceTT.Properties.VariableNames = openPriceVar ;
highPriceTT.Properties.VariableNames = highPriceVar ;
lowPriceTT.Properties.VariableNames = lowPriceVar ;
closePriceTT.Properties.VariableNames = closePriceVar ;
volumeTT.Properties.VariableNames = volumeVar ;

%% wrap up for the output
% populate data results to PriceVolumeContainer class object
priceVolumeData = cell(1,5);
openPrice = openPriceTT;
highPrice = highPriceTT;
lowPrice = lowPriceTT;
closePrice = closePriceTT;
volume = volumeTT;

% put the price volume
priceVolumeData{1} = openPrice;
priceVolumeData{2} = highPrice;
priceVolumeData{3} = lowPrice;
priceVolumeData{4} = closePrice;
priceVolumeData{5} = volume;

% output
% indexIHSG;
% priceVolumeData;

%=========================================================================

%% end of function    

clearvars -except priceVolumeData indexIHSG

end 