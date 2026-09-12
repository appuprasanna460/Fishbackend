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

    // 0. Auto-sync missing Payables & Receivables for consistency
    try {
        const existingPurchases = await Purchase.find({ exporterId, isDeleted: false, status: { $ne: 'CANCELLED' } });
        for (const p of existingPurchases) {
            const exists = await Payable.findOne({ purchaseId: p._id, exporterId });
            if (!exists) {
                await Payable.create({
                    exporterId,
                    sellerId: p.sellerId || null,
                    sellerName: p.sellerName,
                    purchaseId: p._id,
                    purchaseNumber: p.purchaseNumber,
                    totalAmount: p.totalAmount,
                    paidAmount: 0,
                    balanceAmount: p.totalAmount,
                    status: 'PENDING',
                    createdAt: p.createdAt || p.purchaseDate
                });
            }
        }

        const existingSales = await Sale.find({ exporterId, isDeleted: false, status: { $ne: 'CANCELLED' } });
        for (const s of existingSales) {
            const exists = await Receivable.findOne({ saleId: s._id, exporterId });
            if (!exists) {
                const total = s.netAmount || s.totalAmount || 0;
                const paid = s.amountReceived || 0;
                const bal = s.balanceAmount !== undefined ? s.balanceAmount : Math.max(0, total - paid);
                await Receivable.create({
                    exporterId,
                    customerId: s.customerId || null,
                    customerName: s.customerName,
                    saleId: s._id,
                    invoiceNumber: s.invoiceNumber || s.saleNumber,
                    saleNumber: s.saleNumber,
                    totalAmount: total,
                    paidAmount: paid,
                    balanceAmount: bal,
                    dueDate: s.dueDate || s.saleDate,
                    status: bal === 0 ? 'PAID' : 'PENDING',
                    createdAt: s.createdAt || s.saleDate
                });
            }
        }
    } catch (err) {
        console.error('Error auto-syncing payables/receivables in dashboard:', err);
    }

    // 1. Today Purchase Value (or Total Non-Cancelled Purchase Value if today is 0)
    const todayPurchases = await Purchase.aggregate([
        {
            $match: {
                exporterId,
                status: { $ne: 'CANCELLED' },
                $or: [
                    { purchaseDate: { $gte: startOfDay, $lte: endOfDay } },
                    { createdAt: { $gte: startOfDay, $lte: endOfDay } }
                ]
            }
        },
        {
            $group: {
                _id: null,
                totalValue: { $sum: '$totalAmount' }
            }
        }
    ]);
    let todayPurchaseValue = todayPurchases.length > 0 ? todayPurchases[0].totalValue : 0;

    if (todayPurchaseValue === 0) {
        const totalPurchasesAgg = await Purchase.aggregate([
            {
                $match: {
                    exporterId,
                    status: { $ne: 'CANCELLED' }
                }
            },
            {
                $group: {
                    _id: null,
                    totalValue: { $sum: '$totalAmount' }
                }
            }
        ]);
        if (totalPurchasesAgg.length > 0) {
            todayPurchaseValue = totalPurchasesAgg[0].totalValue;
        }
    }

    // 2. Today Sales Value
    const todaySales = await Sale.aggregate([
        {
            $match: {
                exporterId,
                status: { $ne: 'CANCELLED' },
                $or: [
                    { saleDate: { $gte: startOfDay, $lte: endOfDay } },
                    { createdAt: { $gte: startOfDay, $lte: endOfDay } }
                ]
            }
        },
        {
            $group: {
                _id: null,
                totalValue: { $sum: '$netAmount' }
            }
        }
    ]);
    let todaySalesValue = todaySales.length > 0 ? todaySales[0].totalValue : 0;

    if (todaySalesValue === 0) {
        const totalSalesAgg = await Sale.aggregate([
            {
                $match: {
                    exporterId,
                    status: { $ne: 'CANCELLED' }
                }
            },
            {
                $group: {
                    _id: null,
                    totalValue: { $sum: '$netAmount' }
                }
            }
        ]);
        if (totalSalesAgg.length > 0) {
            todaySalesValue = totalSalesAgg[0].totalValue;
        }
    }

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
                status: { $ne: 'PAID' }
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
                status: { $ne: 'PAID' }
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
