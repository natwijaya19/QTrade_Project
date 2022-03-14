function btResults = btEngineVectFcn (dataInputBT, tradeSignalInput, paramSetWFA)

% backtesterEngineFcn generate output backtesting signal against price
%
% USAGE:
%
%       resultStruct = btEngineVectorizedFcn (dataStructInput, tradingSignal, tradingCost, maxCapAllocation)
%
% Input arguments
% dataStructInput struct - consist of openPrice and closePrice in timetable class
% tradingSignal timetable - tradingSIgnal in timetable
% tradingCosts timetable - tradingCost = [buyCost, sellCost]
% maxCapAllocPerSym double - max capital allocation per symbol in each day to
%   maintain diversification


%TODO to be removed or commented
% path = "C:\Users\kikim\OneDrive\Documents\MATLAB_Projects\BackTradeModule_Project\DataInput";
% fileName = "PriceVolumeInput.mat";
% fullFileName = fullfile(path, fileName);
% dataInput = load(fullFileName); % struct data transfer
%
% tradingSignalParameter = [
%     40  %1
%     200 %2
%     5   %3
%     5   %4
%     10  %5
%     8   %6
%     120 %7
%     20  %8
%     5   %9
%     8   %10
%     5   %11
%     ]
%

%================================================================================

%% argument validation
arguments
    dataInputBT cell
    tradeSignalInput timetable
    paramSetWFA struct

end

%================================================================================

%% data transfer
%TODO finalize the data transfer
openPrice = dataInputBT{1};
closePrice = dataInputBT{4};

backShiftNDay = paramSetWFA.backShiftNDay;
tradingCost = paramSetWFA.tradingCost;
maxCapAllocation = paramSetWFA.maxCapAllocation;

symbols = string(closePrice.Properties.VariableNames);
symbols = strrep(symbols,"_close","");

maxCapAllocPerSym = maxCapAllocation;
buyCost = tradingCost(1);
sellCost = tradingCost(2);

% backShift the signal
tradingSignal = tradeSignalInput;
tradingSignal.Variables = backShiftFcn (tradeSignalInput.Variables , backShiftNDay);

clearvars dataInputBT paramSetWFA

%================================================================================

%% data preparation
openPriceVar = openPrice.Variables;
openPriceVar = string(openPriceVar);
openPriceVar = double(openPriceVar);
openPriceVar(isnan(openPriceVar)) = 0;

closePriceVar = closePrice.Variables;
closePriceVar = string(closePriceVar);
closePriceVar = double(closePriceVar);
closePriceVar(isnan(closePriceVar)) = 0;

signal = tradingSignal;
signalVar = signal.Variables;
signalVar = string(signalVar);
signalVar = double(signalVar);
signalVar(isnan(signalVar)) = 0;

clearvars tradingSignal 

%================================================================================

%% calculate number of asset with signal to buy
nSignalDaily = sum(signalVar,2);
%------------------------------------------------------------------------

% start of day (SOD): calclate max capital allocation to be invested and cash
maxCapAllocPerSym;
capAlloc = ones(numel(nSignalDaily),1);
capAlloc = capAlloc ./ nSignalDaily;
capAlloc(isinf(capAlloc)) = 0;
capAlloc(isnan(capAlloc)) = 0;

capAlloc(capAlloc > maxCapAllocPerSym) = maxCapAllocPerSym;

%================================================================================


%% calculate capitalAllocation in start of day to be invested to each symbols to buy and to sell.
%   equally weighted capital allocation is use used
capAllocPerSym = signalVar .* capAlloc;

sodTotalAsset = ones(numel(nSignalDaily),1);
sodInvestedCapitalPerSym = capAllocPerSym;
sodTotalInvestedCapital = sum(sodInvestedCapitalPerSym,2);
sodCash = sodTotalAsset - sum(sodInvestedCapitalPerSym,2);

clearvars sodTotalInvestedCapital
%------------------------------------------------------------------------


