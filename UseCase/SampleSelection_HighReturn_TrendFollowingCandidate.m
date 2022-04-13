%%
clear
clc
close all

%% load data
matfileObject= matfile("DataInput\priceVolumeData.mat");
priceVolumeData = matfileObject.priceVolumeData;

% closePrice = priceVolumeData{5};
%
% endVarName = ["_Open", "_High", "_Low", "_Close", "_Volume"];
% symbolsVarName = strrep(string(priceVolumeData{1}.Properties.VariableNames),"_open","");
% priceVolumeDataUpdated = priceVolumeData;
% for idx = 1:numel(priceVolumeData)
%     priceVolumeDataUpdated{idx}.Properties.VariableNames = strcat(symbolsVarName, endVarName(idx));
% end
%
% priceVolumeData = priceVolumeDataUpdated;
% save("DataInput\priceVolumeData.mat", "priceVolumeData")

% select period for cleanData
startDate =  datetime("01-Jan-2016");
endDate = datetime("today");
selectedPriceVolumeData = priceVolumeData;
for idx = 1:numel(priceVolumeData)
    selectedPriceVolumeData{idx} = priceVolumeData{idx}(startDate:endDate,:);
end
dataInput = cleanDataFcn(selectedPriceVolumeData);

%% establish criteria
minNDayFromLowToHigh = 60;
minCumRet = 2 ; % should be greater than 1
minValueMA = 10^8; % Rp 100M
valueMALookback = 20;

%% loop over the price of the symbols population
closePrice = dataInput{4};
volumeData = dataInput{5};

randNum = randi([1, 999], size(closePrice)) /10^3;
closePrice.Variables = dataInput{4}.Variables + randNum;

valueDaily = closePrice;
valueDaily.Properties.VariableNames = strrep(closePrice.Properties.VariableNames, "_Close", "_Value");
valueDaily.Variables = closePrice.Variables .* volumeData.Variables ;
valueMA = movmean(valueDaily.Variables, [valueMALookback,0], 1, "omitnan");

% clear selectedPriceVolumeData priceVolumeData dataInput

symbolsVarName = closePrice.Properties.VariableNames;
% preallocate
symbolsIndex = 1:numel(symbolsVarName);

for idx = 1:numel(symbolsVarName)
%         idx = 5;

    priceSeriesIdx = closePrice{:,idx};
    highestPrice = max(priceSeriesIdx);
    lowerHighestPrice = highestPrice/minCumRet;
    lowestPriceSeries = priceSeriesIdx (priceSeriesIdx <lowerHighestPrice);
    lowestPrice = max(lowestPriceSeries);

    zeroCheck = min(max(priceSeriesIdx)<1);
    highestPriceCheck = isempty(highestPrice);
    lowestPriceCheck = isempty(lowestPrice);
    skipValidIF= min([zeroCheck, highestPriceCheck, lowestPriceCheck]);

    if ~skipValidIF
        % skip if max priceSeriesIdx <1;
        validIF = 0;

    else
        lowestPriceIdx = find(priceSeriesIdx == lowestPrice);
        highestPriceIdx = find(priceSeriesIdx == highestPrice);

        minNDayFromLowToHighValidIF = highestPriceIdx >= lowestPriceIdx +minNDayFromLowToHigh;
        minCumRetValidIF = highestPrice/lowestPrice >= minCumRet;
        minValueMAValidIF = min(valueMA(:,idx)) > minValueMA;

        validIF = min([minNDayFromLowToHighValidIF, minCumRetValidIF, minValueMAValidIF]);

    end

    if ~validIF
        symbolsIndex(idx) = 0;
    end
end

selectedIdx = symbolsIndex(symbolsIndex>0);
selectedSymbols = symbolsVarName(:, selectedIdx);
selectedClosePrice = closePrice(:, selectedSymbols);
initialClosePriceFirstRow = selectedClosePrice(1, :);

initialClosePrice = repmat (initialClosePriceFirstRow(1, :).Variables, size(selectedClosePrice, 1),1);
scaledClosePrice = selectedClosePrice;
scaledClosePrice.Variables = selectedClosePrice.Variables ./ initialClosePrice;
% clear closePrice

%% plot the selected symbols

figure
for idx = 1:numel(selectedSymbols)
    symIdx = selectedSymbols(idx);
    plot(selectedClosePrice.Time, selectedClosePrice(:, symIdx).Variables)
    hold on;

end
plotTitle = "plot the selected symbols";
title(plotTitle);
legendSym = strrep(selectedSymbols, "_Close", "");
legend(legendSym, Location="best");
hold off;


%%

figure
plot(closePrice.Time, closePrice(:,symbolsVarName(idx)).Variables)
titleText = strrep(symbolsVarName(idx),"_Close","");
title(titleText)

% randNum = randi([1, 10^3], size(closePrice)) /10^6;
% max(max(randNum))
