const Purchase = require('../models/purchaseModel');
const PurchaseLot = require('../models/purchaseLotModel');
const Stock = require('../models/stockModel');
const Sale = require('../models/saleModel');
const Dispatch = require('../models/dispatchModel');
const Expense = require('../models/expenseModel');
const Receivable = require('../models/receivableModel');
const Payable = require('../models/payableModel');

const getDashboard = async (exporterId) => {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    // 1. Today Purchase Value
    const todayPurchases = await Purchase.aggregate([
        {
            $match: {
                exporterId,
                status: { $ne: 'CANCELLED' },
                purchaseDate: { $gte: startOfDay, $lte: endOfDay }
            }
        },
        {
            $group: {
                _id: null,
                totalValue: { $sum: '$totalAmount' }
            }
        }
    ]);
    const todayPurchaseValue = todayPurchases.length > 0 ? todayPurchases[0].totalValue : 0;

    // 2. Today Sales Value
    const todaySales = await Sale.aggregate([
        {
            $match: {
                exporterId,
                status: { $ne: 'CANCELLED' },
                saleDate: { $gte: startOfDay, $lte: endOfDay }
            }
        },
        {
            $group: {
                _id: null,
                totalValue: { $sum: '$netAmount' }
            }
        }
    ]);
    const todaySalesValue = todaySales.length > 0 ? todaySales[0].totalValue : 0;

    // 3. Available Stock Kg + Active Lots Count
    const stockAgg = await Stock.aggregate([
        {
            $match: {
                exporterId,
                status: 'READY'
            }
        },
        {
            $group: {
                _id: null,
                totalWeight: { $sum: '$availableWeightKg' }
            }
        }
    ]);
    const availableStockKg = stockAgg.length > 0 ? stockAgg[0].totalWeight : 0;

    const activeLotsCount = await PurchaseLot.countDocuments({
        exporterId,
        status: { $in: ['PENDING', 'RECEIVING', 'WEIGHED'] }
    });

    // 4. Pending Receiving
    const pendingReceiving = await PurchaseLot.countDocuments({
        exporterId,
        status: { $in: ['PENDING', 'RECEIVING'] }
    });

    // 5. Pending Dispatch
    const pendingDispatch = await Sale.countDocuments({
        exporterId,
        dispatchStatus: { $in: ['PENDING', 'PARTIAL'] },
        status: { $ne: 'CANCELLED' }
    });

    // 6. Customer Receivables
    const recAgg = await Receivable.aggregate([
        {
            $match: {
                exporterId,
                status: { $in: ['PENDING', 'PARTIAL', 'OVERDUE'] }
            }
        },
        {
            $group: {
                _id: null,
                totalBalance: { $sum: '$balanceAmount' }
            }
        }
    ]);
    const customerReceivables = recAgg.length > 0 ? recAgg[0].totalBalance : 0;

    // 7. Supplier Payables
    const payAgg = await Payable.aggregate([
        {
            $match: {
                exporterId,
                status: { $in: ['PENDING', 'PART_PAID'] }
            }
        },
        {
            $group: {
                _id: null,
                totalBalance: { $sum: '$balanceAmount' }
            }
        }
    ]);
    const supplierPayables = payAgg.length > 0 ? payAgg[0].totalBalance : 0;

    // 8. Today Expenses
    const expAgg = await Expense.aggregate([
        {
            $match: {
                exporterId,
                date: { $gte: startOfDay, $lte: endOfDay }
            }
        },
        {
            $group: {
                _id: null,
                totalAmount: { $sum: '$amount' }
            }
        }
    ]);
    const todayExpenses = expAgg.length > 0 ? expAgg[0].totalAmount : 0;

    // 9. Staff Purchase Activity
    const staffPurchaseActivity = await Purchase.aggregate([
        {
            $match: {
                exporterId,
                status: { $ne: 'CANCELLED' },
                purchaseDate: { $gte: startOfDay, $lte: endOfDay }
            }
        },
        {
            $group: {
                _id: '$purchaseStaffId',
                staffName: { $first: '$purchaseStaffName' },
                totalPurchases: { $sum: 1 },
                totalValue: { $sum: '$totalAmount' }
            }
        }
    ]);

    // Recent Activity (last 10 merged purchases and sales)
    const recentPurchases = await Purchase.find({ exporterId }).sort({ createdAt: -1 }).limit(10).lean();
    const recentSales = await Sale.find({ exporterId }).sort({ createdAt: -1 }).limit(10).lean();

    const mergedActivity = [
        ...recentPurchases.map(p => ({
            type: 'PURCHASE',
            title: `Purchase #${p.purchaseNumber} from ${p.sellerName}`,
            amount: p.totalAmount,
            status: p.status,
            date: p.createdAt || p.purchaseDate
        })),
        ...recentSales.map(s => ({
            type: 'SALE',
            title: `Sale #${s.saleNumber} to ${s.customerName}`,
            amount: s.netAmount,
            status: s.status,
            date: s.createdAt || s.saleDate
        }))
    ].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 10);

    return {
        todayPurchaseValue,
        todaySalesValue,
        availableStockKg,
        activeLotsCount,
        pendingReceiving,
        pendingDispatch,
        customerReceivables,
        supplierPayables,
        todayExpenses,
        staffPurchaseActivity,
        recentActivity: mergedActivity
    };
};

module.exports = {
    getDashboard
};
