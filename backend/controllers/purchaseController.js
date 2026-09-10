const mongoose = require('mongoose');
const Purchase = require('../models/purchaseModel');
const PurchaseLot = require('../models/purchaseLotModel');
const Payable = require('../models/payableModel');
const User = require('../models/usermodel');
const UnitMaster = require('../models/unitMasterModel');
const Harbour = require('../models/harbourmodel');

// Helper to generate auto-incrementing purchase number
const generatePurchaseNumber = async (exporterId) => {
    const todayStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const count = await Purchase.countDocuments({
        exporterId,
        createdAt: { $gte: new Date().setHours(0, 0, 0, 0) }
    });
    return `PUR-${todayStr}-${(count + 1).toString().padStart(4, '0')}`;
};

// Helper to generate auto-incrementing lot number
const generateLotNumber = async (exporterId) => {
    const monthStr = new Date().toISOString().slice(0, 7).replace(/-/g, '');
    const count = await PurchaseLot.countDocuments({ exporterId });
    return `LOT-${monthStr}-${(count + 1).toString().padStart(4, '0')}`;
};

// GET /api/purchases
exports.getPurchases = async (req, res, next) => {
    try {
        const { harbourId, status, startDate, endDate, sellerType } = req.query;
        let query = { exporterId: req.user.exporterId, isDeleted: false };

        if (harbourId) query.harbourId = harbourId;
        if (status) query.status = status;
        if (sellerType) query.sellerType = sellerType;

        if (req.user.role === 'PURCHASE_STAFF') {
            query.purchaseStaffId = req.user._id;
        }

        if (startDate || endDate) {
            query.purchaseDate = {};
            if (startDate) query.purchaseDate.$gte = new Date(startDate);
            if (endDate) query.purchaseDate.$lte = new Date(endDate);
        }

        const purchases = await Purchase.find(query)
            .sort({ createdAt: -1 })
            .populate('harbourId', 'name')
            .populate('purchaseStaffId', 'name email');

        res.json({ success: true, count: purchases.length, data: purchases });
    } catch (error) {
        next(error);
    }
};

// GET /api/purchases/:id
exports.getPurchaseById = async (req, res, next) => {
    try {
        const purchase = await Purchase.findOne({ _id: req.params.id, exporterId: req.user.exporterId })
            .populate('harbourId', 'name')
            .populate('purchaseStaffId', 'name email')
            .populate('sellerId', 'name phone');

        if (!purchase || purchase.isDeleted) {
            return res.status(404).json({ success: false, message: 'Purchase not found' });
        }

        res.json({ success: true, data: purchase });
    } catch (error) {
        next(error);
    }
};

// Validate Harbour and Units helper
const validatePurchasePayload = async (exporterId, harbourId, items) => {
    if (!mongoose.Types.ObjectId.isValid(harbourId)) {
        throw new Error('Invalid harbour ID. Harbour must be a valid ObjectId.');
    }
    const harbour = await Harbour.findById(harbourId);
    if (!harbour) {
        throw new Error('Harbour not found');
    }

    const availableUnits = await UnitMaster.find({ exporterId, isActive: true }).select('name').lean();
    const validUnitNames = new Set(availableUnits.map(u => u.name.toUpperCase()));

    for (const item of items) {
        if (item.unit) {
            const unitNameUpper = item.unit.toUpperCase();
            if (validUnitNames.size > 0 && !validUnitNames.has(unitNameUpper)) {
                throw new Error(`Unit '${item.unit}' is not a valid UnitMaster for this exporter.`);
            }
        }
    }
    return harbour;
};

// POST /api/purchases/draft
exports.saveDraft = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const {
            harbourId,
            purchaseStaffName,
            sellerType,
            sellerId,
            sellerName,
            sellerPhone,
            boatId,
            boatName,
            boatNumber,
            paymentMethod,
            items,
            notes,
            photos
        } = req.body;

        if (!harbourId || !sellerType || !sellerName || !items || !Array.isArray(items)) {
            return res.status(400).json({ success: false, message: 'Harbour, seller details, and items array are required' });
        }

        const harbour = await validatePurchasePayload(exporterId, harbourId, items);

        let totalAmount = 0;
        const processedItems = items.map(item => {
            const amount = (item.quantity || 0) * (item.ratePerUnit || 0);
            totalAmount += amount;
            return {
                speciesId: item.speciesId || null,
                speciesName: item.speciesName || 'Unknown',
                unit: item.unit || 'KG',
                quantity: item.quantity || 0,
                ratePerUnit: item.ratePerUnit || 0,
                amount,
                grade: item.grade || 'STANDARD',
                size: item.size || 'STANDARD',
                knownWeightKg: item.knownWeightKg || null
            };
        });

        const purchaseNumber = await generatePurchaseNumber(exporterId);

        const purchase = new Purchase({
            exporterId,
            harbourId,
            purchaseStaffId: req.user._id,
            purchaseStaffName: purchaseStaffName || req.user.name,
            purchaseNumber,
            sellerType,
            sellerId: sellerId || null,
            sellerName,
            sellerPhone: sellerPhone || '',
            boatId: boatId || null,
            boatName: boatName || 'Nil',
            boatNumber: boatNumber || '',
            paymentMethod: paymentMethod || 'CASH',
            items: processedItems,
            totalAmount,
            notes: notes || '',
            photos: photos || [],
            status: 'DRAFT',
            isImmutable: false,
            createdBy: req.user._id
        });

        await purchase.save();

        res.status(201).json({ success: true, message: 'Draft purchase saved successfully', data: purchase });
    } catch (error) {
        next(error);
    }
};

