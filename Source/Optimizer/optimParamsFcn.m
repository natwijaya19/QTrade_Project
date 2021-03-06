function optimStructOut = optimParamsFcn (dataInput, paramSetWFA)

% optimParamsFcn - function for parameter optimization
% USAGE:
%
%       optimParams = optimParamsFcn (tradingSignalParam, dataStructInput,...
%                   optimLookbackStep, tradingCost, maxCapAllocation,...
%                   maxDDThreshold, minPortfolioReturn, minDailyRetThreshold)
%


%% argument validation
arguments
    dataInput cell
    paramSetWFA struct
end

%=========================================================================

%% paralel pool
pool = gcp('nocreate'); % Check whether a parallel pool exists
if isempty(pool) % If not, create one
    pool = parpool;
end

N = pool.NumWorkers;
useParallel = true;

% sample input args
% optimizedParameter
% backtest the signal
% dataStructInput = dataInput;
% tradingCost = [0.15/100, 0.25/100];
% maxCapAllocation = 0.2;
% optimLookbackStep = 250*7;
% maxDDThreshold = -0.50;
% minPortfolioReturn = 1.10;
% minDailyRetThreshold = -0.20;
% maxFcnEval = 24;
%% transfer variable value

LBUBConst = paramSetWFA.lbubConst;
nVars = paramSetWFA.nVars;
maxFcnEval = paramSetWFA.maxFcnEval;
minPortRet = paramSetWFA.minPortRet;

%% define function handle of objectiveFcn and nonLinearConstraintFcn

objFcn = @(x)objectiveFcn (x, dataInput, paramSetWFA);

nlconst = @(x)nonLinearConstraintFcn (x, dataInput, paramSetWFA);

objconstr = packfcn(objFcn,nlconst) ;
F = objconstr ;

%% define other constrains
intConst = 1:nVars;

LB = LBUBConst(:,1)';
UB = LBUBConst(:,2)';

%% setup optimization options
options = optimoptions('surrogateopt','PlotFcn',"surrogateoptplot", ...
    "ConstraintTolerance",1e-3, "UseParallel", useParallel,...
    "UseVectorized",true,"MaxFunctionEvaluations", maxFcnEval, "BatchUpdateInterval", N);

% 

%% call surrogateopt to solve the problem
[sol,fval,exitflag,output] = surrogateopt(F,LB,UB,intConst,options) ;

textDisp = strcat("exitflag: ",string(exitflag));
disp(textDisp);

%% put UB into tradingSignalParam if FVal < minPortfolioReturn

validIF = exitflag==0;
if validIF
    optimizedTradingSignalParam = sol ;
else
    optimizedTradingSignalParam = UB ;
end
%% wrap up for output
optimStructOut.optimizedTradingSignalParam = optimizedTradingSignalParam;
optimStructOut.fval = fval;
optimStructOut.exitflag = exitflag;
optimStructOut.output = output;


clearvars -except optimStructOut
end