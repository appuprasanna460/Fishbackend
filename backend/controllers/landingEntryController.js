const LandingEntry = require('../models/landingEntryModel');
const Voyage = require('../models/voyageModel');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

const getLandingEntry = async (req, res) => {
    try {
        const { voyageId } = req.params;
        const ownerId = req.user._id;

        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false }).lean();
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        const landingEntry = await LandingEntry.findOne({ voyageId, ownerId }).populate('landingHarbour', 'name').lean();
        successResponse(res, 200, 'Landing entry retrieved successfully', landingEntry);
    } catch (error) {
        logger.error('Get landing entry error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve landing entry');
    }
};

const saveLandingEntry = async (req, res) => {
    try {
        const { voyageId } = req.params;
        const ownerId = req.user._id;
        const { boatId, landingHarbour, landingDate, landingTime, totalCatch, catchBySpecies, notes } = req.body;

        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false }).lean();
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        const landingEntry = await LandingEntry.findOneAndUpdate(
            { voyageId, ownerId },
            {
                $set: {
                    boatId,
                    landingHarbour,
                    landingDate,
                    landingTime,
                    totalCatch: totalCatch || 0,
                    catchBySpecies: catchBySpecies || [],
                    notes: notes || ''
                }
            },
            { upsert: true, new: true, runValidators: true }
        );

        successResponse(res, 200, 'Landing entry saved successfully', landingEntry);
    } catch (error) {
        logger.error('Save landing entry error:', error);
        errorResponse(res, 400, error.message || 'Failed to save landing entry');
    }
};

module.exports = {
    getLandingEntry,
    saveLandingEntry
};