// POST /api/purchases
exports.createPurchase = async (req, res, next) => {
    try {
        return exports.saveDraft(req, res, next);
    } catch (error) {
        next(error);
    }
};

// POST /api/purchases/:id/confirm
exports.confirmPurchase = async (req, res, next) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const exporterId = req.user.exporterId;
        const { idempotencyKey } = req.body;

        if (idempotencyKey) {
            const existingConfirmed = await Purchase.findOne({ idempotencyKey, exporterId }).session(session);
            if (existingConfirmed) {
                await session.commitTransaction();
                session.endSession();
                return res.json({ success: true, message: 'Purchase already confirmed', data: existingConfirmed });
            }
        }

        let purchase = await Purchase.findOne({ _id: req.params.id, exporterId }).session(session);
        if (!purchase || purchase.isDeleted) {
            await session.abortTransaction();
            session.endSession();
            return res.status(404).json({ success: false, message: 'Purchase not found' });
        }

        if (purchase.status === 'CONFIRMED' || purchase.isImmutable) {
            await session.commitTransaction();
            session.endSession();
            return res.json({ success: true, message: 'Purchase already confirmed', data: purchase });
        }

        // Lock immutable fields
        purchase.status = 'CONFIRMED';
        purchase.isImmutable = true;
        if (idempotencyKey) purchase.idempotencyKey = idempotencyKey;
        await purchase.save({ session });

        // Create PurchaseLot entries for each item
        const harbour = await Harbour.findById(purchase.harbourId).session(session);
        const harbourName = harbour ? harbour.name : 'Harbour';

        for (const item of purchase.items) {
            const lotNumber = await generateLotNumber(exporterId);
            const lot = new PurchaseLot({
                purchaseId: purchase._id,
                lotNumber,
                exporterId,
                harbourId: purchase.harbourId.toString(),
                harbourName,
                sellerName: purchase.sellerName,
                species: item.speciesName,
                purchaseUnit: item.unit,
                purchaseQty: item.quantity,
                purchaseAmount: item.amount,
                status: 'PENDING'
            });
            await lot.save({ session });
        }

        // Create Payable entry for seller
        const existingPayable = await Payable.findOne({ purchaseId: purchase._id, exporterId }).session(session);
        if (!existingPayable) {
            const payable = new Payable({
                exporterId,
                sellerId: purchase.sellerId,
                sellerName: purchase.sellerName,
                purchaseId: purchase._id,
                purchaseNumber: purchase.purchaseNumber,
                totalAmount: purchase.totalAmount,
                paidAmount: 0,
                balanceAmount: purchase.totalAmount,
                status: 'PENDING'
            });
            await payable.save({ session });
        }

        await session.commitTransaction();
        session.endSession();

        res.json({ success: true, message: 'Purchase confirmed, lots and payables generated', data: purchase });
    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        next(error);
    }
};

