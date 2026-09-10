const Purchase = require('../models/purchaseModel');
const Sale = require('../models/saleModel');
const Harbour = require('../models/harbourmodel');

// ── Helper: compute species-level market intel from real purchase & sale data ──
const computeMarketIntel = async (exporterId) => {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const day7Ago = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    const day30Ago = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);

    // Fetch last 30 days of purchases for this exporter
    const purchases = await Purchase.find({
        exporterId,
        isDeleted: { $ne: true },
        status: { $nin: ['CANCELLED', 'REVERSED'] },
        purchaseDate: { $gte: day30Ago }
    }).populate('harbourId', 'name').lean();

    // Fetch last 30 days of sales for this exporter
    const sales = await Sale.find({
        $or: [{ exporterId }, { ownerId: exporterId }],
        status: { $nin: ['CANCELLED', 'REVERSED'] },
        createdAt: { $gte: day30Ago }
    }).lean();

    // ── Group purchases by species ──────────────────────────────────────────
    const speciesMap = {};

    for (const p of purchases) {
        const harbourName = p.harbourId?.name || 'Unknown Harbour';
        for (const item of (p.items || [])) {
            const name = item.speciesName;
            if (!name) continue;

            if (!speciesMap[name]) {
                speciesMap[name] = {
                    speciesName: name,
                    purchaseRates: [],        // { rate, date, harbour }
                    harbourRates: {},          // { harbourName: [rates] }
                    sellRates: [],             // { rate, customerName, expenses }
                    todayRates: [],
                };
            }

            const ratePerKg = item.unit?.toUpperCase() === 'KG'
                ? item.ratePerUnit
                : (item.amount / Math.max(item.knownWeightKg || item.quantity, 0.01));

            speciesMap[name].purchaseRates.push({
                rate: ratePerKg,
                date: p.purchaseDate,
                harbour: harbourName
            });

            if (!speciesMap[name].harbourRates[harbourName]) {
                speciesMap[name].harbourRates[harbourName] = [];
            }
            speciesMap[name].harbourRates[harbourName].push(ratePerKg);

            // Today's rates
            if (new Date(p.purchaseDate) >= today) {
                speciesMap[name].todayRates.push(ratePerKg);
            }
        }
    }

    // ── Group sales by species ───────────────────────────────────────────────
    for (const s of sales) {
        for (const item of (s.items || [])) {
            const name = item.speciesName;
            if (!name || !speciesMap[name]) continue;

            speciesMap[name].sellRates.push({
                rate: item.ratePerKg || 0,
                customerName: s.customerName || 'Unknown',
                purchaseCost: item.purchaseCost || 0,
                margin: item.margin || 0,
            });
        }
    }

    // ── Build response per species ──────────────────────────────────────────
    const results = [];

    for (const [speciesName, data] of Object.entries(speciesMap)) {
        const allRates = data.purchaseRates.map(r => r.rate);
        if (allRates.length === 0) continue;

        // Current rate = most recent purchase rate
        const sorted = [...data.purchaseRates].sort((a, b) => new Date(b.date) - new Date(a.date));
        const currentRate = Math.round(sorted[0]?.rate || 0);

        // 7-day and 30-day averages
        const rates7d = data.purchaseRates
            .filter(r => new Date(r.date) >= day7Ago)
            .map(r => r.rate);
        const rates30d = allRates;

        const avg7Days = rates7d.length > 0
            ? Math.round(rates7d.reduce((s, r) => s + r, 0) / rates7d.length)
            : currentRate;
        const avg30Days = rates30d.length > 0
            ? Math.round(rates30d.reduce((s, r) => s + r, 0) / rates30d.length)
            : currentRate;

        // Price change (current vs 7-day avg)
        const priceChange = Math.round(currentRate - avg7Days);
        const priceChangePercent = avg7Days > 0
            ? Math.round((priceChange / avg7Days) * 100 * 100) / 100
            : 0;

        // Today's high/low
        const todayHigh = data.todayRates.length > 0 ? Math.round(Math.max(...data.todayRates)) : currentRate;
        const todayLow = data.todayRates.length > 0 ? Math.round(Math.min(...data.todayRates)) : currentRate;

        // ── Buy markets (harbour-wise avg rates) ────────────────────────────
        const buyMarkets = [];
        for (const [harbour, rates] of Object.entries(data.harbourRates)) {
            const avgRate = Math.round(rates.reduce((s, r) => s + r, 0) / rates.length);

            // Determine trend: compare first half vs second half
            let trend = '→';
            if (rates.length >= 2) {
                const mid = Math.floor(rates.length / 2);
                const firstHalf = rates.slice(0, mid).reduce((s, r) => s + r, 0) / mid;
                const secondHalf = rates.slice(mid).reduce((s, r) => s + r, 0) / (rates.length - mid);
                if (secondHalf > firstHalf * 1.02) trend = '↑';
                else if (secondHalf < firstHalf * 0.98) trend = '↓';
            }

            buyMarkets.push({ harbour, rate: avgRate, trend });
        }
        buyMarkets.sort((a, b) => a.rate - b.rate); // cheapest first

        // ── Sell markets (customer-wise avg rates + margins) ────────────────
        const customerRates = {};
        for (const sr of data.sellRates) {
            if (!customerRates[sr.customerName]) {
                customerRates[sr.customerName] = { rates: [], costs: [], margins: [] };
            }
            customerRates[sr.customerName].rates.push(sr.rate);
            customerRates[sr.customerName].costs.push(sr.purchaseCost);
            customerRates[sr.customerName].margins.push(sr.margin);
        }

        const sellMarkets = [];
        for (const [market, info] of Object.entries(customerRates)) {
            const avgSellRate = Math.round(info.rates.reduce((s, r) => s + r, 0) / info.rates.length);
            const avgCost = Math.round(info.costs.reduce((s, r) => s + r, 0) / info.costs.length);
            const expenses = Math.max(0, Math.round(avgSellRate * 0.08)); // estimate ~8% expenses
            const netMargin = avgSellRate - (buyMarkets[0]?.rate || currentRate) - expenses;
            const marginPercentage = avgSellRate > 0
                ? Math.round((netMargin / avgSellRate) * 100 * 10) / 10
                : 0;

            sellMarkets.push({
                market,
                rate: avgSellRate,
                expenses,
                netMargin: Math.round(netMargin),
                marginPercentage
            });
        }
        sellMarkets.sort((a, b) => b.netMargin - a.netMargin); // best margin first

        // ── Best buy/sell ───────────────────────────────────────────────────
        const bestBuyHarbour = buyMarkets.length > 0 ? buyMarkets[0].harbour : '';
        const bestSellMarket = sellMarkets.length > 0 ? sellMarkets[0].market : '';
        const bestMarginPerKg = sellMarkets.length > 0 ? sellMarkets[0].netMargin : 0;

        // ── Historical prices (daily averages for chart) ────────────────────
        const dailyMap = {};
        for (const r of data.purchaseRates) {
            const dateStr = new Date(r.date).toISOString().slice(0, 10);
            if (!dailyMap[dateStr]) dailyMap[dateStr] = [];
            dailyMap[dateStr].push(r.rate);
        }
        const historicalPrices = Object.entries(dailyMap)
            .sort(([a], [b]) => a.localeCompare(b))
            .map(([date, rates]) => ({
                date,
                price: Math.round(rates.reduce((s, r) => s + r, 0) / rates.length)
            }));

        results.push({
            speciesName,
            currentRate,
            priceChange,
            priceChangePercent,
            avg7Days,
            avg30Days,
            todayHigh,
            todayLow,
            buyMarkets,
            sellMarkets,
            bestBuyHarbour,
            bestSellMarket,
            bestMarginPerKg,
            historicalPrices
        });
    }

    // Sort by most purchases (most traded species first)
    results.sort((a, b) => b.historicalPrices.length - a.historicalPrices.length);
    return results;
};