%buySellPortion
% sz = size(signalVar);
% buySellPortion = zeros(sz)
buySellPortion = capAllocPerSym;
buySellPortion(2:end,:) = capAllocPerSym(2:end,:) - capAllocPerSym(1:end-1,:);
%------------------------------------------------------------------------


% invested value from BuyPortion
sodGrossBuyPortion = buySellPortion;
sodGrossBuyPortion(sodGrossBuyPortion < 0 ) = 0;

% sellCost from SellPortion
sodGrossSellPortion = buySellPortion;
sodGrossSellPortion(sodGrossSellPortion> 0 ) = 0;
sodGrossSellPortion = -1 .* sodGrossSellPortion;

% invested value from prevRemain
sz = size(signalVar);
sodPrevRemainPortion = zeros(sz);
sodPrevRemainPortion(2:end,:) = capAllocPerSym(1:end-1,:) - sodGrossSellPortion(2:end,:);

clearvars capAlloc capAllocPerSym buySellPortion

%================================================================================

%% calculate net invested value from buy portion at the end of day eodNetBuyPortion
% sodGrossBuyPortion will experience the effect of buyCost,
% dailyRet (closeToClosePriceRet) and slippageCost (closeToOpenPriceRet)
buyCost;
sodGrossBuyPortion;

% sodGrossBuyPortion contain both buyCostPortion and sodNetBuyPortion
sodNetBuyPortion = sodGrossBuyPortion ./ (1+buyCost);
sodNetBuyPortion(isnan(sodNetBuyPortion)) = 0;
buyCostPortion = sodGrossBuyPortion - sodNetBuyPortion;

clearvars sodGrossBuyPortion

% closeToClosePriceRet is dailyRet without slippage
closeToClosePriceRet = zeros(size(signalVar));
closeToClosePriceRet(2:end,:) = (closePriceVar(2:end,:) ./ closePriceVar(1:end-1,:)) - 1;
closeToClosePriceRet(isnan(closeToClosePriceRet)) = 0;
closeToClosePriceRet(isinf(closeToClosePriceRet)) = 0;

%slippage priceRet from last trading day close price to open price in the start of day
closeToOpenPriceRet = zeros(size(signalVar));
closeToOpenPriceRet(2:end,:) = (openPriceVar(2:end,:) ./ closePriceVar(1:end-1,:)) - 1;
closeToOpenPriceRet(isnan(closeToOpenPriceRet)) = 0;
closeToOpenPriceRet(isinf(closeToOpenPriceRet)) = 0;

% netPriceRet after slippage is closeToClosePriceRet minus by closeToOpenPrice
% netPriceRetAfterSlippage = closeToClosePriceRet - closeToOpenPrice
netPriceRetAfterSlippage = closeToClosePriceRet - closeToOpenPriceRet;

% eodNetBuyPortion at athe end of day is
eodNetBuyPortion = sodNetBuyPortion .* (1+netPriceRetAfterSlippage);

slippageCostOfSodNetBuyPortion = sodNetBuyPortion .* closeToOpenPriceRet;
dailySlippageCostOfSodNetBuyPortion = sum(slippageCostOfSodNetBuyPortion,2);
totalSlippageCostOfSodNetBuyPortion = sum(dailySlippageCostOfSodNetBuyPortion);

%================================================================================

%% calculate net invested value at the end of day from prevRemainPortion.
% prevRemainPortion will only have the effect of dailyRet (closeToClosePriceRet)
sodPrevRemainPortion;

% closeToClosePriceRet is dailyRet without slippage
closeToClosePriceRet = zeros(size(signalVar));
closeToClosePriceRet(2:end,:) = (closePriceVar(2:end,:) ./ closePriceVar(1:end-1,:)) - 1;
closeToClosePriceRet(isnan(closeToClosePriceRet)) = 0;
closeToClosePriceRet(isinf(closeToClosePriceRet)) = 0;

