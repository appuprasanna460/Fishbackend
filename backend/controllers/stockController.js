const Stock = require('../models/stockModel');
const PurchaseLot = require('../models/purchaseLotModel');
const Location = require('../models/locationmodel');

// GET /api/stock
exports.getStock = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const { speciesName, grade, status, locationId } = req.query;
        let query = { exporterId };

        if (speciesName) query.speciesName = { $regex: speciesName, $options: 'i' };
        if (grade) query.grade = grade;
        if (locationId) query.locationId = locationId;
        if (status) query.status = status;
        else query.status = { $ne: 'CLOSED' };

        const stockItems = await Stock.find(query)
            .populate('locationId', 'name')
            .populate('subLocationId', 'name')
            .sort({ speciesName: 1, grade: 1 });

        res.json({ success: true, count: stockItems.length, data: stockItems });
    } catch (error) {
        next(error);
    }
};

// GET /api/stock/locations - stock grouped by location
exports.getStockByLocation = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const stockByLocation = await Stock.aggregate([
            { $match: { exporterId, status: 'READY' } },
            {
                $group: {
                    _id: '$locationId',
                    totalWeightKg: { $sum: '$availableWeightKg' },
                    totalBoxes: { $sum: '$totalBoxes' },
                    totalValuation: { $sum: { $multiply: ['$availableWeightKg', '$avgCostPerKg'] } },
                    itemsCount: { $sum: 1 }
                }
            }
        ]);

        const populatedLocations = await Promise.all(
            stockByLocation.map(async loc => {
                const locDoc = loc._id ? await Location.findById(loc._id).select('name').lean() : null;
                return {
                    locationId: loc._id,
                    locationName: locDoc ? locDoc.name : 'Unassigned Location',
                    totalWeightKg: loc.totalWeightKg,
                    totalBoxes: loc.totalBoxes,
                    totalValuation: loc.totalValuation,
                    itemsCount: loc.itemsCount
                };
            })
        );

        res.json({ success: true, data: populatedLocations });
    } catch (error) {
        next(error);
    }
};

// GET /api/stock/summary
exports.getStockSummary = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const activeStock = await Stock.find({ exporterId, status: { $ne: 'CLOSED' } });

        let totalWeightKg = 0;
        let totalBoxes = 0;
        let totalValuation = 0;

        activeStock.forEach(item => {
            totalWeightKg += item.availableWeightKg;
            totalBoxes += item.totalBoxes;
            totalValuation += (item.availableWeightKg * item.avgCostPerKg);
        });

        res.json({
            success: true,
            data: {
                totalWeightKg,
                totalBoxes,
                totalValuation,
                activeLotsCount: activeStock.length
            }
        });
    } catch (error) {
        next(error);
    }
};

// GET /api/stock/lots
exports.getPurchaseLots = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const { status } = req.query;
        let query = { exporterId };
        if (status && status !== 'ALL') query.status = status;

        const lots = await PurchaseLot.find(query).sort({ createdAt: -1 });
        res.json({ success: true, count: lots.length, data: lots });
    } catch (error) {
        next(error);
    }
};

// POST /api/stock/lots/:id/report-issue
exports.reportLotIssue = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const { reason, quantityKg, notes } = req.body;

        if (!reason || !quantityKg || quantityKg <= 0) {
            return res.status(400).json({ success: false, message: 'Valid reason and quantity (KG) are required' });
        }

        const lot = await PurchaseLot.findOne({ _id: req.params.id, exporterId });
        if (!lot) {
            return res.status(404).json({ success: false, message: 'Purchase lot not found' });
        }

        lot.issueReports = lot.issueReports || [];
        lot.issueReports.push({
            reason,
            quantityKg,
            notes: notes || '',
            reportedAt: new Date(),
            reportedBy: req.user._id
        });

        await lot.save();

        res.json({ success: true, message: 'Issue report logged successfully', data: lot });
    } catch (error) {
        next(error);
    }
};

