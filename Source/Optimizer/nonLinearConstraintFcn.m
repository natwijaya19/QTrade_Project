function [c, ceq] = nonLinearConstraintFcn (tradingSignalParam, dataInput, paramSetWFA)
% nonLinearConstraintFcn
%
% USAGE:
%       Fval = nonLinearConstraintFcn (dataStructInput, tradingSignalParam,...
%               optimLookbackStep, tradingCost, maxCapAllocation,...
%               maxDDThreshold, minPortfolioReturn, minDailyRetThreshold)
%
% input argument:
%   tradingSignalParam      vector array    :   1xnVars
%   dataStructInput         struct          :   field openPrice, highPrice, lowPrice,
%                                               highPrice and volume. All these data are in timetable
%   optimLookbackStep       scalar          :   nStep lookback for total return calculation
%   maxDDThreshold          scalar          :   max acceptable drawdown
%   minPortfolioReturn               scalar          :   min acceptable return of
%                                               the portfolio for the optimLookbackStep period
%   minDailyRetThreshold    scalar          :   min acceptable dailyRet of the portfolio

%======================================================================

%%
% transfer input variables
optimLookbackStep = paramSetWFA.optimLookbackStep;
minSharpeRatio = paramSetWFA.minSharpeRatio;
maxDDThreshold = paramSetWFA.maxDDThreshold;
minPortRet = paramSetWFA.minPortRet;
minDailyRetThreshold = paramSetWFA.minDailyRetThreshold;
minLast20DRetThreshold = paramSetWFA.minLast20DRetThreshold ;
minLast60DRetThreshold = paramSetWFA.minLast60DRetThreshold ;
minLast200DRetThreshold = paramSetWFA.minLast200DRetThreshold ;

% generate signal
tradingSignalOut = tradeSignalShortMomFcn (tradingSignalParam, dataInput);

% backtest the signal against the price
tradingSignalIn = tradingSignalOut;

resultStruct = btEngineEventDrivenFcn (dataInput, tradingSignalIn,paramSetWFA);

% calculate equityCurve at for the evaluation
equityCurvePortfolioVar_raw = resultStruct.equityCurvePortfolioTT.Variables;
equityCurvePortfolioVar = equityCurvePortfolioVar_raw(end-optimLookbackStep+1: end);
equityCurvePortfolioVar = string(equityCurvePortfolioVar);
equityCurvePortfolioVar = double(equityCurvePortfolioVar);
equityCurvePortfolioVar = fillmissing(equityCurvePortfolioVar, "previous");

%% calcluate return for the given  optimLookbackWindow minPortfolioReturn
startOptimPortValue = equityCurvePortfolioVar(1);
endOptimPortValue = equityCurvePortfolioVar(end);
cumPortfolioReturn = endOptimPortValue / startOptimPortValue;
cumPortfolioReturn(isnan(cumPortfolioReturn)) = 0;
cumPortfolioReturn(isinf(cumPortfolioReturn)) = 0;


%% Risk-reward ratios
risklessAssetRet = 0 ;
dailyNetRetPortfolioTT = resultStruct.dailyNetRetPortfolioTT;
sharpeRatio = sharpe(dailyNetRetPortfolioTT.Variables, risklessAssetRet) *sqrt (252);
sharpeRatio(isnan(sharpeRatio)) = 0 ;
sharpeRatio(isinf(sharpeRatio)) = 0 ;

%% calculate maxDD for maxDDThreshold
maxDD = -maxdrawdown(equityCurvePortfolioVar);

%% calculate dailyRet for minDailyRetThreshold
dailyRet = tick2ret(equityCurvePortfolioVar);
dailyRet(isnan(dailyRet)) = 0;
DailyRetMin = min(dailyRet);

%==========================================================================

%% Last 20 days return
nDays = 20;
portCumRet = equityCurvePortfolioVar;
Last20DRet = portCumRet ;

if numel (portCumRet) <= nDays
    Last20DRetMin = 0;
else

    Last20DRet(nDays+1:end,:) = (portCumRet(nDays+1:end,:) ./ portCumRet(1:end-nDays,:))-1;
    Last20DRet(1:nDays,:) = 0 ;
    Last20DRet (isnan(Last20DRet)) = 0 ;
    Last20DRet (isnan(Last20DRet)) = 0 ;
    Last20DRet (isinf(Last20DRet)) = 0 ;
    Last20DRetMin = min(Last20DRet);

end

%==========================================================================

%% Last 20 days return
nDays = 60;
portCumRet = equityCurvePortfolioVar;
Last60DRet = portCumRet ;

if numel (portCumRet) <= nDays
    Last60DRetMin = 0;
else
    Last60DRet(nDays+1:end,:) = (portCumRet(nDays+1:end,:) ./ portCumRet(1:end-nDays,:))-1;
    Last60DRet(1:nDays,:) = 0 ;
    Last60DRet (isnan(Last60DRet)) = 0 ;
    Last60DRet (isnan(Last60DRet)) = 0 ;
    Last60DRet (isinf(Last60DRet)) = 0 ;
    Last60DRetMin = min(Last60DRet);

end

%==========================================================================

%% Last 200 days return
nDays = 200;
portCumRet = equityCurvePortfolioVar;
Last200DRet = portCumRet ;

if numel (portCumRet) <= nDays
    Last200DRetMin = 0;

else
    Last200DRet(nDays+1:end,:) = (portCumRet(nDays+1:end,:) ./ portCumRet(1:end-nDays,:))-1;
    Last200DRet(1:nDays,:) = 0 ;
    Last200DRet (isnan(Last200DRet)) = 0 ;
    Last200DRet (isnan(Last200DRet)) = 0 ;
    Last200DRet (isinf(Last200DRet)) = 0 ;
    Last200DRetMin = min(Last200DRet);

end

%==========================================================================

%% formulate the constraints
c = [
    maxDDThreshold - maxDD;
    minSharpeRatio - sharpeRatio;
    minPortRet - cumPortfolioReturn;
    minDailyRetThreshold - DailyRetMin;
    minLast20DRetThreshold - Last20DRetMin;
    minLast60DRetThreshold - Last60DRetMin;
    minLast200DRetThreshold - Last200DRetMin;
    ];

ceq = [];

%==========================================================================

clearvars -except c eq

end
%------------------------------------------------------------------------------------