eodPrevRemainPortion = sodPrevRemainPortion .*(1+closeToClosePriceRet);

clearvars sodPrevRemainPortion closeToClosePriceRet
%================================================================================

%% calculate sellCostPortion from sodGrossSellPortion. This portion will
% have the effect of slippage and sellCost. sellCost is the only cost will be
% included into the eod asset calc.
sodGrossSellPortion;
sellCost;

% slippageCost
% slippage priceRet from last trading day close price to open price in the start of day
%TODO remove NAN
closeToOpenPriceRet = zeros(size(signalVar));
closeToOpenPriceRet(2:end,:) = (openPriceVar(2:end,:) ./ closePriceVar(1:end-1,:)) - 1;
closeToOpenPriceRet(isnan(closeToOpenPriceRet)) = 0;
closeToOpenPriceRet(isinf(closeToOpenPriceRet)) = 0;

sodGrossSellPortionAtOpenPrice = sodGrossSellPortion .* (closeToOpenPriceRet+1);
sodNetSellPortionAfterSellCost = sodGrossSellPortionAtOpenPrice ./ (1+sellCost);

sellCostPortion = sodGrossSellPortionAtOpenPrice - sodNetSellPortionAfterSellCost;
totalDailySellCostPortion = sum(sellCostPortion,2);

slippageCostOfGrossSellPortion = sodGrossSellPortionAtOpenPrice - sodGrossSellPortion;
dailySlippageCostOfGrossSellPortion = sum(slippageCostOfGrossSellPortion,2);
totalSlippageCostOfGrossSellPortion = sum(dailySlippageCostOfGrossSellPortion);

clearvars signalVar sodGrossSellPortion closeToOpenPriceRet sodGrossSellPortionAtOpenPrice 
clearvars slippageCostOfGrossSellPortion dailySlippageCostOfGrossSellPortion
%================================================================================

%% calculate end of day (EOD) invested capital
eodInvestedCapital = eodNetBuyPortion + eodPrevRemainPortion;
eodTotalInvestedCapital = sum(eodInvestedCapital,2);

clearvars eodInvestedCapital

% calculate total asset = invested capital + cash at the end of day (EOD)
eodCash = sodCash;
totalDailySellCostPortion;
eodTotalAsset = eodCash + eodTotalInvestedCapital - totalDailySellCostPortion;

clearvars eodTotalInvestedCapital

% calculate daily return dailyRet
dailyNetRetPortfolio = (eodTotalAsset ./ sodTotalAsset) - 1;
dailyNetRetPortfolio = string(dailyNetRetPortfolio);
dailyNetRetPortfolio = double(dailyNetRetPortfolio);
dailyNetRetPortfolio (isnan(dailyNetRetPortfolio)) = 0;
dailyNetRetPortfolio (isinf(dailyNetRetPortfolio)) = 0;

timeCol = openPrice.Time;
nRow = size(nSignalDaily,1);
nCol = size(nSignalDaily,2);
sz = [nRow, nCol];
variableTypes = repmat({'double'},1, nCol);
variableNames = "dailyNetRetPortfolio";
TT = timetable('Size', sz, 'VariableTypes', variableTypes,...
    'RowTimes', timeCol, 'VariableNames', variableNames);

dailyNetRetPortfolioTT = TT;
dailyNetRetPortfolioTT.Variables = dailyNetRetPortfolio;
btResults.dailyNetRetPortfolioTT = dailyNetRetPortfolioTT;

clearvars sodTotalAsset totalDailySellCostPortion eodTotalAsset dailyNetRetPortfolioTT

% equityCurvePortfolio
equityCurvePortfolio = ret2tick (dailyNetRetPortfolio);
equityCurvePortfolio(1,:) = [];
equityCurvePortfolio = string(equityCurvePortfolio);
equityCurvePortfolio = double(equityCurvePortfolio);
equityCurvePortfolio = fillmissing(equityCurvePortfolio, "previous");

