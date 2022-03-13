function Fval = objectiveFcn (tradingSignalParam, dataInputBT, paramSetWFA)
    %
    % USAGE:
    %       Fval = objectiveFcn (tradingSignalParam, dataStructInput, optimLookbackStep)
    %
    % input argument:
    %   tradingSignalParam      vector array    :   1xnVars
    %   dataStructInput         struct          :   field openPrice, highPrice, lowPrice, 
    %                                               highPrice and volume. All these data are in timetable               
    %   optimLookbackStep       scalar          :   nStep lookback for total return calculation
    
    % prepare data input
    % tradingSignalParam = tradingSignalParameter;
    optimLookbackStep = paramSetWFA.lookbackUB;

    
    % generate signal
    tradingSignalOut = tradeSignalShortMomFcn (tradingSignalParam, dataInputBT);
    
    % backtest the signal against the price
    tradeSignalInput = tradingSignalOut;
    resultStruct = btEngineEventDrivenFcn(dataInputBT, tradeSignalInput, paramSetWFA);
    
    % calculate equityCurve at for the evaluation
    equityCurvePortfolioVar_raw = resultStruct.equityCurvePortfolioTT.Variables;
    equityCurvePortfolioVar = equityCurvePortfolioVar_raw(end-optimLookbackStep: end);
    
    % % calcluate return for the given  optimLookbackWindow
    startOptimPortValue = equityCurvePortfolioVar(1);
    endOptimPortValue = equityCurvePortfolioVar(end);
    cumPortfolioReturn = endOptimPortValue / startOptimPortValue;
    cumPortfolioReturn(isnan(cumPortfolioReturn)) = 0;
    
    Fval = -cumPortfolioReturn;
    
    clearvars -except Fval


end
%---------------------------------------------------------------------------------------