// POST /api/purchases/:id/reverse
exports.reversePurchase = async (req, res, next) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const exporterId = req.user.exporterId;
        const purchase = await Purchase.findOne({ _id: req.params.id, exporterId }).session(session);

        if (!purchase || purchase.isDeleted) {
            await session.abortTransaction();
            session.endSession();
            return res.status(404).json({ success: false, message: 'Purchase not found' });
        }

        if (purchase.status === 'REVERSED') {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({ success: false, message: 'Purchase is already reversed' });
        }

        purchase.status = 'REVERSED';
        await purchase.save({ session });

        // Create a REVERSED copy
        const purchaseNumber = await generatePurchaseNumber(exporterId);
        const reversedItems = purchase.items.map(item => ({
            speciesId: item.speciesId,
            speciesName: item.speciesName,
            unit: item.unit,
            quantity: -item.quantity,
            ratePerUnit: item.ratePerUnit,
            amount: -item.amount,
            grade: item.grade,
            size: item.size
        }));

        const reversedPurchase = new Purchase({
            exporterId,
            parentPurchaseId: purchase._id,
            harbourId: purchase.harbourId,
            purchaseStaffId: req.user._id,
            purchaseStaffName: req.user.name,
            purchaseNumber: `${purchaseNumber}-REV`,
            sellerType: purchase.sellerType,
            sellerId: purchase.sellerId,
            sellerName: purchase.sellerName,
            sellerPhone: purchase.sellerPhone,
            boatId: purchase.boatId,
            boatName: purchase.boatName,
            paymentMethod: purchase.paymentMethod,
            items: reversedItems,
            totalAmount: -purchase.totalAmount,
            notes: `Reversal of Purchase #${purchase.purchaseNumber}`,
            status: 'REVERSED',
            isImmutable: true,
            createdBy: req.user._id
        });

        await reversedPurchase.save({ session });

        // Update payable status to CANCELLED/PAID
        await Payable.updateOne(
            { purchaseId: purchase._id, exporterId },
            { status: 'PAID', balanceAmount: 0 }
        ).session(session);

        await session.commitTransaction();
        session.endSession();

        res.json({ success: true, message: 'Purchase reversed successfully', data: reversedPurchase });
    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        next(error);
    }
};

// PATCH /api/purchases/:id/status
exports.updatePurchaseStatus = async (req, res, next) => {
    try {
        const { status } = req.body;
        const purchase = await Purchase.findOne({ _id: req.params.id, exporterId: req.user.exporterId });

        if (!purchase) {
            return res.status(404).json({ success: false, message: 'Purchase not found' });
        }

        purchase.status = status;
        await purchase.save();

        res.json({ success: true, message: 'Purchase status updated', data: purchase });
    } catch (error) {
        next(error);
    }
};

// GET /api/purchases/summary
exports.getPurchaseSummary = async (req, res, next) => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const purchasesToday = await Purchase.find({
            exporterId: req.user.exporterId,
            createdAt: { $gte: today },
            isDeleted: false,
            status: { $ne: 'CANCELLED' }
        });

        let totalValue = 0;
        purchasesToday.forEach(p => totalValue += p.totalAmount);

        res.json({
            success: true,
            data: {
                totalValue,
                totalCount: purchasesToday.length,
                todayPurchases: purchasesToday
            }
        });
    } catch (error) {
        next(error);
    }
};

// GET /api/purchases/sellers
exports.getSellersByHarbour = async (req, res, next) => {
    try {
        const { harbourId } = req.query;
        
        let query = {
            isDeleted: { $ne: true }
        };

        if (req.user && req.user.exporterId) {
            query.$or = [
                { exporterId: req.user.exporterId },
                { role: { $in: ['BOAT_OWNER', 'COMMISSION_AGENT', 'FISH_BUYER', 'STAFF', 'DOMESTIC_EXPORTER', 'SUPPLIER', 'TRADER'] } },
                { sellerType: { $in: ['BOAT_OWNER', 'COMMISSION_AGENT', 'SUPPLIER'] } }
            ];
        }

        const sellers = await User.find(query)
            .select('_id name phone role sellerType businessName assignedHarbourId harbourId')
            .lean();

        let allBoats = [];
        try {
            const Boat = require('../models/boatmodel');
            allBoats = await Boat.find({ isDeleted: { $ne: true } })
                .select('_id boatName boatNumber ownerId agentId locationId')
                .lean();
        } catch (boatErr) {
            console.error('Error querying Boat model:', boatErr.message);
        }

        // Attach associated boats to each seller
        const enrichedSellers = sellers.map(seller => {
            const sellerIdStr = seller._id ? seller._id.toString() : '';
            const sellerBoats = allBoats.filter(b => 
                (b.ownerId && b.ownerId.toString() === sellerIdStr) || 
                (b.agentId && b.agentId.toString() === sellerIdStr)
            );
            return {
                ...seller,
                boats: sellerBoats
            };
        });

        return res.json({ success: true, data: enrichedSellers, allBoats });
    } catch (error) {
        console.error('Error in getSellersByHarbour:', error);
        return res.status(500).json({ success: false, message: error.message, data: [] });
    }
};

// GET /api/purchases/harbour/:id/staff
exports.getHarbourStaff = async (req, res, next) => {
    try {
        const staff = await User.find({
            exporterId: req.user.exporterId,
            isActive: true
        }).select('_id name email role phone');

        res.json({ success: true, data: staff });
    } catch (error) {
        next(error);
    }
};