// GET /api/market-intelligence/buy
exports.getBuyMarketRates = async (req, res) => {
    try {
        const exporterId = req.user?.exporterId || req.user?._id;
        if (!exporterId) {
            return res.status(400).json({ success: false, message: 'Exporter ID required' });
        }

        const data = await computeMarketIntel(exporterId);

        if (data.length === 0) {
            return res.json({
                success: true,
                data: [],
                message: 'No purchase data found. Start making purchases to see market intelligence.'
            });
        }

        res.json({ success: true, data });
    } catch (error) {
        console.error('Market Intelligence Error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
};

// GET /api/market-intelligence/sell
exports.getSellMarketRates = async (req, res) => {
    try {
        const exporterId = req.user?.exporterId || req.user?._id;
        if (!exporterId) {
            return res.status(400).json({ success: false, message: 'Exporter ID required' });
        }

        const data = await computeMarketIntel(exporterId);
        // Filter to only species that have sell data
        const sellData = data.filter(d => d.sellMarkets.length > 0);

        res.json({ success: true, data: sellData });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// GET /api/market-intelligence/trends
exports.getPriceTrends = async (req, res) => {
    try {
        const exporterId = req.user?.exporterId || req.user?._id;
        if (!exporterId) {
            return res.status(400).json({ success: false, message: 'Exporter ID required' });
        }

        const { speciesName } = req.query;
        const data = await computeMarketIntel(exporterId);

        if (speciesName) {
            const match = data.find(d => d.speciesName.toLowerCase().includes(speciesName.toLowerCase()));
            return res.json({
                success: true,
                data: match || { historicalPrices: [] }
            });
        }

        res.json({ success: true, data: data[0] || { historicalPrices: [] } });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// GET /api/market-intelligence/opportunity
exports.getBestOpportunity = async (req, res) => {
    try {
        const exporterId = req.user?.exporterId || req.user?._id;
        if (!exporterId) {
            return res.status(400).json({ success: false, message: 'Exporter ID required' });
        }

        const data = await computeMarketIntel(exporterId);
        const opportunities = data.map(d => ({
            speciesName: d.speciesName,
            bestBuyHarbour: d.bestBuyHarbour,
            bestSellMarket: d.bestSellMarket,
            currentRate: d.currentRate,
            bestMarginPerKg: d.bestMarginPerKg
        }));

        res.json({ success: true, data: opportunities });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
