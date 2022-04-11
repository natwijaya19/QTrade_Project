function tradeSignal = tradeSignalShortMomFcn(paramInput, dataInput)

% tradeSignalShortMomFcn generate trading signal and is core of the
% strategy

% input arguments

% mechanism:
% 
% priceSignal:  
% priceRet = closePrice ./ lowPrice 
% priceRetSignal = priceRet > priceRetThreshold
% 
% volumeSignal:
% volumeMA = movmean (volumeTT.Variables, [volumeMALookback 0], 1, 'omitnan');
% volumeMASignal = volume > (volumeMA* volumeMAThreshold)
% 
% priceVolumeBuffer:
% priceVolumeSignal = priceRetSignal .* volumeMASignal 
% priceVolumeBufferDays = movmax(priceVolumeSignal ,[priceVolumeBufferDays, 0], 1, 'omitnan');
% 
% LiquiditySignal:
% valueTransaction = closePrice .* volume
% valueMA= movmean (valueTransaction , [valueMALookback 0], 1, 'omitnan');
% valueMASignal = (valueTransaction ./ valueMA) > valueMAThreshold
% 
% cutLoss:
% LastHightoCloseRet = closePrice ./ lastHighPrice -1
% cutlossSignal = LastHightoCloseRet > (-cutLossPct);
% 
% combinedSignal:
% combinedSignal = priceVolumeBufferDays .* valueMASignal .* cutlossSignal

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
%     6   %5
%     1   %6
%     120 %7
%     5   %8
%     8   %9
%     5   %10
%     ];

%% Transfer input values to each variables. All variables are converted from
% integer value in optimization adjusted to the suitable unit

x = paramInput ; % TODO remove comment when final

volumeMATreshold        = x(1)/100 ;    % input #1
volumeMALookback        = x(2) ;        % input #2
valueThreshold          = x(3)*10^8 ;   % input #3 in Rp 100Mn
priceRetLowCloseThresh  = x(4)/100 ;    % input #4
priceMAThreshold        = x(5)/100 ;    % input #5
priceMALookback         = x(6) ;        % input #6
priceVolumeBufferDays   = x(7) ;        % input #7
cutLossLookback         = x(8) ;        % input #8
cutLossPct              = x(9)/100 ;   % input #9

%=======================================================================

%% Signal from higher volume than historical volume MA
% volumeMALookback;
% volumeMATreshold;

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
% valueThreshold;
% valueMALookback;

tradeValue = closePriceTT.Variables .* volumeTT.Variables ;
% valueMA = movmean (tradeValue, [valueMALookback 0], 1, 'omitnan');
% valueMA(isnan(valueMA)) = 0;
% valueMA(isinf(valueMA)) = 0;

valueSignal = tradeValue > valueThreshold ;
valueSignal(isnan(valueSignal)) = 0;
valueSignal(isinf(valueSignal)) = 0;

% % check
% signal = sum(valueSignal,2);
% barFig = bar(signal);
% title("valueSignal")

clear tradeValue volumeTT volumeMA closePriceTT 

%=======================================================================

%% priceRetLowCloseSignal
% priceRetLowCloseThresh;
% priceRetLowCloseLookback;

lowPriceTT = dataInput{3};
closePriceTT = dataInput{4};
priceRetLowClose = (closePriceTT.Variables ./ lowPriceTT.Variables) -1 ;
priceRetLowClose(isnan(priceRetLowClose)) = 0;
priceRetLowClose(isinf(priceRetLowClose)) = 0;

priceRetLowCloseSignal = priceRetLowClose > priceRetLowCloseThresh;
priceRetLowCloseSignal(isnan(priceRetLowCloseSignal)) = 0;
priceRetLowCloseSignal(isinf(priceRetLowCloseSignal)) = 0;

% % check
% signal = sum(priceRetLowCloseSignal,2);
% barFig = bar(signal);
% title("priceRetLowCloseSignal")

clear lowPriceTT closePriceTT priceRetLowClose 

%=======================================================================

%% priceMA signal
% priceMALookback;
% priceMAThreshold;
closePriceTT = dataInput{4};

priceMA = movmean (closePriceTT.Variables, [priceMALookback, 0], 1, 'omitnan');
priceMA(isnan(priceMA)) = 0;
priceMA(isinf(priceMA)) = 0;

priceMASignal = closePriceTT.Variables > (priceMA .* priceMAThreshold);
priceMASignal(isnan(priceMASignal)) = 0;
priceMASignal(isinf(priceMASignal)) = 0;

% % check
% signal = sum(priceMASignal,2);
% barFig = bar(signal);
% title("priceMASignal")

clear closePriceTT priceMA

%=======================================================================

%% price volume buffer days
% priceVolumeBufferDays;

priceVolumeBuffer =  priceRetLowCloseSignal .* priceMASignal .* volumeSignal .* valueSignal;

priceVolumeBufferSignal = movmax(priceVolumeBuffer,[priceVolumeBufferDays, 0], 1, 'omitnan');

% % check
% signal = sum(priceBufferSignal,2);
% barFig = bar(signal);
% title("priceBufferSignal")

clear priceVolumeBuffer priceRetLowCloseSignal priceMASignal volumeSignal valueSignal

%=======================================================================

%% cut loss signal
% cutLossLookback;
% cutLossPct;

highPriceTT = dataInput{2};
closePriceTT = dataInput{4};

lastHighPrice = movmax(highPriceTT.Variables ,[cutLossLookback, 0], 1, 'omitnan');
lastHighPrice(isnan(lastHighPrice)) = 0;
lastHighPrice(isinf(lastHighPrice)) = 0;

LastHightoCloseRet = (closePriceTT.Variables ./ lastHighPrice) -1 ;
LastHightoCloseRet(isnan(LastHightoCloseRet)) = 0;
LastHightoCloseRet(isinf(LastHightoCloseRet)) = 0;

cutLossSignal = LastHightoCloseRet > (-cutLossPct);

% % check
% signal = sum(cutlossSignal,2);
% barFig = bar(signal);
% title("cutlossSignal")

clear highPriceTT closePriceTT lastHighPrice LastHightoCloseRet

%=======================================================================

%% Pre final signal (not yet 1 step lag shifted to avoid look ahead bias)
finalSignal = priceVolumeBufferSignal .* cutLossSignal ;

% % check
% signal = sum(finalSignal,2);
% barFig = bar(signal);
% title("finalSignal")

clear priceVolumeBufferSignal cutLossSignal 

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

clearvars -except tradeSignal

end