% put equityCurvePortfolio into timetable
timeCol = openPrice.Time;
nRow = size(nSignalDaily,1);
nCol = size(nSignalDaily,2);
sz = [nRow, nCol];
variableTypes = repmat({'double'},1, nCol);
variableNames = "equityCurvePortfolio";
TT = timetable('Size', sz, 'VariableTypes', variableTypes,...
    'RowTimes', timeCol, 'VariableNames', variableNames);

equityCurvePortfolioTT = TT;
equityCurvePortfolioTT.Variables = equityCurvePortfolio;
btResults.equityCurvePortfolioTT = equityCurvePortfolioTT;

clearvars nSignalDaily dailyNetRetPortfolio equityCurvePortfolioTT

%================================================================================

%% dailyNetRetPerSym can be calculated buy taking into account the
% sellCostPortion per symbol
eodInvestedCapitalPerSym = eodNetBuyPortion + eodPrevRemainPortion - sellCostPortion ;
dailyNetRetPerSym = (eodInvestedCapitalPerSym ./ sodInvestedCapitalPerSym) - 1 ;
dailyNetRetPerSym(isnan(dailyNetRetPerSym)) = 0;
dailyNetRetPerSym(isinf(dailyNetRetPerSym)) = 0;

clearvars sodInvestedCapitalPerSym eodInvestedCapitalPerSym eodPrevRemainPortion

%================================================================================

%% wrap up the result output packed in a data struct resultStruct
% assume 1 is invested at beginning o the signal
% dailyNetRetPerSym
timeCol = openPrice.Time;
nRow = size(openPriceVar,1);
nCol = size(openPriceVar,2);
variableTypes = repmat({'double'},1, nCol);
sz = [nRow, nCol];
variableNames = string(signal.Properties.VariableNames);
TT = timetable('Size', sz, 'VariableTypes', variableTypes,...
    'RowTimes', timeCol, 'VariableNames', variableNames);

dailyNetRetPerSymTT = TT;
dailyNetRetPerSymTT.Variables = dailyNetRetPerSym;
dailyNetRetPerSymTT.Properties.VariableNames = symbols;
btResults.dailyNetRetPerSymTT = dailyNetRetPerSymTT;

clearvars dailyNetRetPerSymTT

% equityCurvePerSym
equityCurvePerSym = ret2tick(dailyNetRetPerSym);
equityCurvePerSym(1,:) = [];
equityCurvePerSymTT = openPrice;
equityCurvePerSymTT.Variables = equityCurvePerSym;
equityCurvePerSymTT.Properties.VariableNames = symbols;
btResults.equityCurvePerSymTT = equityCurvePerSymTT;

clearvars equityCurvePerSym equityCurvePerSymTT symbols

%================================================================================

% totalBuyCost
buyCostPortion;
DailyBuyCost = sum(buyCostPortion,2);
totalDailyBuyCost = DailyBuyCost .* equityCurvePortfolio;
totalBuyCost = sum(totalDailyBuyCost) ;
btResults.totalBuyCost = totalBuyCost;

clearvars DailyBuyCost totalDailyBuyCost totalBuyCost

% totalSellCost
sellCostPortion;
dailySellCost = sum(sellCostPortion,2);
totalDailySellCost =  dailySellCost .* equityCurvePortfolio;
totalSellCost = sum(totalDailySellCost);
btResults.totalSellCost = totalSellCost;

% totalSlippage
totalSlippageCost = totalSlippageCostOfSodNetBuyPortion + totalSlippageCostOfGrossSellPortion ;
btResults.totalSlippageCost = totalSlippageCost;

clearvars sodNetBuyPortion equityCurvePortfolio sellCostPortion dailySellCost 
clearvars totalDailySellCost totalSellCost totalSlippageCost
%================================================================================

% TODO summary statistics


%================================================================================

%%

clearvars -except btResults

end