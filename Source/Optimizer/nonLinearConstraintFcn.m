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
optimLookbackStep           = paramSetWFA.optimLookbackStep;
nstepTest                   = paramSetWFA.nstepTest;
minSharpeRatio              = paramSetWFA.minSharpeRatio;
maxDDThreshold              = paramSetWFA.maxDDThreshold;
minPortRet                  = paramSetWFA.minPortRet;
minDailyRetThreshold        = paramSetWFA.minDailyRetThreshold;
minLast20DRetThreshold      = paramSetWFA.minLast20DRetThreshold ;
minLast60DRetThreshold      = paramSetWFA.minLast60DRetThreshold ;
minLast200DRetThreshold     = paramSetWFA.minLast200DRetThreshold ;
minAvgDailyRet              = paramSetWFA.minAvgDailyRet;
minAvg20DaysRet             = paramSetWFA.minAvg20DaysRet;
minAvg60DaysRet             = paramSetWFA.minAvg60DaysRet;
minNStepTestRet             = paramSetWFA.minNStepTestRet;

% generate signal
tradingSignalOut = tradeSignalShortMomFcn (tradingSignalParam, dataInput);

% backtest the signal against the price
tradingSignalIn = tradingSignalOut;
clear tradingSignalOut

resultStruct = btEngineVectFcn(dataInput, tradingSignalIn,paramSetWFA);
clear dataInput tradingSignalIn paramSetWFA

%% calcluate return for the given  optimLookbackWindow minPortfolioReturn
equityCurvePortVar = resultStruct.equityCurvePortfolioTT.Variables;
equityCurvePortVar = equityCurvePortVar(end-optimLookbackStep+1: end,:);
equityCurvePortVar = string(equityCurvePortVar);
equityCurvePortVar = double(equityCurvePortVar);
equityCurvePortVar = fillmissing(equityCurvePortVar, "previous");

startOptimPortValue = equityCurvePortVar(1);
endOptimPortValue = equityCurvePortVar(end);
cumPortfolioReturn = endOptimPortValue / startOptimPortValue;
cumPortfolioReturn(isnan(cumPortfolioReturn)) = 0;
cumPortfolioReturn(isinf(cumPortfolioReturn)) = 0;
clear endOptimPortValue startOptimPortValue

%% Risk-reward ratios
risklessAssetRet = 0 ;
dailyNetRetPort = resultStruct.dailyNetRetPortfolioTT.Variables;
dailyNetRetPort  = dailyNetRetPort(end-optimLookbackStep+1: end,:);
sharpeRatio = sharpe(dailyNetRetPort, risklessAssetRet) *sqrt (252);
sharpeRatio(isnan(sharpeRatio)) = 0 ;
sharpeRatio(isinf(sharpeRatio)) = 0 ;
clear dailyNetRetPortfolioTT

%% calculate maxDD for maxDDThreshold
equityCurvePortVar = resultStruct.equityCurvePortfolioTT.Variables;
equityCurvePortVar = equityCurvePortVar(end-optimLookbackStep+1: end,:);
maxDD = -maxdrawdown(equityCurvePortVar);

%% calculate dailyRet for minDailyRetThreshold
equityCurvePortVar = resultStruct.equityCurvePortfolioTT.Variables;
dailyRet = tick2ret(equityCurvePortVar);
dailyRet = dailyRet(end-optimLookbackStep+1: end,:);
dailyRet(isnan(dailyRet)) = 0;
DailyRetMin = min(dailyRet);
% clear dailyRet

%==========================================================================

%% Last 20 days return
nDays = 20;
equityCurvePortVar = resultStruct.equityCurvePortfolioTT.Variables;
portCumRet = equityCurvePortVar;
Last20DRet = equityCurvePortVar ;

if numel (portCumRet) <= nDays
    Last20DRetMin = 0;
else

    Last20DRet(nDays+1:end,:) = (portCumRet(nDays+1:end,:) ./ portCumRet(1:end-nDays,:))-1;
    Last20DRet(1:nDays,:) = [] ;
    Last20DRet (isnan(Last20DRet)) = 0 ;
    Last20DRet (isnan(Last20DRet)) = 0 ;
    Last20DRet (isinf(Last20DRet)) = 0 ;
    Last20DRet  = Last20DRet (end-optimLookbackStep+1: end,:);
    Last20DRetMin = min(Last20DRet);

end
% clear Last20DRet

%==========================================================================

%% Last 20 days return
nDays = 60;
equityCurvePortVar = resultStruct.equityCurvePortfolioTT.Variables;
portCumRet = equityCurvePortVar;
Last60DRet = equityCurvePortVar ;

if numel (portCumRet) <= nDays
    Last60DRetMin = 0;
else

    Last60DRet(nDays+1:end,:) = (portCumRet(nDays+1:end,:) ./ portCumRet(1:end-nDays,:))-1;
    Last60DRet(1:nDays,:) = [] ;
    Last60DRet (isnan(Last60DRet)) = 0 ;
    Last60DRet (isnan(Last60DRet)) = 0 ;
    Last60DRet (isinf(Last60DRet)) = 0 ;
    Last60DRet  = Last60DRet (end-optimLookbackStep+1: end,:);
    Last60DRetMin = min(Last60DRet);

end

% clear Last60DRet
%==========================================================================

%% Last 200 days return
nDays = 200;
equityCurvePortVar = resultStruct.equityCurvePortfolioTT.Variables;
portCumRet = equityCurvePortVar;
Last200DRet = equityCurvePortVar ;

if numel (portCumRet) <= nDays
    Last200DRetMin = 0;
else

    Last200DRet(nDays+1:end,:) = (portCumRet(nDays+1:end,:) ./ portCumRet(1:end-nDays,:))-1;
    Last200DRet(1:nDays,:) = [] ;
    Last200DRet (isnan(Last200DRet)) = 0 ;
    Last200DRet (isnan(Last200DRet)) = 0 ;
    Last200DRet (isinf(Last200DRet)) = 0 ;
    Last200DRet  = Last200DRet (end-optimLookbackStep+1: end,:);
    Last200DRetMin = min(Last200DRet);

end

% clear equityCurvePortfolioVar Last200DRet

%==========================================================================


%% minAvgRetConst
avgDailyRet     = mean(dailyRet);
avg20DaysRet    = mean(Last20DRet);
avg60DaysRet    = mean(Last200DRet);

nstepTestRet    = equityCurvePortVar(end,:) ./ equityCurvePortVar(end-nstepTest+1,:) ;

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

    minAvgDailyRet - avgDailyRet;
    minAvg20DaysRet - avg20DaysRet;
    minAvg60DaysRet - avg60DaysRet;

    minNStepTestRet - nstepTestRet;
    ];

ceq = [];

%==========================================================================

clearvars -except c eq

end
