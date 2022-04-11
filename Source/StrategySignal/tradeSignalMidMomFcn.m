function tradeSignal = tradeSignalMidMomFcn(paramInput, dataInput)

% tradeSignalShortMomFcn generate trading signal and is core of the
% strategy

%% argument validation
arguments
    paramInput {mustBeNumeric}
    dataInput cell

end
%% setUp dataInput
% dataInput = dataClean;

%=======================================================================

%% setup the params


%% Transfer input values to each variables. All variables are converted from
% integer value in optimization adjusted to the suitable unit

x = paramInput ; % TODO remove comment when final

leadMALookback          = x(1);
lagMALookback           = x(2);
leadLagThreshold        = x(3) /100;
valueThreshold          = x(5) *10^8; % in Rp 100Mn
valueMALookback         = x(6);
lagPriceMABackShiftDay  = x(7);
lagPriceMARetThreshold  = x(8) /100;
cutLossLookback         = x(9);
cutLossPct              = x(10) /100;
cutLossBufferDays       = x(11);

%=======================================================================

%% Lead and Lag Signal
closePrice = dataInput{4};
lowPrice = dataInput{3};

leadMALookback;
lagMALookback;
leadLagThreshold;
leadLagBufferDays;

leadPriceMA = movmean (closePrice.Variables, [leadMALookback, 0], 1, 'omitnan');
leadPriceMA(isnan(leadPriceMA)) = 0;
leadPriceMA(isinf(leadPriceMA)) = 0;

lagPriceMA = movmean (lowPrice.Variables, [lagMALookback, 0], 1, 'omitnan');
lagPriceMA(isnan(lagPriceMA)) = 0;
lagPriceMA(isinf(lagPriceMA)) = 0;

leadLagSignal = leadPriceMA > (lagPriceMA * leadLagThreshold);
leadLagSignal(isnan(leadLagSignal)) = 0;
leadLagSignal(isinf(leadLagSignal)) = 0;

% % check
% signal = sum(volumeSignal,2);
% barFig = bar(signal);
% title("volumeSignal")

clear closePrice lowPrice leadPriceMA lagPriceMA 

%=======================================================================

%% Signal value threshold
closePriceTT = dataInput{4};
volumeTT = dataInput{5};

valueThreshold;
valueMALookback;


tradeValue = closePriceTT.Variables .* volumeTT.Variables ;
valueMA = movmean (tradeValue, [valueMALookback 0], 1, 'omitnan');
valueMA(isnan(valueMA)) = 0;
valueMA(isinf(valueMA)) = 0;

valueMASignal = valueMA > valueThreshold ;
valueMASignal(isnan(valueMASignal)) = 0;
valueMASignal(isinf(valueMASignal)) = 0;

% % check
% signal = sum(valueSignal,2);
% barFig = bar(signal);
% title("valueSignal")

clear tradeValue volumeTT closePriceTT valueMA

%=======================================================================

%% lagPriceMARetSignal
lagPriceMABackShiftDay;
lagMALookback;
lagPriceMARetThreshold;


lowPrice = dataInput{3};
lagPriceMA = movmean (lowPrice.Variables, [lagMALookback, 0], 1, 'omitnan');
lagPriceMA(isnan(lagPriceMA)) = 0;
lagPriceMA(isinf(lagPriceMA)) = 0;

shiftedLagPriceMA = lagPriceMA;
shiftedLagPriceMA.Variables = backShiftFcn (lagPriceMA.Variables, lagPriceMABackShiftDay);

lagPriceMARet = (lagPriceMA.Variables ./ shiftedLagPriceMA.Variables) -1; 
lagPriceMARet(isnan(lagPriceMARet)) = 0;
lagPriceMARet(isinf(lagPriceMARet)) = 0;

lagPriceMARetSignal = lagPriceMARet > lagPriceMARetThreshold;
lagPriceMARetSignal(isnan(lagPriceMARetSignal)) = 0;
lagPriceMARetSignal(isinf(lagPriceMARetSignal)) = 0;


% % check
% signal = sum(priceMASignal,2);
% barFig = bar(signal);
% title("priceMASignal")

clear lowPrice lagPriceMA shiftedLagPriceMA lagPriceMARet 

%=======================================================================

%% cut loss signal
cutLossLookback;
cutLossPct;
cutLossBufferDays;

% highPriceTT = dataInput{2};
lowPriceTT = dataInput{4};

lastHighestLowPrice = movmax(lowPriceTT.Variables ,[cutLossLookback, 0], 1, 'omitnan');
lastHighestLowPrice(isnan(lastHighestLowPrice)) = 0;
lastHighestLowPrice(isinf(lastHighestLowPrice)) = 0;

cutLossRet = (lowPriceTT.Variables ./ lastHighestLowPrice) -1 ;
cutLossRet(isnan(cutLossRet)) = 0;
cutLossRet(isinf(cutLossRet)) = 0;

cutLossSignal = cutLossRet > (-cutLossPct);
cutLossSignal(isnan(cutLossSignal)) = 0;
cutLossSignal(isinf(cutLossSignal)) = 0;

cutLossBufferSignal = movmin(cutLossSignal,[cutLossBufferDays, 0], 1, 'omitnan');

% % check
% signal = sum(cutlossSignal,2);
% barFig = bar(signal);
% title("cutlossSignal")

clear lowPriceTT lastHighestLowPrice cutLossRet cutLossSignal 

%=======================================================================

%% Pre final signal (not yet 1 step lag shifted to avoid look ahead bias)
finalSignal = leadLagSignal .* lagPriceMARetSignal .* valueMASignal .* cutLossBufferSignal ;

% % check
% signal = sum(finalSignal,2);
% barFig = bar(signal);
% title("finalSignal")

clear  cutLossSignal priceMABufferSignal valueMASignal

%=======================================================================

%% Warming up or initialization days
leadMALookback;
lagMALookback;
valueMALookback;
cutLossLookback;

lookbackArray   = [leadMALookback, lagMALookback, valueMALookback, cutLossLookback] ;
warmingUpPeriod = max(lookbackArray) ;
finalSignal (1:warmingUpPeriod, :) = 0 ;

% % check
% signal = sum(finalSignal,2);
% barFig = bar(signal);
% title("finalSignal")

%=======================================================================

%% transfer to the output variable
tradeSignal = dataInput{1};
tradeSignal.Variables = finalSignal;

symbols = tradeSignal.Properties.VariableNames ;
symbols = strrep(symbols,"_open","_signal") ;
tradeSignal.Properties.VariableNames  = symbols ;

%=======================================================================

%% end of function, remove intermediary variables

clearvars -except tradeSignal

end