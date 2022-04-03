% function paramSetWFA = setUpWFAParam(marketData, inputArgs)
% %WFASetUp is to store all set up required to to a walk-forward analysis
%
% input arguments:
%
% output arguments:

%===============================================================================================

arguments 
    % market data
    marketData struct

    % WFA specific set up
    inputArgs.nWalk             = 1; % Number of walk for the whole walk forwad
    inputArgs.maxLookbackData   = 300; % lookback upper bound
    inputArgs.nstepTrain        = 250; % Number of step for training datastasket
    inputArgs.nstepTest         = 20; % Number of step for testing dataset

    % btEngineSetUp
    inputArgs.tradingCost                           = [0.15/100, 0.25/100];
    inputArgs.maxCapAllocation                      = 1/5;
    inputArgs.initialAssetValue {mustBePositive}    = 10^4;

    % optimization set up
    inputArgs.maxFcnEval = 180; % must be multiplication of 6 >> 6 cores CPU

    % nlConstParam
    inputArgs.maxLookbackConst                              = 250; 
    inputArgs.maxDDThreshold {mustBeNumeric}                = -30/100;
    inputArgs.minSharpeRatio {mustBeNumeric}                = 1.5;
    inputArgs.minPortRet {mustBeNumeric}                    = 1.1;
    
    inputArgs.minDailyRetThreshold {mustBeNumeric}          = -30/100;
    inputArgs.minLast20DRetThreshold {mustBeNumeric}        = -25/100;
    inputArgs.minLast60DRetThreshold {mustBeNumeric}        = -15/100;
    inputArgs.minLast200DRetThreshold {mustBeNumeric}       = -5/100;

    inputArgs.minAvgDailyRet                                = 0.0/100;
    inputArgs.minAvg20DaysRet                               = 0/100;
    inputArgs.minAvg60DaysRet                               = 0/100;
    inputArgs.minNStepTestRet                               = 1.02;

    inputArgs.backShiftNDay {mustBeNumeric, mustBeInteger}  = 1;

end 

%===============================================================================================

%% intermediate & preparation calcuation

% setUp extracted from market data
optimLookbackStep = inputArgs.nstepTrain;

%% number of required nDataRow
nstepWalk = inputArgs.nWalk*inputArgs.nstepTest + inputArgs.maxLookbackData + inputArgs.nstepTrain;
additionalData = inputArgs.nstepTest; % additional data for safety required data
nRowRequired = nstepWalk+additionalData;

nRowAvailable = size(marketData.priceVolumeData{1},1);
validIf = nRowAvailable < nRowRequired;
if validIf
    error(message('WFA:backtest:nRowAvailable < nRowRequired'));
end


% transfer input data
maxLookbackData  = inputArgs.maxLookbackData;
nstepTrain  = inputArgs.nstepTrain;
nstepTest   = inputArgs.nstepTest;
nWalk       = inputArgs.nWalk;

dataInputRaw   = marketData.priceVolumeData;
dataInput = cleanDataFcn(dataInputRaw);
clear dataInputRaw

% idx for start and end of test steps
nRowAvailable = size(dataInput{1},1);
lastEndStepTest = nRowAvailable;
% lastStartStepTest = lastEndStepTest - nstepTest +1;
firstEndStepTest = lastEndStepTest - (nWalk-1)*nstepTest;
% firstStartStepTest = firstEndStepTest - nstepTest +1;

endStepTest = (firstEndStepTest:nstepTest:lastEndStepTest)';
startStepTest= endStepTest - nstepTest +1;

% idx for start and end of train steps
endStepTrain = startStepTest-1;
startStepTrain = endStepTrain - nstepTrain+1;

% idx for start and end of lookback steps
endStepLookbackTrain = startStepTrain-1;
startStepLookbackTrain = endStepLookbackTrain - maxLookbackData+1;

endStepLookbackTest = startStepTest-1;
startStepLookbackTest = endStepLookbackTest - maxLookbackData+1;

% determine index and timecolumn for each step and walk
timeCol = dataInput{1}.Time;
% nRow = numel(timeCol);

% create walkPeriodTable
Walk = (1:inputArgs.nWalk)';
startDateLookbackTrain = timeCol(startStepLookbackTrain);
endDateLookbackTrain = timeCol(endStepLookbackTrain);
startDateTrain = timeCol(startStepTrain);
endDateTrain = timeCol(endStepTrain);

startDateLookbackTest = timeCol(startStepLookbackTest);
endDateLookbackTest = timeCol(endStepLookbackTest);
startDateTest = timeCol(startStepTest);
endDateTest = timeCol(endStepTest);

walkPeriodTable = table(Walk, startStepLookbackTrain, endStepLookbackTrain,...
    startStepTrain, endStepTrain, startStepLookbackTest, endStepLookbackTest,...
    startStepTest, endStepTest, startDateLookbackTrain, endDateLookbackTrain,...
    startDateTrain, endDateTrain, startDateLookbackTest, endDateLookbackTest,...
    startDateTest, endDateTest);



%% create walkMCapTable: walk for each MCap

% uniqMktCap
mktCapCateg     = marketData.marketCapCategory;
symbols         = mktCapCateg.Properties.VariableNames;
uniqMktCap      = unique(mktCapCateg.Variables);
uniqMktCap (ismissing(uniqMktCap)) = [];
uniqMktCap      = sort(uniqMktCap);



