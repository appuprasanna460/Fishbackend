const mongoose = require('mongoose');

const buyMarketRateSchema = new mongoose.Schema({
    harbour: { type: String, required: true },
    rate: { type: Number, required: true },
    trend: { type: String, enum: ['↑', '↓', '→'], default: '→' }
}, { _id: false });

const sellMarketRateSchema = new mongoose.Schema({
    market: { type: String, required: true },
    rate: { type: Number, required: true },
    expenses: { type: Number, default: 0 },
    netMargin: { type: Number, default: 0 },
    marginPercentage: { type: Number, default: 0 }
}, { _id: false });

const priceHistorySchema = new mongoose.Schema({
    date: { type: String, required: true },
    price: { type: Number, required: true }
}, { _id: false });

const marketIntelligenceSchema = new mongoose.Schema({
    speciesName: {
        type: String,
        required: true,
        unique: true
    },
    currentRate: {
        type: Number,
        required: true
    },
    priceChange: {
        type: Number,
        default: 0
    },
    priceChangePercent: {
        type: Number,
        default: 0
    },
    avg7Days: {
        type: Number,
        default: 0
    },
    avg30Days: {
        type: Number,
        default: 0
    },
    todayHigh: {
        type: Number,
        default: 0
    },
    todayLow: {
        type: Number,
        default: 0
    },
    buyMarkets: [buyMarketRateSchema],
    sellMarkets: [sellMarketRateSchema],
    bestBuyHarbour: {
        type: String,
        default: ''
    },
    bestSellMarket: {
        type: String,
        default: ''
    },
    bestMarginPerKg: {
        type: Number,
        default: 0
    },
    historicalPrices: [priceHistorySchema]
}, {
    timestamps: true
});

marketIntelligenceSchema.index({ speciesName: 1 }, { unique: true });

const MarketIntelligence = mongoose.model('MarketIntelligence', marketIntelligenceSchema);
module.exports = MarketIntelligence;
