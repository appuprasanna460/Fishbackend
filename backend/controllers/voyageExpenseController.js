const VoyageExpense = require('../models/voyageExpenseModel');
const Voyage = require('../models/voyageModel');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

// Get all expense records for a voyage (by date, ascending)
const getVoyageExpenses = async (req, res) => {
    try {
        const { voyageId } = req.params;
        const ownerId = req.user._id;

        // Ownership check
        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false }).lean();
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        const expenses = await VoyageExpense.find({ voyageId, ownerId })
            .sort({ date: 1 })
            .lean();

        // Compute totals
        const totals = expenses.reduce(
            (acc, e) => ({
                totalFuel: acc.totalFuel + (e.fuelUsed || 0),
                totalIce: acc.totalIce + (e.iceUsed || 0),
                totalWater: acc.totalWater + (e.waterUsed || 0),
            }),
            { totalFuel: 0, totalIce: 0, totalWater: 0 }
        );

        successResponse(res, 200, 'Voyage expenses retrieved successfully', { expenses, totals });
    } catch (error) {
        logger.error('Get voyage expenses error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve voyage expenses');
    }
};

// Create or update the expense record for a specific voyage date (upsert)
const saveVoyageExpenses = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const { voyageId, boatId, date, fuelUsed, iceUsed, waterUsed, notes } = req.body;

        if (!voyageId || !boatId || !date) {
            return errorResponse(res, 400, 'voyageId, boatId and date are required');
        }

        // Ownership check
        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false }).lean();
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        // Normalise date to midnight UTC so the unique index works correctly
        const normalised = new Date(date);
        normalised.setUTCHours(0, 0, 0, 0);

        const expense = await VoyageExpense.findOneAndUpdate(
            { voyageId, ownerId, date: normalised },
            {
                $set: {
                    boatId,
                    fuelUsed: fuelUsed || 0,
                    iceUsed: iceUsed || 0,
                    waterUsed: waterUsed || 0,
                    notes: notes || '',
                },
            },
            { upsert: true, new: true, runValidators: true }
        );

        successResponse(res, 200, 'Voyage expenses saved successfully', expense);
    } catch (error) {
        logger.error('Save voyage expenses error:', error);
        errorResponse(res, 400, error.message || 'Failed to save voyage expenses');
    }
};

module.exports = {
    getVoyageExpenses,
    saveVoyageExpenses,
};
