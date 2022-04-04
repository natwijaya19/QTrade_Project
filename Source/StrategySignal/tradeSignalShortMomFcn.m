function tradeSignal = tradeSignalShortMomFcn(paramInput, dataInput)

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

% % dummy paramInput
% x = [
%     40  %1
%     200 %2
%     1   %3
%     5   %4
%     10  %5
%     6   %6
%     1   %7
%     120 %8
%     20  %9
%     5   %10
%     8   %11
%     5   %12
%     ];

%% Transfer input values to each variables. All variables are converted from
% integer value in optimization adjusted to the suitable unit

x = paramInput ; % TODO remove comment when final

volumeMATreshold = x(1)/100 ; % input #1
volumeMALookback = x(2) ; % input #2
valueThreshold = x(3)*10^9 ; % input #3 in Rp Bn
valueMALookback = x(4) ; % input #4 nDays`
volumeValueBufferDays = x(5) ; % input #5  
priceRetLowCloseThresh = x(6)/100 ; % input #6
priceRetLowCloseLookback = x(7)-1; % input #7
priceMAThreshold = x(8)/100 ; % input #8
priceMALookback = x(9) ; % input #9
priceBufferDays = x(10) ; % input #10
cutLossLookback = x(11) ; % input #11
cutLossPct = x(12)/100 ; % input #12



%=======================================================================

%% Signal from higher volume than historical volume MA
volumeMALookback;
volumeMATreshold;

volumeTT = dataInput{5};
volumeMA = movmean (volumeTT.Variables, [volumeMALookback 0], 1, 'omitnan');
volumeMA(isnan(volumeMA)) = 0;
volumeMA(isinf(volumeMA)) = 0;

volumeSignal = volumeTT.Variables > (volumeMA *volumeMATreshold);
volumeSignal(isnan(volumeSignal)) = 0;
volumeSignal(isinf(volumeSignal)) = 0;

% % check
% signal = sum(volumeSignal,2);
% barFig = bar(signal);
% title("volumeSignal")

clear volumeTT volumeMA

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

valueSignal = valueMA > valueThreshold ;

% % check
% signal = sum(valueSignal,2);
% barFig = bar(signal);
% title("valueSignal")

clear tradeValue volumeTT volumeMA closePriceTT

%=======================================================================

%% Volume value buffer days
volumeValueBufferDays ;

volumeValueSignal = volumeSignal .* valueSignal;
volumeValueBufferSignal = movmax(volumeValueSignal,[volumeValueBufferDays, 0], 1, 'omitnan');

% % check
% signal = sum(volumeValueBufferSignal,2);
% barFig = bar(signal);
% title("volumeValueBufferSignal")

clear  volumeSignal valueSignal
%=======================================================================

%% Signal price return from low to close
priceRetLowCloseThresh;
priceRetLowCloseLookback;

lowPriceTT = dataInput{3};
closePriceTT = dataInput{4};

shiftedLlowPriceTT = lowPriceTT;
shiftedLlowPriceTT.Variables = backShiftFcn(lowPriceTT.Variables, priceRetLowCloseLookback); 
priceRetLowClose = (closePriceTT.Variables ./ shiftedLlowPriceTT.Variables) -1 ;
priceRetLowClose(isnan(priceRetLowClose)) = 0;
priceRetLowClose(isinf(priceRetLowClose)) = 0;

priceRetLowCloseSignal = priceRetLowClose > priceRetLowCloseThresh;


% % check
% signal = sum(priceRetLowCloseSignal,2);
% barFig = bar(signal);
% title("priceRetLowCloseSignal")

clear lowPriceTT closePriceTT priceRetLowClose 

%=======================================================================

%% price MA signal
priceMALookback;
priceMAThreshold;
closePriceTT = dataInput{4};

priceMA = movmean (closePriceTT.Variables, [priceMALookback, 0], 1, 'omitnan');
priceMA(isnan(priceMA)) = 0;
priceMA(isinf(priceMA)) = 0;

priceMASignal = closePriceTT.Variables > (priceMA .* priceMAThreshold);

% % check
% signal = sum(priceMASignal,2);
% barFig = bar(signal);
% title("priceMASignal")

clear closePriceTT priceMA

%=======================================================================

%% price volume value buffer days
priceBufferDays;

priceBuffer =  priceRetLowCloseSignal .* priceMASignal;

priceBufferSignal = movmax(priceBuffer,[priceBufferDays, 0], 1, 'omitnan');

% % check
% signal = sum(priceBufferSignal,2);
% barFig = bar(signal);
% title("priceBufferSignal")

clear priceBuffer priceRetLowCloseSignal priceMASignal

%=======================================================================

%% cut loss signal
cutLossLookback;
cutLossPct;

highPriceTT = dataInput{2};
closePriceTT = dataInput{4};

lastHighPrice = movmax(highPriceTT.Variables ,[cutLossLookback, 0], 1, 'omitnan');
lastHighPrice(isnan(lastHighPrice)) = 0;
lastHighPrice(isinf(lastHighPrice)) = 0;

LastHightoCloseRet = (closePriceTT.Variables ./ lastHighPrice) -1 ;
LastHightoCloseRet(isnan(LastHightoCloseRet)) = 0;
LastHightoCloseRet(isinf(LastHightoCloseRet)) = 0;

cutlossSignal = LastHightoCloseRet > (-cutLossPct);

% % check
% signal = sum(cutlossSignal,2);
% barFig = bar(signal);
% title("cutlossSignal")

clear highPriceTT closePriceTT lastHighPrice LastHightoCloseRet

%=======================================================================

%% Pre final signal (not yet 1 step lag shifted to avoid look ahead bias)
finalSignal = priceBufferSignal .* cutlossSignal .* volumeValueBufferSignal;

% % check
% signal = sum(finalSignal,2);
% barFig = bar(signal);
% title("finalSignal")

clear priceBufferSignal cutlossSignal volumeValueBufferSignal

%=======================================================================

%% Warming up or initialization days
lookbackArray = [volumeMALookback, priceMALookback, cutLossLookback] ;
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

% clearvars -except tradeSignal

end