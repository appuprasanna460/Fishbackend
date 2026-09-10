const Purchase = require('../models/purchaseModel');
const PurchaseLot = require('../models/purchaseLotModel');
const Sale = require('../models/saleModel');
const Expense = require('../models/expenseModel');
const Receivable = require('../models/receivableModel');
const Payable = require('../models/payableModel');
const Stock = require('../models/stockModel');
const Dispatch = require('../models/dispatchModel');

const parseDateFilter = (dateRange = {}) => {
    const filter = {};
    if (dateRange.fromDate) {
        filter.$gte = new Date(dateRange.fromDate);
    }
    if (dateRange.toDate) {
        const end = new Date(dateRange.toDate);
        end.setHours(23, 59, 59, 999);
        filter.$lte = end;
    }
    return Object.keys(filter).length > 0 ? filter : null;
};

const getPurchaseRegister = async (exporterId, { fromDate, toDate } = {}) => {
    const query = { exporterId, status: { $ne: 'CANCELLED' } };
    const dateFilter = parseDateFilter({ fromDate, toDate });
    if (dateFilter) {
        query.purchaseDate = dateFilter;
    }
    const purchases = await Purchase.find(query).sort({ purchaseDate: -1 }).lean();
    const totalValue = purchases.reduce((sum, p) => sum + (p.totalAmount || 0), 0);
    return { purchases, totalCount: purchases.length, totalValue };
};

const getSalesRegister = async (exporterId, { fromDate, toDate } = {}) => {
    const query = { exporterId, status: { $ne: 'CANCELLED' } };
    const dateFilter = parseDateFilter({ fromDate, toDate });
    if (dateFilter) {
        query.saleDate = dateFilter;
    }
    const sales = await Sale.find(query).sort({ saleDate: -1 }).lean();
    const totalValue = sales.reduce((sum, s) => sum + (s.netAmount || 0), 0);
    return { sales, totalCount: sales.length, totalValue };
};

const getSpeciesWisePL = async (exporterId, dateRange = {}) => {
    const saleQuery = { exporterId, status: { $ne: 'CANCELLED' } };
    const dateFilter = parseDateFilter(dateRange);
    if (dateFilter) {
        saleQuery.saleDate = dateFilter;
    }

    const sales = await Sale.find(saleQuery).lean();

    const speciesMap = {};
    sales.forEach(sale => {
        (sale.items || []).forEach(item => {
            const key = item.speciesName || 'Unknown';
            if (!speciesMap[key]) {
                speciesMap[key] = {
                    speciesName: key,
                    totalSalesWeightKg: 0,
                    totalSalesRevenue: 0,
                    totalPurchaseCost: 0,
                    margin: 0
                };
            }
            speciesMap[key].totalSalesWeightKg += (item.weightKg || 0);
            speciesMap[key].totalSalesRevenue += (item.amount || 0);
            speciesMap[key].totalPurchaseCost += (item.purchaseCost || 0);
            speciesMap[key].margin += (item.margin || (item.amount - item.purchaseCost));
        });
    });

    const breakdown = Object.values(speciesMap);
    const summary = breakdown.reduce((acc, curr) => {
        acc.totalSalesRevenue += curr.totalSalesRevenue;
        acc.totalPurchaseCost += curr.totalPurchaseCost;
        acc.totalMargin += curr.margin;
        return acc;
    }, { totalSalesRevenue: 0, totalPurchaseCost: 0, totalMargin: 0 });

    return { summary, speciesBreakdown: breakdown };
};

const getStaffWisePurchases = async (exporterId, dateRange = {}) => {
    const match = { exporterId, status: { $ne: 'CANCELLED' } };
    const dateFilter = parseDateFilter(dateRange);
    if (dateFilter) {
        match.purchaseDate = dateFilter;
    }

    const result = await Purchase.aggregate([
        { $match: match },
        {
            $group: {
                _id: '$purchaseStaffId',
                staffName: { $first: '$purchaseStaffName' },
                totalPurchases: { $sum: 1 },
                totalAmount: { $sum: '$totalAmount' }
            }
        },
        { $sort: { totalAmount: -1 } }
    ]);

    return result;
};

