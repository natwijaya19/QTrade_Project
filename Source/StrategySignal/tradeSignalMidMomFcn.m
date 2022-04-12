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

priceMAThreshold        = x(1)/100 ;  
priceMALookback         = x(2) ;     
priceMABufferDays       = x(3) ;       
priceMABackShiftDay     = x(4);
priceMARetThreshold     = x(5) /100;
valueThreshold          = x(6)*10^9 ;  % in Rp Bn
valueMALookback         = x(7) ;      
cutLossLookback         = x(8) ;       
cutLossPct              = x(9)/100 ;   
cutLossBufferDays       = x(10);

%=======================================================================

%% price MA signal
priceMALookback;
priceMAThreshold;
priceMABufferDays;

closePriceTT = dataInput{4};
lowPriceTT = dataInput{3};

priceMA = movmean (closePriceTT.Variables, [priceMALookback, 0], 1, 'omitnan');
priceMA(isnan(priceMA)) = 0;
priceMA(isinf(priceMA)) = 0;

priceMASignal = lowPriceTT.Variables > (priceMA * priceMAThreshold);
priceMABufferSignal = movmax(priceMASignal,[priceMABufferDays, 0], 1, 'omitnan');

% % check
% signal = sum(priceMASignal,2);
% barFig = bar(signal);
% title("priceMASignal")

clear closePriceTT priceMASignal

%=======================================================================

%% priceMARetSignal
priceMABackShiftDay;
priceMARetThreshold;
priceMALookback;

shiftedPriceMA= backShiftFcn (priceMA, priceMABackShiftDay);

priceMARet = (priceMA ./ shiftedPriceMA) -1; 
priceMARet(isnan(priceMARet)) = 0;
priceMARet(isinf(priceMARet)) = 0;

priceMARetSignal = priceMARet > priceMARetThreshold;
priceMARetSignal(isnan(priceMARetSignal)) = 0;
priceMARetSignal(isinf(priceMARetSignal)) = 0;

clear shiftedPriceMA priceMARet priceMA

%=======================================================================

%% Signal value threshold
valueThreshold;
valueMALookback;

closePriceTT = dataInput{4};
volumeTT = dataInput{5};

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

%% cut loss signal
cutLossLookback;
cutLossPct;
cutLossBufferDays;

highPriceTT = dataInput{2};
closePriceTT = dataInput{4};

lastHighPrice = movmax(highPriceTT.Variables ,[cutLossLookback, 0], 1, 'omitnan');
lastHighPrice(isnan(lastHighPrice)) = 0;
lastHighPrice(isinf(lastHighPrice)) = 0;

LastHightoCloseRet = (closePriceTT.Variables ./ lastHighPrice) -1 ;
LastHightoCloseRet(isnan(LastHightoCloseRet)) = 0;
LastHightoCloseRet(isinf(LastHightoCloseRet)) = 0;

cutLossSignal = LastHightoCloseRet > (-cutLossPct);
cutLossSignal(isnan(cutLossSignal)) = 0;
cutLossSignal(isinf(cutLossSignal)) = 0;

cutLossBufferSignal = movmin(cutLossSignal,[cutLossBufferDays, 0], 1, 'omitnan');

% % check
% signal = sum(cutlossSignal,2);
% barFig = bar(signal);
% title("cutlossSignal")

clear highPriceTT closePriceTT lastHighPrice LastHightoCloseRet cutLossSignal

%=======================================================================

%% Pre final signal (not yet 1 step lag shifted to avoid look ahead bias)
finalSignal = priceMABufferSignal .* priceMARetSignal .* valueMASignal .* cutLossBufferSignal;

% % check
% signal = sum(finalSignal,2);
% barFig = bar(signal);
% title("finalSignal")

clear  priceMABufferSignal priceMARetSignal valueMASignal cutLossBufferSignal

%=======================================================================

%% Warming up or initialization days
lookbackArray = [valueMALookback, priceMALookback, cutLossLookback] ;
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