const Receivable = require('../models/receivableModel');
const Payable = require('../models/payableModel');
const Expense = require('../models/expenseModel');
const Sale = require('../models/saleModel');
const Purchase = require('../models/purchaseModel');
const Customer = require('../models/customerModel');
const User = require('../models/usermodel');
const exporterReportService = require('../services/exporterReportService');

// GET /api/receivables
exports.getReceivables = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const { customerId, status } = req.query;
        let query = { exporterId };
        if (customerId) query.customerId = customerId;
        if (status && status !== 'ALL') query.status = status;

        const receivables = await Receivable.find(query)
            .sort({ createdAt: -1 })
            .populate('customerId', 'name phone email');

        let totalAmount = 0;
        let totalPaid = 0;
        let totalBalance = 0;
        let overdueCount = 0;

        receivables.forEach(r => {
            totalAmount += r.totalAmount;
            totalPaid += r.paidAmount;
            totalBalance += r.balanceAmount;
            if (r.status === 'OVERDUE') overdueCount++;
        });

        res.json({
            success: true,
            summary: { totalAmount, totalPaid, totalBalance, overdueCount },
            data: receivables
        });
    } catch (error) {
        next(error);
    }
};

// GET /api/finance/receivables/aging
exports.getReceivablesAging = async (req, res, next) => {
    try {
        const aging = await exporterReportService.getReceivablesAging(req.user.exporterId);
        res.json({ success: true, data: aging });
    } catch (error) {
        next(error);
    }
};

// POST /api/receivables/payment
exports.recordReceivablePayment = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const { receivableId, amount, paymentMethod, referenceNumber, notes } = req.body;

        if (!receivableId || !amount || amount <= 0 || !paymentMethod) {
            return res.status(400).json({ success: false, message: 'Receivable ID, valid amount, and payment method are required' });
        }

        const receivable = await Receivable.findOne({ _id: receivableId, exporterId });
        if (!receivable) {
            return res.status(404).json({ success: false, message: 'Receivable entry not found' });
        }

        if (amount > receivable.balanceAmount) {
            return res.status(400).json({
                success: false,
                message: `Payment amount ₹${amount} exceeds outstanding balance ₹${receivable.balanceAmount}`
            });
        }

        receivable.paidAmount += amount;
        receivable.balanceAmount = Math.max(0, receivable.totalAmount - receivable.paidAmount);

        if (receivable.balanceAmount === 0) {
            receivable.status = 'PAID';
        } else {
            receivable.status = 'PART_PAID';
        }

        receivable.paymentHistory.push({
            amount,
            paymentDate: new Date(),
            paymentMethod,
            referenceNumber: referenceNumber || '',
            notes: notes || '',
            recordedBy: req.user._id
        });

        await receivable.save();

        const sale = await Sale.findOne({ _id: receivable.saleId, exporterId });
        if (sale) {
            sale.amountReceived = receivable.paidAmount;
            sale.balanceAmount = receivable.balanceAmount;
            sale.paymentStatus = receivable.status;
            await sale.save();
        }

        res.json({
            success: true,
            message: 'Payment recorded successfully',
            data: receivable
        });
    } catch (error) {
        next(error);
    }
};

// GET /api/payables
exports.getPayables = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const { sellerId, status } = req.query;
        let query = { exporterId };
        if (sellerId) query.sellerId = sellerId;
        if (status && status !== 'ALL') query.status = status;

        // Auto-sync missing payables for non-cancelled purchases
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

        const payables = await Payable.find(query).sort({ createdAt: -1 });

        let totalAmount = 0;
        let totalPaid = 0;
        let totalBalance = 0;

        payables.forEach(p => {
            totalAmount += p.totalAmount;
            totalPaid += p.paidAmount;
            totalBalance += p.balanceAmount;
        });

        res.json({
            success: true,
            summary: { totalAmount, totalPaid, totalBalance },
            data: payables
        });
    } catch (error) {
        next(error);
    }
};

// GET /api/finance/payables/aging
exports.getPayablesAging = async (req, res, next) => {
    try {
        const aging = await exporterReportService.getPayablesAging(req.user.exporterId);
        res.json({ success: true, data: aging });
    } catch (error) {
        next(error);
    }
};

// POST /api/payables/payment
exports.recordPayablePayment = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const { payableId, amount, paymentMethod, referenceNumber, notes } = req.body;

        if (!payableId || !amount || amount <= 0 || !paymentMethod) {
            return res.status(400).json({ success: false, message: 'Payable ID, valid amount, and payment method are required' });
        }

        const payable = await Payable.findOne({ _id: payableId, exporterId });
        if (!payable) {
            return res.status(404).json({ success: false, message: 'Payable entry not found' });
        }

        if (amount > payable.balanceAmount) {
            return res.status(400).json({
                success: false,
                message: `Payment amount ₹${amount} exceeds outstanding balance ₹${payable.balanceAmount}`
            });
        }

        payable.paidAmount += amount;
        payable.balanceAmount = Math.max(0, payable.totalAmount - payable.paidAmount);

        if (payable.balanceAmount === 0) {
            payable.status = 'PAID';
        } else {
            payable.status = 'PART_PAID';
        }

        payable.paymentHistory.push({
            amount,
            paymentDate: new Date(),
            paymentMethod,
            referenceNumber: referenceNumber || '',
            notes: notes || ''
        });

        await payable.save();

        res.json({
            success: true,
            message: 'Supplier payment recorded successfully',
            data: payable
        });
    } catch (error) {
        next(error);
    }
};