const getUnitWiseAnalysis = async (exporterId, dateRange = {}) => {
    const match = { exporterId, status: { $ne: 'CANCELLED' } };
    const dateFilter = parseDateFilter(dateRange);
    if (dateFilter) {
        match.purchaseDate = dateFilter;
    }

    const result = await Purchase.aggregate([
        { $match: match },
        { $unwind: '$items' },
        {
            $group: {
                _id: '$items.unit',
                unit: { $first: '$items.unit' },
                totalQuantity: { $sum: '$items.quantity' },
                totalAmount: { $sum: '$items.amount' },
                count: { $sum: 1 }
            }
        },
        { $sort: { totalAmount: -1 } }
    ]);

    return result;
};

const getLotTraceability = async (exporterId, lotId) => {
    const lot = await PurchaseLot.findOne({ _id: lotId, exporterId }).lean();
    if (!lot) {
        throw new Error('Purchase lot not found');
    }

    const purchase = await Purchase.findOne({ _id: lot.purchaseId }).lean();
    const stocks = await Stock.find({ exporterId, lotIds: lot._id }).lean();
    const stockIds = stocks.map(s => s._id);
    const sales = await Sale.find({ exporterId, 'items.stockId': { $in: stockIds } }).lean();
    const saleIds = sales.map(s => s._id);
    const dispatches = await Dispatch.find({ exporterId, sales: { $in: saleIds } }).lean();

    return {
        lot,
        sourcePurchase: purchase,
        inventoryStocks: stocks,
        sales,
        dispatches
    };
};

const getReceivablesAging = async (exporterId) => {
    const receivables = await Receivable.find({ exporterId, status: { $ne: 'PAID' } }).lean();
    const now = new Date();

    const aging = {
        current: 0,
        days1_30: 0,
        days31_60: 0,
        days61_90: 0,
        days90Plus: 0,
        total: 0,
        records: []
    };

    receivables.forEach(r => {
        const due = r.dueDate ? new Date(r.dueDate) : new Date(r.invoiceDate);
        const diffTime = now - due;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        const balance = r.balanceAmount || 0;

        aging.total += balance;
        if (diffDays <= 0) {
            aging.current += balance;
        } else if (diffDays <= 30) {
            aging.days1_30 += balance;
        } else if (diffDays <= 60) {
            aging.days31_60 += balance;
        } else if (diffDays <= 90) {
            aging.days61_90 += balance;
        } else {
            aging.days90Plus += balance;
        }

        aging.records.push({
            ...r,
            diffDays: diffDays > 0 ? diffDays : 0
        });
    });

    return aging;
};

const getPayablesAging = async (exporterId) => {
    const payables = await Payable.find({ exporterId, status: { $ne: 'PAID' } }).lean();
    const now = new Date();

    const aging = {
        current: 0,
        days1_30: 0,
        days31_60: 0,
        days61_90: 0,
        days90Plus: 0,
        total: 0,
        records: []
    };

    payables.forEach(p => {
        const due = p.dueDate ? new Date(p.dueDate) : new Date(p.createdAt);
        const diffTime = now - due;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        const balance = p.balanceAmount || 0;

        aging.total += balance;
        if (diffDays <= 0) {
            aging.current += balance;
        } else if (diffDays <= 30) {
            aging.days1_30 += balance;
        } else if (diffDays <= 60) {
            aging.days31_60 += balance;
        } else if (diffDays <= 90) {
            aging.days61_90 += balance;
        } else {
            aging.days90Plus += balance;
        }

        aging.records.push({
            ...p,
            diffDays: diffDays > 0 ? diffDays : 0
        });
    });

    return aging;
};

const getExpenseReport = async (exporterId, dateRange = {}) => {
    const match = { exporterId };
    const dateFilter = parseDateFilter(dateRange);
    if (dateFilter) {
        match.date = dateFilter;
    }

    const expenses = await Expense.find(match).sort({ date: -1 }).lean();

    const categorySummary = await Expense.aggregate([
        { $match: match },
        {
            $group: {
                _id: '$category',
                category: { $first: '$category' },
                totalAmount: { $sum: '$amount' },
                count: { $sum: 1 }
            }
        },
        { $sort: { totalAmount: -1 } }
    ]);

    const totalExpense = expenses.reduce((sum, e) => sum + (e.amount || 0), 0);

    return { expenses, categorySummary, totalExpense };
};

module.exports = {
    getPurchaseRegister,
    getSalesRegister,
    getSpeciesWisePL,
    getStaffWisePurchases,
    getUnitWiseAnalysis,
    getLotTraceability,
    getReceivablesAging,
    getPayablesAging,
    getExpenseReport
};