% symList for each walk
nWalk           = inputArgs.nWalk;
walk            = walkPeriodTable.Walk;
endDateTrain    = walkPeriodTable.endDateTrain;

varTable        = array2table(zeros(nWalk, numel(symbols)));
walkSymTable    = table2timetable([table(endDateTrain, walk), varTable]);
walkSymTable.Properties.VariableNames(2:end) = symbols;

walkMCapTable   = cell(1,numel(uniqMktCap));

% preallocate nSym per walk for each mCap   
nColumn = 1+numel(uniqMktCap);
walkMCapNSymTable = walkSymTable(:,1:nColumn);
walkMCapNSymTable.Properties.VariableNames(2:end) = uniqMktCap';
walkMCapNSymTable(:,2:end).Variables = zeros(size(walkMCapNSymTable(:,2:end).Variables ));


% walkSymTable
for mCapIdx = 1:numel(uniqMktCap)
    mCap    = uniqMktCap(mCapIdx);

    symMCap = strcat(symbols,"_",uniqMktCap(mCapIdx));
    walkTableMCapIdx = walkSymTable;
    walkTableMCapIdx.Properties.VariableNames(2:end) = symMCap;

    for walkIdx = 1:nWalk

        rowTime = endDateTrain(walkIdx);

        mktCapCategIdx = mktCapCateg(rowTime,:).Variables;
        walkTableMCapIdx(rowTime,2:end).Variables = mktCapCategIdx==mCap;

        walkMCapNSymTable(rowTime,mCap).Variables = sum(walkTableMCapIdx(rowTime,2:end).Variables);

    end

    walkMCapTable{mCapIdx} = walkTableMCapIdx;

end

clear mktCapCateg


% optimParamSetUp
maxLookbackConst = inputArgs.maxLookbackConst;
lbubConst =...
    [               % open the array
    20, 800         % volumeMATreshold = x(1)/100 ; % input #1
    10, maxLookbackConst % volumeMALookback = x(2) ; % input #2
    1,  100          % valueThreshold = x(3)*10^7 ; % input #3 in Rp hundreds million
    1,  20          % valueLookback = x(4) ; % input #4 nDays
    1,  20          % volumeValueBufferDays = x(5) ; % input #5
    1,  20          % priceRetLowCloseThresh = x(6)/100 ; % input #6
    40, 800          % priceMAThreshold = x(7)/100 ; % input #7
    1,  40          % priceMALookback = x(8) ; % input #8
    1,  20          % priceVolumeValueBufferDays = x(9) ; % input #9
    1,  20          % cutLossLookback = x(10) ; % input #10
    0,  10           % cutLossPct = x(11)/100 ; % input #11
    ] ;             % close the array

nVars = size(lbubConst, 1);

%===========================================================================================

%% results

% WFA specific set up
paramSetWFA.nWalk               = inputArgs.nWalk ; % Number of walk for the whole walk forwad
paramSetWFA.maxLookbackData     = inputArgs.maxLookbackData; % maxLookback data
paramSetWFA.nstepTrain          = inputArgs.nstepTrain; % Number of step for training datastasket
paramSetWFA.nstepTest           = inputArgs.nstepTest; % Number of step for testing dataset
paramSetWFA.walkPeriodTable     = walkPeriodTable;
paramSetWFA.walkMCapNSymTable   = walkMCapNSymTable;
paramSetWFA.walkMCapTable       = walkMCapTable;
paramSetWFA.uniqMktCap          = uniqMktCap;

% btEngineSetUp
paramSetWFA.tradingCost         = inputArgs.tradingCost;
paramSetWFA.maxCapAllocation    = inputArgs.maxCapAllocation;
paramSetWFA.backShiftNDay       = inputArgs.backShiftNDay ;
paramSetWFA.initialAssetValue   = inputArgs.initialAssetValue ;

% optimization set up
paramSetWFA.maxFcnEval          = inputArgs.maxFcnEval;
paramSetWFA.nVars               = nVars;
paramSetWFA.optimLookbackStep   = optimLookbackStep;

% nlConstParam
paramSetWFA.maxDDThreshold          = inputArgs.maxDDThreshold ;
paramSetWFA.minPortRet              = inputArgs.minPortRet ;
paramSetWFA.minDailyRetThreshold    = inputArgs.minDailyRetThreshold;
paramSetWFA.minLast20DRetThreshold  = inputArgs.minLast20DRetThreshold ;
paramSetWFA.minLast60DRetThreshold  = inputArgs.minLast60DRetThreshold ;
paramSetWFA.minLast200DRetThreshold = inputArgs.minLast200DRetThreshold ;

paramSetWFA.lbubConst               = lbubConst;
paramSetWFA.nVars                   = nVars;
paramSetWFA.minSharpeRatio          = inputArgs.minSharpeRatio;

paramSetWFA.minAvgDailyRet          = inputArgs.minAvgDailyRet;
paramSetWFA.minAvg20DaysRet         = inputArgs.minAvg20DaysRet;
paramSetWFA.minAvg60DaysRet         = inputArgs.minAvg60DaysRet;
paramSetWFA.minNStepTestRet         = inputArgs.minNStepTestRet ;
%===============================================================================================

%% end of function

clearvars -except paramSetWFA 

% end 