// GET /api/finance/customers/:id/ledger
exports.getCustomerLedger = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const customerId = req.params.id;

        const customer = await Customer.findOne({ _id: customerId, exporterId });
        if (!customer) {
            return res.status(404).json({ success: false, message: 'Customer not found' });
        }

        const sales = await Sale.find({ customerId, exporterId, status: { $ne: 'CANCELLED' } }).lean();
        const receivables = await Receivable.find({ customerId, exporterId }).lean();

        const entries = [];

        sales.forEach(s => {
            entries.push({
                type: 'SALE_INVOICE',
                referenceNumber: s.invoiceNumber || s.saleNumber,
                date: s.saleDate,
                debit: s.netAmount,
                credit: 0,
                notes: `Sale Order #${s.saleNumber}`
            });
        });

        receivables.forEach(r => {
            (r.paymentHistory || []).forEach(p => {
                entries.push({
                    type: 'PAYMENT_RECEIVED',
                    referenceNumber: p.referenceNumber || r.invoiceNumber,
                    date: p.paymentDate,
                    debit: 0,
                    credit: p.amount,
                    notes: `Payment via ${p.paymentMethod} - ${p.notes}`
                });
            });
        });

        entries.sort((a, b) => new Date(a.date) - new Date(b.date));

        let runningBalance = 0;
        entries.forEach(e => {
            runningBalance += (e.debit - e.credit);
            e.balance = runningBalance;
        });

        res.json({
            success: true,
            data: {
                customer,
                closingBalance: runningBalance,
                ledger: entries
            }
        });
    } catch (error) {
        next(error);
    }
};

// GET /api/finance/suppliers/:id/ledger
exports.getSupplierLedger = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const supplierId = req.params.id;

        const purchases = await Purchase.find({ sellerId: supplierId, exporterId, status: { $ne: 'CANCELLED' } }).lean();
        const payables = await Payable.find({ sellerId: supplierId, exporterId }).lean();

        const entries = [];

        purchases.forEach(p => {
            entries.push({
                type: 'PURCHASE_BILL',
                referenceNumber: p.purchaseNumber,
                date: p.purchaseDate,
                debit: 0,
                credit: p.totalAmount,
                notes: `Purchase Bill #${p.purchaseNumber}`
            });
        });

        payables.forEach(p => {
            (p.paymentHistory || []).forEach(pay => {
                entries.push({
                    type: 'PAYMENT_MADE',
                    referenceNumber: pay.referenceNumber || p.purchaseNumber,
                    date: pay.paymentDate,
                    debit: pay.amount,
                    credit: 0,
                    notes: `Payment via ${pay.paymentMethod}`
                });
            });
        });

        entries.sort((a, b) => new Date(a.date) - new Date(b.date));

        let runningBalance = 0;
        entries.forEach(e => {
            runningBalance += (e.credit - e.debit);
            e.balance = runningBalance;
        });

        res.json({
            success: true,
            data: {
                supplierId,
                closingBalance: runningBalance,
                ledger: entries
            }
        });
    } catch (error) {
        next(error);
    }
};

