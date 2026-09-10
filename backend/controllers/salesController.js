const mongoose = require('mongoose');
const Sale = require('../models/saleModel');
const Stock = require('../models/stockModel');
const Receivable = require('../models/receivableModel');
const Customer = require('../models/customerModel');

// Helper to generate auto-incrementing sale and invoice numbers
const generateSaleNumbers = async (exporterId) => {
    const todayStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const count = await Sale.countDocuments({
        exporterId,
        createdAt: { $gte: new Date().setHours(0, 0, 0, 0) }
    });
    const seq = (count + 1).toString().padStart(4, '0');
    return {
        saleNumber: `SAL-${todayStr}-${seq}`,
        invoiceNumber: `INV-SAL-${todayStr}-${seq}`
    };
};

// GET /api/sales
exports.getSales = async (req, res, next) => {
    try {
        const { customerId, status, dispatchStatus, startDate, endDate } = req.query;
        let query = { exporterId: req.user.exporterId, isDeleted: false };

        if (customerId) query.customerId = customerId;
        if (status) query.status = status;
        if (dispatchStatus) query.dispatchStatus = dispatchStatus;

        if (startDate || endDate) {
            query.saleDate = {};
            if (startDate) query.saleDate.$gte = new Date(startDate);
            if (endDate) query.saleDate.$lte = new Date(endDate);
        }

        const sales = await Sale.find(query)
            .sort({ createdAt: -1 })
            .populate('customerId', 'name phone email')
            .populate('createdBy', 'name email');

        res.json({ success: true, count: sales.length, data: sales });
    } catch (error) {
        next(error);
    }
};

// GET /api/sales/:id
exports.getSaleById = async (req, res, next) => {
    try {
        const sale = await Sale.findOne({ _id: req.params.id, exporterId: req.user.exporterId })
            .populate('customerId', 'name phone email address')
            .populate('createdBy', 'name email');

        if (!sale || sale.isDeleted) {
            return res.status(404).json({ success: false, message: 'Sale order not found' });
        }

        res.json({ success: true, data: sale });
    } catch (error) {
        next(error);
    }
};

// POST /api/sales
exports.createSale = async (req, res, next) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const exporterId = req.user.exporterId;
        const {
            customerId,
            customerName: inputCustomerName,
            customerPhone,
            customerType,
            marketId,
            marketName,
            items,
            charges,
            discount,
            paymentMode,
            paymentTerms,
            amountReceived,
            notes,
            idempotencyKey
        } = req.body;

        if (!customerId || !items || !Array.isArray(items) || items.length === 0) {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({ success: false, message: 'Customer ID and sale items are required' });
        }

        // Validate customer
        let customer = await Customer.findOne({ _id: customerId, exporterId, isDeleted: false }).session(session);
        const resolvedCustomerName = customer ? customer.name : (inputCustomerName || 'Customer');

        // Check idempotencyKey if present
        if (idempotencyKey) {
            const existingSale = await Sale.findOne({ idempotencyKey, exporterId }).session(session);
            if (existingSale) {
                await session.commitTransaction();
                session.endSession();
                return res.json({ success: true, message: 'Sale already created', data: existingSale });
            }
        }

        // 1. Verify stock availability & stock exporterId matching
        let totalWeightKg = 0;
        let totalAmount = 0;

        for (const item of items) {
            if (!item.stockId) {
                await session.abortTransaction();
                session.endSession();
                return res.status(400).json({ success: false, message: `Every item must specify a valid stockId (${item.speciesName || 'Item'})` });
            }

            const stock = await Stock.findOne({ _id: item.stockId, exporterId }).session(session);
            if (!stock) {
                await session.abortTransaction();
                session.endSession();
                return res.status(400).json({ success: false, message: `Stock item not found or does not belong to exporter (${item.speciesName})` });
            }

            if (stock.availableWeightKg < item.weightKg) {
                await session.abortTransaction();
                session.endSession();
                return res.status(400).json({
                    success: false,
                    message: `Insufficient stock for ${item.speciesName} (${item.grade}). Requested: ${item.weightKg} KG, Available: ${stock.availableWeightKg} KG`
                });
            }

            totalWeightKg += item.weightKg;
            totalAmount += (item.weightKg * item.ratePerKg);
        }

        const totalCharges = charges ? (
            (charges.loadingCharge || 0) +
            (charges.marketCharge || 0) +
            (charges.transportationCharge || 0) +
            (charges.otherCharges || 0)
        ) : 0;

        const disc = discount || 0;
        const netAmount = totalAmount - disc + totalCharges;
        const received = amountReceived || 0;
        const balance = netAmount - received;

        let paymentStatus = 'PENDING';
        if (received >= netAmount) paymentStatus = 'PAID';
        else if (received > 0) paymentStatus = 'PART_PAID';

        const { saleNumber, invoiceNumber } = await generateSaleNumbers(exporterId);

        // 2. Format sale items
        const processedItems = items.map(item => ({
            stockId: item.stockId,
            speciesId: item.speciesId || null,
            speciesName: item.speciesName,
            grade: item.grade || 'STANDARD',
            boxes: item.boxes || 0,
            weightKg: item.weightKg,
            dispatchedQuantity: 0,
            ratePerKg: item.ratePerKg,
            amount: item.weightKg * item.ratePerKg,
            purchaseCost: item.purchaseCost || 0,
            margin: item.margin || 0
        }));

        const sale = new Sale({
            exporterId,
            ownerId: req.user._id,
            customerId,
            customerName: resolvedCustomerName,
            customerPhone: customerPhone || '',
            customerType: customerType || 'WHOLESALE_MARKET',
            saleNumber,
            invoiceNumber,
            marketId: marketId || null,
            marketName: marketName || '',
            items: processedItems,
            totalItems: processedItems.length,
            totalWeightKg,
            avgRatePerKg: totalWeightKg > 0 ? (totalAmount / totalWeightKg) : 0,
            totalAmount,
            charges: charges || { loadingCharge: 0, marketCharge: 0, transportationCharge: 0, otherCharges: 0 },
            discount: disc,
            netAmount,
            paymentMode: paymentMode || 'CREDIT',
            paymentTerms: paymentTerms || 'IMMEDIATE',
            amountReceived: received,
            balanceAmount: balance,
            paymentStatus,
            dispatchStatus: 'PENDING',
            status: 'CONFIRMED',
            notes: notes || '',
            createdBy: req.user._id
        });

        await sale.save({ session });

        // 3. Deduct stock inventory
        for (const item of items) {
            const stock = await Stock.findOne({ _id: item.stockId, exporterId }).session(session);
            if (stock) {
                stock.availableWeightKg = Math.max(0, stock.availableWeightKg - item.weightKg);
                stock.reservedWeightKg = (stock.reservedWeightKg || 0) + item.weightKg;
                await stock.save({ session });
            }
        }

        // 4. Create Receivable entry automatically
        const receivable = new Receivable({
            exporterId,
            customerId: sale.customerId,
            customerName: sale.customerName,
            saleId: sale._id,
            invoiceNumber: sale.invoiceNumber,
            invoiceDate: sale.saleDate,
            totalAmount: sale.netAmount,
            paidAmount: received,
            balanceAmount: balance,
            status: paymentStatus
        });
        if (received > 0) {
            receivable.paymentHistory.push({
                amount: received,
                paymentDate: new Date(),
                paymentMethod: paymentMode === 'CASH' ? 'CASH' : 'BANK_TRANSFER',
                notes: 'Advance/Initial payment at sale creation',
                recordedBy: req.user._id
            });
        }
        await receivable.save({ session });

        await session.commitTransaction();
        session.endSession();

        res.status(201).json({
            success: true,
            message: 'Sale created successfully, stock reduced, receivable generated',
            data: sale
        });
    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        next(error);
    }
};

