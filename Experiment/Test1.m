yahooDataSetUp = YahooDataSetUp;
spreadSheetSetUp = SpreadSheetSetUp;
matFileSetUp = MatFileSetUp;
marketData = MarketData (yahooDataSetUp, spreadSheetSetUp, matFileSetUp);
marketData.loadSymbolMCapRef;
marketData.loadDataFromYahoo;


