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

%% setup the params

%=======================================================================

%% Transfer input values to each variables. All variables are converted from
% integer value in optimization adjusted to the suitable unit

x = paramInput ; % TODO remove comment when final

priceMAThreshold        = x(1)/100 ;  
priceMALookback         = x(2) ;      
priceMABufferDays       = x(3) ;       
valueThreshold          = x(4)*10^8 ;  % input #1 in Rp Bn
valueMALookback         = x(5) ;       
cutLossLookback         = x(6) ; 
cutLossPct              = x(7)/100 ;  
cutLossBufferDays       = x(8);

%=======================================================================

%% price MA signal
priceMALookback;
priceMAThreshold;
priceMABufferDays;

% lowPriceTT = dataInput{4};
closePriceTT = dataInput{4};

priceMA = movmean (closePriceTT.Variables, [priceMALookback, 0], 1, 'omitnan');
priceMA(isnan(priceMA)) = 0;
priceMA(isinf(priceMA)) = 0;

priceMASignal = closePriceTT.Variables > (priceMA .* priceMAThreshold);
priceMABufferSignal = movmax(priceMASignal,[priceMABufferDays, 0], 1, 'omitnan');

% % check
% signal = sum(priceMASignal,2);
% barFig = bar(signal);
% title("priceMASignal")

clear closePriceTT priceMA priceMASignal

%=======================================================================

%% Signal value threshold
closePriceTT = dataInput{4};
volumeTT = dataInput{5};
% valueThreshold;
% valueMALookback;

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

clear closePriceTT volumeTT  tradeValue valueMA

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
finalSignal = priceMABufferSignal .* valueMASignal .* cutLossBufferSignal;

% % check
% signal = sum(finalSignal,2);
% barFig = bar(signal);
% title("finalSignal")

clear  cutlossSignal priceMABufferSignal valueMASignal

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