// POST /api/sales/:id/cancel
exports.cancelSale = async (req, res, next) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const exporterId = req.user.exporterId;
        const sale = await Sale.findOne({ _id: req.params.id, exporterId }).session(session);

        if (!sale || sale.isDeleted) {
            await session.abortTransaction();
            session.endSession();
            return res.status(404).json({ success: false, message: 'Sale order not found' });
        }

        if (sale.status === 'CANCELLED') {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({ success: false, message: 'Sale order is already cancelled' });
        }

        if (sale.dispatchStatus === 'DISPATCHED' || sale.dispatchStatus === 'COMPLETED') {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({ success: false, message: 'Cannot cancel fully dispatched sale order' });
        }

        sale.status = 'CANCELLED';
        sale.dispatchStatus = 'CANCELLED';
        await sale.save({ session });

        // Restore stock
        for (const item of sale.items) {
            if (item.stockId) {
                const stock = await Stock.findOne({ _id: item.stockId, exporterId }).session(session);
                if (stock) {
                    const remainingWeight = item.weightKg - (item.dispatchedQuantity || 0);
                    if (remainingWeight > 0) {
                        stock.availableWeightKg += remainingWeight;
                        stock.reservedWeightKg = Math.max(0, (stock.reservedWeightKg || 0) - remainingWeight);
                        if (stock.status === 'CLOSED' || stock.status === 'RESERVED') {
                            stock.status = 'READY';
                        }
                        await stock.save({ session });
                    }
                }
            }
        }

        // Update receivable
        await Receivable.updateOne(
            { saleId: sale._id, exporterId },
            { status: 'OVERDUE', balanceAmount: 0 }
        ).session(session);

        await session.commitTransaction();
        session.endSession();

        res.json({ success: true, message: 'Sale cancelled and remaining stock restored', data: sale });
    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        next(error);
    }
};

// PATCH /api/sales/:id/status
exports.updateSaleStatus = async (req, res, next) => {
    try {
        const { status } = req.body;
        const sale = await Sale.findOne({ _id: req.params.id, exporterId: req.user.exporterId });

        if (!sale) {
            return res.status(404).json({ success: false, message: 'Sale order not found' });
        }

        sale.status = status;
        await sale.save();

        res.json({ success: true, message: 'Sale status updated', data: sale });
    } catch (error) {
        next(error);
    }
};

// GET /api/sales/summary
exports.getSalesSummary = async (req, res, next) => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const salesToday = await Sale.find({
            exporterId: req.user.exporterId,
            createdAt: { $gte: today },
            isDeleted: false,
            status: { $ne: 'CANCELLED' }
        });

        let totalValue = 0;
        let totalWeightKg = 0;
        salesToday.forEach(s => {
            totalValue += s.netAmount;
            totalWeightKg += s.totalWeightKg;
        });

        res.json({
            success: true,
            data: {
                totalValue,
                totalCount: salesToday.length,
                totalWeightKg,
                todaySales: salesToday
            }
        });
    } catch (error) {
        next(error);
    }
};
