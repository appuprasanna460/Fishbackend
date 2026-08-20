const ReturnEntry = require('../models/returnEntryModel');
const Voyage = require('../models/voyageModel');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

const getReturnEntry = async (req, res) => {
    try {
        const { voyageId } = req.params;
        const ownerId = req.user._id;

        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false }).lean();
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        const returnEntry = await ReturnEntry.findOne({ voyageId, ownerId }).populate('returningToHarbour', 'name').lean();
        successResponse(res, 200, 'Return entry retrieved successfully', returnEntry);
    } catch (error) {
        logger.error('Get return entry error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve return entry');
    }
};

const saveReturnEntry = async (req, res) => {
    try {
        const { voyageId } = req.params;
        const ownerId = req.user._id;
        const { boatId, returningToHarbour, returnDate, returnTime, seaCondition, distanceFromHarbour, fuelInTank, iceInStock, notes } = req.body;

        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false }).lean();
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        const returnEntry = await ReturnEntry.findOneAndUpdate(
            { voyageId, ownerId },
            {
                $set: {
                    boatId,
                    returningToHarbour,
                    returnDate,
                    returnTime,
                    seaCondition,
                    distanceFromHarbour: distanceFromHarbour || 0,
                    fuelInTank: fuelInTank || 0,
                    iceInStock: iceInStock || 0,
                    notes: notes || ''
                }
            },
            { upsert: true, new: true, runValidators: true }
        );

        successResponse(res, 200, 'Return entry saved successfully', returnEntry);
    } catch (error) {
        logger.error('Save return entry error:', error);
        errorResponse(res, 400, error.message || 'Failed to save return entry');
    }
};

module.exports = {
    getReturnEntry,
    saveReturnEntry
};
