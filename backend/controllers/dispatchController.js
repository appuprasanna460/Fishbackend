const mongoose = require('mongoose');
const Dispatch = require('../models/dispatchModel');
const Sale = require('../models/saleModel');

// Helper to generate auto-incrementing trip code
const generateTripCode = async (exporterId) => {
    const todayStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const count = await Dispatch.countDocuments({
        exporterId,
        createdAt: { $gte: new Date().setHours(0, 0, 0, 0) }
    });
    return `TRP-${todayStr}-${(count + 1).toString().padStart(4, '0')}`;
};

// GET /api/dispatch
exports.getDispatches = async (req, res, next) => {
    try {
        const { status } = req.query;
        let query = { exporterId: req.user.exporterId };
        if (status) query.status = status;

        const dispatches = await Dispatch.find(query)
            .sort({ createdAt: -1 })
            .populate('sales');

        res.json({ success: true, count: dispatches.length, data: dispatches });
    } catch (error) {
        next(error);
    }
};

// POST /api/dispatch
exports.createDispatch = async (req, res, next) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const exporterId = req.user.exporterId;
        const {
            vehicleNumber,
            vehicleType,
            driverName,
            driverPhone,
            saleIds,
            drops,
            marketFreight,
            idempotencyKey
        } = req.body;

        if (!vehicleNumber || !driverName || !driverPhone || !saleIds || !Array.isArray(saleIds) || saleIds.length === 0) {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({ success: false, message: 'Vehicle, driver, and valid sale order references are required' });
        }

        // Idempotency check
        if (idempotencyKey) {
            const existingDispatch = await Dispatch.findOne({ idempotencyKey, exporterId }).session(session);
            if (existingDispatch) {
                await session.commitTransaction();
                session.endSession();
                return res.json({ success: true, message: 'Dispatch already created', data: existingDispatch });
            }
        }

        // Verify sales
        const sales = await Sale.find({ _id: { $in: saleIds }, exporterId, isDeleted: false }).session(session);
        if (sales.length !== saleIds.length) {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({ success: false, message: 'One or more sales were not found or do not belong to exporter' });
        }

        let serverTotalBoxes = 0;
        let serverTotalWeightKg = 0;
        const dispatchItems = [];

        for (const sale of sales) {
            if (sale.dispatchStatus !== 'PENDING' && sale.dispatchStatus !== 'PARTIAL') {
                await session.abortTransaction();
                session.endSession();
                return res.status(400).json({ success: false, message: `Sale ${sale.saleNumber} has invalid status '${sale.dispatchStatus}' for dispatch` });
            }

            sale.items.forEach(item => {
                serverTotalBoxes += (item.boxes || 0);
                serverTotalWeightKg += (item.weightKg - (item.dispatchedQuantity || 0));
                dispatchItems.push({
                    saleId: sale._id,
                    saleItemId: item._id,
                    speciesName: item.speciesName,
                    weightKg: item.weightKg - (item.dispatchedQuantity || 0),
                    dispatchedWeightKg: 0,
                    status: 'PENDING'
                });
            });
        }

        const tripCode = await generateTripCode(exporterId);

        const dispatch = new Dispatch({
            tripCode,
            exporterId,
            idempotencyKey,
            vehicleNumber,
            vehicleType: vehicleType || 'OWN',
            driverName,
            driverPhone,
            sales: saleIds,
            items: dispatchItems,
            drops: drops || [],
            marketFreight: marketFreight || 0,
            totalBoxes: serverTotalBoxes,
            totalWeightKg: serverTotalTotalWeightKg || serverTotalWeightKg,
            status: 'IN_TRANSIT',
            departureTime: new Date()
        });

        await dispatch.save({ session });

        await session.commitTransaction();
        session.endSession();

        res.status(201).json({
            success: true,
            message: 'Dispatch trip created successfully',
            data: dispatch
        });
    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        next(error);
    }
};

// POST /api/dispatch/:id/deliver
exports.deliverDispatch = async (req, res, next) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const exporterId = req.user.exporterId;
        const dispatch = await Dispatch.findOne({ _id: req.params.id, exporterId }).session(session);

        if (!dispatch) {
            await session.abortTransaction();
            session.endSession();
            return res.status(404).json({ success: false, message: 'Dispatch trip not found' });
        }

        if (dispatch.status === 'DELIVERED' || dispatch.status === 'CLOSED') {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({ success: false, message: 'Dispatch trip is already delivered or closed' });
        }

        const { deliveredItems } = req.body; // array of { saleId, saleItemId, quantityKg }

        // Update sales per-item dispatched quantities
        for (const saleId of dispatch.sales) {
            const sale = await Sale.findOne({ _id: saleId, exporterId }).session(session);
            if (sale) {
                let allItemsFullyDispatched = true;
                let anyItemDispatched = false;

                sale.items.forEach(item => {
                    const deliveredMatch = Array.isArray(deliveredItems) ? deliveredItems.find(d => d.saleItemId && d.saleItemId.toString() === item._id.toString()) : null;
                    const addQty = deliveredMatch ? Number(deliveredMatch.quantityKg) : (item.weightKg - item.dispatchedQuantity);

                    item.dispatchedQuantity = Math.min(item.weightKg, (item.dispatchedQuantity || 0) + addQty);
                    if (item.dispatchedQuantity > 0) anyItemDispatched = true;
                    if (item.dispatchedQuantity < item.weightKg) allItemsFullyDispatched = false;
                });

                if (allItemsFullyDispatched) {
                    sale.dispatchStatus = 'COMPLETED';
                } else if (anyItemDispatched) {
                    sale.dispatchStatus = 'PARTIAL';
                }

                await sale.save({ session });
            }
        }

        dispatch.status = 'DELIVERED';
        (dispatch.drops || []).forEach(drop => { drop.status = 'DELIVERED'; });
        (dispatch.items || []).forEach(item => { item.status = 'DELIVERED'; });
        await dispatch.save({ session });

        await session.commitTransaction();
        session.endSession();

        res.json({ success: true, message: 'Dispatch trip marked as delivered', data: dispatch });
    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        next(error);
    }
};

// PATCH /api/dispatch/:id/status
exports.updateDispatchStatus = async (req, res, next) => {
    try {
        const { status } = req.body;
        const dispatch = await Dispatch.findOne({ _id: req.params.id, exporterId: req.user.exporterId });

        if (!dispatch) {
            return res.status(404).json({ success: false, message: 'Dispatch trip not found' });
        }

        dispatch.status = status;
        await dispatch.save();

        res.json({ success: true, message: 'Dispatch status updated', data: dispatch });
    } catch (error) {
        next(error);
    }
};