// GET /api/finance/pl
exports.getPLReport = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const { period, startDate, endDate } = req.query;
        let dateQuery = {};

        const now = new Date();

        if (period) {
            switch (period.toUpperCase()) {
                case 'TODAY':
                    const startToday = new Date(now);
                    startToday.setHours(0, 0, 0, 0);
                    dateQuery = { $gte: startToday };
                    break;
                case 'THIS_WEEK':
                    const startWeek = new Date(now);
                    startWeek.setDate(now.getDate() - now.getDay());
                    startWeek.setHours(0, 0, 0, 0);
                    dateQuery = { $gte: startWeek };
                    break;
                case 'THIS_MONTH':
                    const startMonth = new Date(now.getFullYear(), now.getMonth(), 1);
                    dateQuery = { $gte: startMonth };
                    break;
                case 'THIS_QUARTER':
                    const quarterMonth = Math.floor(now.getMonth() / 3) * 3;
                    const startQuarter = new Date(now.getFullYear(), quarterMonth, 1);
                    dateQuery = { $gte: startQuarter };
                    break;
                case 'THIS_YEAR':
                    const startYear = new Date(now.getFullYear(), 0, 1);
                    dateQuery = { $gte: startYear };
                    break;
                case 'CUSTOM':
                    if (startDate) dateQuery.$gte = new Date(startDate);
                    if (endDate) {
                        const end = new Date(endDate);
                        end.setHours(23, 59, 59, 999);
                        dateQuery.$lte = end;
                    }
                    break;
            }
        } else if (startDate || endDate) {
            if (startDate) dateQuery.$gte = new Date(startDate);
            if (endDate) {
                const end = new Date(endDate);
                end.setHours(23, 59, 59, 999);
                dateQuery.$lte = end;
            }
        }

        const hasDateQuery = Object.keys(dateQuery).length > 0;

        // Aggregate Purchases
        const purchaseQuery = { exporterId, isDeleted: false, status: { $ne: 'CANCELLED' } };
        if (hasDateQuery) purchaseQuery.purchaseDate = dateQuery;
        const purchases = await Purchase.find(purchaseQuery);

        let totalPurchase = 0;
        purchases.forEach(p => totalPurchase += p.totalAmount);

        // Aggregate Sales
        const salesQuery = { exporterId, isDeleted: false, status: { $ne: 'CANCELLED' } };
        if (hasDateQuery) salesQuery.saleDate = dateQuery;
        const sales = await Sale.find(salesQuery);

        let totalSales = 0;
        sales.forEach(s => totalSales += s.netAmount);

        // Aggregate Expenses
        const expenseQuery = { exporterId };
        if (hasDateQuery) expenseQuery.date = dateQuery;
        const expenses = await Expense.find(expenseQuery);

        let totalExpenses = 0;
        const expenseBreakdown = {};
        expenses.forEach(e => {
            totalExpenses += e.amount;
            expenseBreakdown[e.category] = (expenseBreakdown[e.category] || 0) + e.amount;
        });

        const grossProfit = totalSales - totalPurchase;
        const netProfit = grossProfit - totalExpenses;
        const netMargin = totalSales > 0 ? ((netProfit / totalSales) * 100).toFixed(1) : 0;

        // Species-wise P&L aggregation
        const speciesMap = {};
        sales.forEach(s => {
            s.items.forEach(item => {
                const name = item.speciesName;
                if (!speciesMap[name]) {
                    speciesMap[name] = { purchase: 0, sales: 0, profit: 0, margin: 0 };
                }
                speciesMap[name].sales += item.amount;
                speciesMap[name].purchase += (item.purchaseCost || (item.amount * 0.75));
            });
        });

        const speciesBreakdown = Object.keys(speciesMap).map(sp => {
            const data = speciesMap[sp];
            const profit = data.sales - data.purchase;
            const margin = data.sales > 0 ? ((profit / data.sales) * 100).toFixed(1) : 0;
            return {
                species: sp,
                purchase: data.purchase,
                sales: data.sales,
                profit,
                margin: `${margin}%`
            };
        });

        // Market-wise P&L aggregation
        const marketMap = {};
        sales.forEach(s => {
            const m = s.marketName || 'General Market';
            if (!marketMap[m]) {
                marketMap[m] = { sales: 0, cost: 0, profit: 0, margin: 0 };
            }
            marketMap[m].sales += s.netAmount;
            marketMap[m].cost += (s.totalAmount * 0.78);
        });

        const marketBreakdown = Object.keys(marketMap).map(mk => {
            const data = marketMap[mk];
            const profit = data.sales - data.cost;
            const margin = data.sales > 0 ? ((profit / data.sales) * 100).toFixed(1) : 0;
            return {
                market: mk,
                sales: data.sales,
                cost: data.cost,
                profit,
                margin: `${margin}%`
            };
        });

        const summaryData = {
            totalPurchase,
            totalSales,
            grossProfit,
            operatingExpenses: totalExpenses,
            netProfit,
            netMargin: `${netMargin}%`
        };

        res.json({
            success: true,
            summary: summaryData,
            speciesBreakdown,
            marketBreakdown,
            expenseBreakdown,
            data: {
                summary: summaryData,
                speciesBreakdown,
                marketBreakdown,
                expenseBreakdown
            }
        });
    } catch (error) {
        next(error);
    }
};

// POST /api/expenses
exports.addExpense = async (req, res, next) => {
    try {
        const { category, amount, date, paymentMethod, notes, attachmentUrl } = req.body;

        if (!category || !amount || amount <= 0) {
            return res.status(400).json({ success: false, message: 'Expense category and valid amount are required' });
        }

        const expense = new Expense({
            exporterId: req.user.exporterId,
            category,
            amount,
            date: date ? new Date(date) : new Date(),
            staffId: req.user._id,
            paymentMethod: paymentMethod || 'CASH',
            notes: notes || '',
            attachmentUrl: attachmentUrl || ''
        });

        await expense.save();

        res.status(201).json({ success: true, message: 'Expense added successfully', data: expense });
    } catch (error) {
        next(error);
    }
};