// PATCH /api/stock/lots/:id/weigh
exports.weighAndGradeLot = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const { weighedWeightKg, gradeSplits, rejectedWeightKg, qualityNotes, locationId, subLocationId } = req.body;
        const lot = await PurchaseLot.findOne({ _id: req.params.id, exporterId });

        if (!lot) {
            return res.status(404).json({ success: false, message: 'Purchase lot not found' });
        }

        if (!weighedWeightKg || weighedWeightKg <= 0) {
            return res.status(400).json({ success: false, message: 'Valid weighed weight (KG) is required' });
        }

        const splits = gradeSplits && gradeSplits.length > 0 ? gradeSplits : [
            { grade: 'A Grade', weight: weighedWeightKg, splitPercentage: 100 }
        ];

        // Validate grade splits sum <= weighedWeightKg
        const totalSplitWeight = splits.reduce((sum, s) => sum + (Number(s.weight) || 0), 0);
        if (totalSplitWeight > weighedWeightKg) {
            return res.status(400).json({
                success: false,
                message: `Sum of grade splits (${totalSplitWeight} KG) cannot exceed weighed weight (${weighedWeightKg} KG)`
            });
        }

        const costPerKg = lot.purchaseAmount / weighedWeightKg;

        lot.weighedWeightKg = weighedWeightKg;
        lot.costPerKg = costPerKg;
        lot.rejectedWeightKg = rejectedWeightKg || 0;
        lot.qualityNotes = qualityNotes || '';
        lot.status = 'WEIGHED';
        lot.receivedAt = new Date();
        lot.gradeSplits = splits;

        await lot.save();

        // Update or create Stock entries for each grade split with parentLotId
        for (const split of splits) {
            let stock = await Stock.findOne({
                exporterId,
                speciesName: lot.species,
                grade: split.grade,
                status: 'READY'
            });

            if (stock) {
                const existingWeight = stock.availableWeightKg;
                const existingTotalCost = existingWeight * stock.avgCostPerKg;
                const newAddedCost = split.weight * costPerKg;
                const combinedWeight = existingWeight + split.weight;
                const combinedAvgCost = combinedWeight > 0 ? (existingTotalCost + newAddedCost) / combinedWeight : costPerKg;

                stock.availableWeightKg = combinedWeight;
                stock.avgCostPerKg = combinedAvgCost;
                stock.totalPurchaseCost += newAddedCost;
                if (locationId) stock.locationId = locationId;
                if (subLocationId) stock.subLocationId = subLocationId;
                if (!stock.lotIds.includes(lot._id)) {
                    stock.lotIds.push(lot._id);
                }
                await stock.save();
            } else {
                stock = new Stock({
                    exporterId,
                    ownerId: req.user._id,
                    speciesName: lot.species,
                    grade: split.grade,
                    size: 'STANDARD',
                    locationId: locationId || null,
                    subLocationId: subLocationId || null,
                    availableWeightKg: split.weight,
                    reservedWeightKg: 0,
                    dispatchedWeightKg: 0,
                    totalBoxes: Math.ceil(split.weight / 25),
                    avgCostPerKg: costPerKg,
                    totalPurchaseCost: split.weight * costPerKg,
                    lotIds: [lot._id],
                    status: 'READY'
                });
                await stock.save();
            }
        }

        lot.status = 'DONE';
        lot.isImmutable = true;
        await lot.save();

        res.json({
            success: true,
            message: 'Lot weighed and inventory stock updated successfully',
            data: lot
        });
    } catch (error) {
        next(error);
    }
};

// POST /api/stock/allocate
exports.allocateStock = async (req, res, next) => {
    try {
        const exporterId = req.user.exporterId;
        const { items } = req.body; // [{ stockId, weightKg }]
        if (!items || items.length === 0) {
            return res.status(400).json({ success: false, message: 'Items to allocate are required' });
        }

        for (const item of items) {
            const stock = await Stock.findOne({ _id: item.stockId, exporterId });
            if (!stock || stock.availableWeightKg < item.weightKg) {
                return res.status(400).json({
                    success: false,
                    message: `Insufficient stock for ${stock ? stock.speciesName : 'item'}. Available: ${stock ? stock.availableWeightKg : 0} KG`
                });
            }
            stock.availableWeightKg -= item.weightKg;
            stock.reservedWeightKg += item.weightKg;
            if (stock.availableWeightKg === 0) {
                stock.status = 'RESERVED';
            }
            await stock.save();
        }

        res.json({ success: true, message: 'Stock allocated successfully' });
    } catch (error) {
        next(error);
    }
};
